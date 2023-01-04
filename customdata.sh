#! /bin/bash
sudo sed -i '/^'"#ClientAliveCountMax"'/d' /etc/ssh/sshd_config
sudo sh -c "echo 'ClientAliveCountMax 170' >> /etc/ssh/sshd_config"
sudo systemctl restart sshd
sudo yum install -y yum-utils git
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo usermod -aG docker kafkaadmin
newgrp docker
sudo systemctl start docker
sudo systemctl enable docker
docker run hello-world
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
git clone https://github.com/confluentinc/training-administration-src.git confluent-admin
cd confluent-admin/
docker-compose up -d
