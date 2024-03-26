#!/usr/bin/env bash
# Default
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl ansible awscli git s3fs jq
sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service && sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
DEBIAN_FRONTEND="noninteractive" sudo apt-get install -y --no-install-recommends tzdata && sudo timedatectl set–timezone Europe/Belgrade
export AWS_REGION=eu-central-1

sudo tee /home/ubuntu/install_nginx.yaml <<EOF >/dev/null
---
- name: Install Nginx on Ubuntu 22
  hosts: localhost
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Ensure Nginx is running and enabled
      systemd:
        name: nginx
        state: started
        enabled: yes
    - name: Configure Nginx to listen on port 80
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/sites-available/default
      notify:
        - restart nginx
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
EOF

sudo tee /home/ubuntu/nginx.conf.j2 <<EON >/dev/null
server {
    listen 80 default_server;
    keepalive_timeout 75s;

    root /var/www/html;
    index index.html index.htm;

    location / {
        index index.html index.htm;
    }
}
EON

sudo ansible-playbook /home/ubuntu/install_nginx.yaml
mv /var/www/html/index.nginx-debian.html /var/www/html/index.html
sudo systemctl restart nginx

aws secretsmanager get-secret-value --secret-id aws_s3_key_dev --region eu-central-1 | jq -r .SecretString > /root/.passwd-s3fs
chmod 600 /root/.passwd-s3fs

sudo mkdir /mnt/s3-bucket
echo "*/5 * * * * sudo s3fs nolyporp-dev-fe /mnt/s3-bucket -o passwd_file=/root/.passwd-s3fs -o url=https://s3.amazonaws.com" > crontab.txt
crontab crontab.txt
