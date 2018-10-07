#!/bin/bash
#
#This script is executed on the EC2 instance effectively turning it into a Cowrie honeypot
# System SSH daemon moves to port 5522
# Cowrie listens on port 22 and 23
set -eux

function cleanup(){
  sudo userdel cowrie || true
  sudo rm -rf /home/cowrie/* || true
}

function configure_system(){
  sudo sed -i'' 's/^#Port 22$/Port 5522/g' /etc/ssh/sshd_config
  sudo service sshd restart
  sudo useradd cowrie -m
  sudo apt-get update
}

function install_cowrie(){
  sudo apt-get install -y python python-dev python-setuptools gcc authbind
  sudo easy_install pip
  sudo pip install --upgrade pip
  sudo pip install virtualenv awscli
  sudo su -c 'cd ~ && git clone https://github.com/tgenov/cowrie.git' cowrie
  sudo su -c 'cd ~cowrie/cowrie && git checkout openwrt' cowrie
  sudo su -c 'cd ~cowrie/cowrie && virtualenv cowrie-env' cowrie
  sudo su -c 'cd ~cowrie/cowrie && source cowrie-env/bin/activate && cd ~cowrie/cowrie && pip install --upgrade -r requirements.txt' cowrie
  sudo su -c 'cd ~cowrie/cowrie && source cowrie-env/bin/activate && cd ~cowrie/cowrie && pip install boto3 ec2-metadata' cowrie
  sudo touch /etc/authbind/byport/22
  sudo chown cowrie:cowrie /etc/authbind/byport/22
  sudo chmod 770 /etc/authbind/byport/22
  sudo touch /etc/authbind/byport/23
  sudo chown cowrie:cowrie /etc/authbind/byport/23
  sudo chmod 770 /etc/authbind/byport/23
}

function configure_cowrie(){
  sudo su -c 'sed -i"" "s/^AUTHBIND_ENABLED=no$/AUTHBIND_ENABLED=yes/g" ~cowrie/cowrie/bin/cowrie' cowrie
  sudo su -c 'cp ~ubuntu/scripts/config-files/cowrie.cfg ~cowrie/cowrie' cowrie
  sudo su -c 'cp ~ubuntu/scripts/config-files/responder.json ~cowrie/cowrie' cowrie
  sudo su -c 'cp ~ubuntu/scripts/config-files/mounts ~cowrie/cowrie/honeyfs/proc' cowrie
  sudo su -c 'cp ~ubuntu/scripts/config-files/cpuinfo ~cowrie/cowrie/honeyfs/proc' cowrie
  sudo cp ~ubuntu/scripts/config-files/rc.local /etc/
  sudo cp ~ubuntu/scripts/config-files/rc.local.service /etc/systemd/system/
  sudo chmod +x /etc/rc.local

}

function start_cowrie(){
  sudo systemctl enable rc.local.service
  sudo systemctl start rc.local.service
}

function install_logstash(){
  sudo mkdir -p /etc/logstash
  # The devault JVM requires 1G of RAM. Our config limits this to 64M
  sudo cp ~ubuntu/scripts/config-files/jvm.options /etc/logstash
  sudo cp ~ubuntu/scripts/config-files/logstash.yml /etc/logstash
  echo "### INSTALL LOGSTASH"
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y apt-transport-https default-jre
  echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
  sudo apt-get update && sudo apt-get -o Dpkg::Options::=--force-confold install logstash
}

function install_logstash_config()
{
   METADATA="http://169.254.169.254/latest/meta-data/"
   AWS_ZONE="$(curl -s $METADATA/placement/availability-zone)"
   PUBLIC_IP="$(curl -s $METADATA/public-ipv4)"
   INSTANCE_ID="$(curl -s $METADATA/instance-id)"
   KERNEL_VERSION=$(egrep -o "^kernel_version = .*$" ~ubuntu/scripts/config-files/cowrie.cfg | cut -d= -f2 |tr -d "^ ")
   KERNEL_BUILD=$(egrep -o "^kernel_build_string = .*$" ~ubuntu/scripts/config-files/cowrie.cfg | cut -d= -f2 |tr -d "^ ")
   HARDWARE_PLATFORM=$(egrep -o "^hardware_platform = .*$" ~ubuntu/scripts/config-files/cowrie.cfg | cut -d= -f2 |tr -d "^ ")
   ELF_ARCH=$(egrep -o "^arch = .*$" ~ubuntu/scripts/config-files/cowrie.cfg | cut -d= -f2 |tr -d "^ ")
   sed -i'' "s/__AWS_REGION__/$AWS_ZONE/" ~ubuntu/scripts/config-files/logstash-cowrie.conf
   sed -i'' "s/__AWS_PUBLIC_IP__/$PUBLIC_IP/" ~ubuntu/scripts/config-files/logstash-cowrie.conf
   sed -i'' "s/__AWS_INSTANCE_ID__/$INSTANCE_ID/" ~ubuntu/scripts/config-files/logstash-cowrie.conf
   sed -i'' "s/__COWRIE_KERNEL_VERSION__/$KERNEL_VERSION/" ~ubuntu/scripts/config-files/logstash-cowrie.conf
   sed -i'' "s/__COWRIE_KERNEL_BUILD__/$KERNEL_BUILD/" ~ubuntu/scripts/config-files/logstash-cowrie.conf
   sed -i'' "s/__COWRIE_HARDWARE_PLATFORM__/$HARDWARE_PLATFORM/" ~ubuntu/scripts/config-files/logstash-cowrie.conf
   sed -i'' "s/__COWRIE_ELF_ARCH__/$ELF_ARCH/" ~ubuntu/scripts/config-files/logstash-cowrie.conf
   sudo cp ~ubuntu/scripts/config-files/logstash-cowrie.conf /etc/logstash/conf.d/
   sudo systemctl restart logstash
   sudo systemctl enable logstash
}

cleanup
configure_system
install_cowrie
install_logstash
install_logstash_config
configure_cowrie
start_cowrie
