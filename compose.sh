#! /bin/bash

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