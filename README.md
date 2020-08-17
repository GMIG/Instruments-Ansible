- Устанавливаем на Raspbrry PI Инструменты
Чтобы иметь возможность делать все что мы хотим, нам надо подготовить наш новый компьютер. Для этого Raspberry должен быть подключен к интернету (позже появиться вариант автономной установки)

Настройки можно сделать вручную по инструкции или воспользоваться Ansible скриптом для автоматической настройки.

-- Автоматическая настройка
Для автоматической настройки мы используем Ansible, кстати, эта программа подволяет настроить сразу несколько устройств одновременно, если есть такая необходимость.

Если настроить необходимо только один миниПК, то скрипт можно запустить на нём же.
Если настроить необходимо несколько миниПК, то необходимо включить на них SSH, а скрипт запустить на одной из Raspberry или на отдельном ПК

--- Настройка локального компьютера

# Открываем терминал - Ctrl+Alt+T

# Запускаем скрипт, который скачает всё необходимое для установки и запустит установку
# curl -sSL https://raw.githubusercontent.com/GMIG/Instruments-Ansible/master/install-instruments-local.sh | bash


-- Настройка удаленных компьютеров
Устанавливаем ansible на одной из расбери или на отдельном ПК
# для Raspberry команда ниже, для других ОС можно посмотреть как устанавливать тут: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
# sshpass нужен для первоначальной авторизации по паролю

# Запускаем скрипт, который скачает всё необходимое для установки
# curl -sSL https://raw.githubusercontent.com/GMIG/Instruments-Ansible/master/install-instruments-network.sh | bash

# необходмо открыть файл hosts и вписать туда имена и ip адреса всех настраиваемых Raspberry
# также если вы меняли стандартные имя пользователя или пароль, необходимо их указать.
# Можно настроить несколько групп устройств, для последующего раздельного управления, тогда их необходимо записать в объединяющую группу [raspberry-all:children] чтобы скрипт первоначальной установки сработал на всех миниПК

nano hosts

# После этого запускаем скрипт
ansible-playbook base-init.yaml


####

В результате работы скрипта, на Raspberry будут произведены необходимые настройки, установлены необходимые пакеты и добавлен в автозагрузку демон управления Инструментами. 
Можно проверить что все работает выполнив команды

cd /home/pi/Instruments/main/
/home/pi/.local/bin/pipenv run python /home/pi/Instruments/main/Main.py cl

Далее в зависимости от сценария настраивается программа и если необходимо управление - демон






-- Ручная настройка

# Открываем терминал - Ctrl+Alt+T

# Устанавливаем необходимые зависимости 
sudo apt-get install mpv libmpv1 unclutter exfat-fuse exfat-utils watchdog -y

#настраиваем watchdog
#Для того, чтобы watchdog срабатывал и в тех случаях, когда список ожидающих выполнения процессов зашкаливает (говорит нам о том, что идет сильно не так), раскомментируем строчку max-load-1 = 24. тем самым мы говорим таймеру, что «если load average за минуту превысит 24, то watchdog должен перезагрузить операционку». min-memory = 5 - если осталось меньше 5 страниц виртуальной памяти - перезагружаем

ln /lib/systemd/system/watchdog.service /etc/systemd/system/multi-user.target.wants/watchdog.service
sudo nano /etc/watchdog.conf
	watchdog-device = /dev/watchdog
	watchdog-timeout = 10
	interval = 2
	max-load-1 = 24
	min-memory = 5


#Отключение Screensaver
sudo nano /etc/lightdm/lightdm.conf
# Add the following lines to the [SeatDefaults] section:
# don't sleep the screen
xserver-command=X -s 0 dpms


Для того чтобы рабочий стол загружался без подключенного монитора (могут быть проблемы в случае смены монитора):

sudo nano /boot/config.txt
# Раскомментируем строку
hdmi_force_hotplug=1


# Переходим в домашнюю директорию
cd ~/

# Скачиваем инструментарий и переходим в папку с ним
git clone https://github.com/GMIG/Instruments.git 
cd Instruments/daemon

# Для удобства настраиваем окружение на работу с 3-й версией питона
alias pip=pip3
alias python=python3

#и добавляем их в переменную bash чтобы работало и после перезагрузки

nano /home/pi/.bashrc
	alias python=python3  
	alias pip=pip3
	export PATH=$PATH:/home/pi/.local/bin
            
# Обновлеям bash 			
. ~/.bashrc

# Устанавливаем виртуальное окружение pipenv
pip install --user pipenv
pip install -U platformio
PATH=$PATH:~/.local/bin

# Устанавлиаем необходимые зависимости
pipenv update

# Возвращаемся в домашнюю папку и создаем скрипт автозапуска демона управления
cd ~/
{
  echo '#!/bin/bash'
  echo ' '
  echo '# Hide the mouse from the display'
  echo 'unclutter &'
  echo ' '
  echo 'cd ~/Instruments/daemon'
  echo '~/.local/bin/pipenv run python ~/Instruments/daemon/daemonMain.py'
} > autorun-daemon.sh

# Даем права на выполнение
chmod +x autorun-daemon.sh
 
# Добавляем созданный скрипт в автозагрузку 
# работает для raspbery pi с установленной RasbianOS с окружением рабочего стола\
# если у вас другая ОС, то файл автостарта может быть расположен в другом месте
sudo sh -c "echo '@~/autorun-daemon.sh' >> /etc/xdg/lxsession/LXDE-pi/autostart"