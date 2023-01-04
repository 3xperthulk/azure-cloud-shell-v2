#! /bin/bash
sudo sed -i '/^'"#ClientAliveCountMax"'/d' /etc/ssh/sshd_config
sudo sh -c "echo 'ClientAliveCountMax 170' >> /etc/ssh/sshd_config"
sudo systemctl restart sshd
sudo yum install -y yum-utils git
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
