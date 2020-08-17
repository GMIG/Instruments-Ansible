#!/bin/bash

cd ~/
git clone https://github.com/GMIG/Instruments-Ansible.git
cd Instruments-Ansible
sudo apt install ansible -y
ansible-playbook base-init-local.yaml
