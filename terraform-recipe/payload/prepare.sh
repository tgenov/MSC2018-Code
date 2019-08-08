#!/bin/bash
#
# This script is executed on the EC2 instance effectively turning it into a Cowrie honeypot
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
  sudo useradd cowrie -m -s /bin/bash || true
  sudo apt-get update
}

function install_dependencies(){
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python python-dev python-setuptools gcc authbind python-pip jq
  sudo pip install --upgrade pip
  sudo pip install virtualenv awscli
}

function install_cowrie(){
  sudo su -c 'cd ~ && git clone https://github.com/tgenov/cowrie.git' cowrie
  sudo su -c 'cd ~cowrie/cowrie && git checkout openwrt' cowrie
  sudo su -c 'cd ~cowrie/cowrie && virtualenv cowrie-env' cowrie
  sudo su -c 'cd ~cowrie/cowrie && source cowrie-env/bin/activate && cd ~cowrie/cowrie && pip install --upgrade -r requirements.txt' cowrie
  sudo su -c 'cd ~cowrie/cowrie && source cowrie-env/bin/activate && cd ~cowrie/cowrie && pip install boto3 ec2-metadata bcrypt' cowrie
  sudo touch /etc/authbind/byport/22
  sudo chown cowrie:cowrie /etc/authbind/byport/22
  sudo chmod 770 /etc/authbind/byport/22
  sudo touch /etc/authbind/byport/23
  sudo chown cowrie:cowrie /etc/authbind/byport/23
  sudo chmod 770 /etc/authbind/byport/23
}

function configure_cowrie(){
  COWRIE_CONFIG="$(curl -s http://169.254.169.254/latest/user-data/)"
  sudo su -c 'sed -i"" "s/^AUTHBIND_ENABLED=no$/AUTHBIND_ENABLED=yes/g" ~cowrie/cowrie/bin/cowrie' cowrie
  sudo su -c "cp -fr $CONFIG_DIRECTORY/cowrie/* /home/cowrie/cowrie/" cowrie
  sudo su -c "cp -fr /home/ubuntu/scripts/etc/* /etc"
  sudo su -c "cp -fr $CONFIG_DIRECTORY/etc/* /etc/"
  sudo chmod +x /etc/rc.local
  sudo chmod +x /home/ubuntu/scripts/cowrie-watchdog.sh
}

function start_honeypot(){
  sudo systemctl enable rc.local.service
  sudo systemctl start rc.local.service
}

function configure_log_processor()
{
   sudo chmod +x /home/ubuntu/scripts/log-processor.sh
   METADATA="http://169.254.169.254/latest/meta-data/"
   AWS_ZONE="$(curl -s $METADATA/placement/availability-zone)"
   PUBLIC_IP="$(curl -s $METADATA/public-ipv4)"
   INSTANCE_ID="$(curl -s $METADATA/instance-id)"
   KERNEL_VERSION=$(egrep -o "^kernel_version = .*$" "$COWRIE_CONFIG_FILE" | cut -d= -f2 |tr -d "^ ")
   KERNEL_BUILD=$(egrep -o "^kernel_build_string = .*$" "$COWRIE_CONFIG_FILE"  | cut -d= -f2 |tr -d "^ ")
   HARDWARE_PLATFORM=$(egrep -o "^hardware_platform = .*$" "$COWRIE_CONFIG_FILE" | cut -d= -f2 |tr -d "^ ")
   ELF_ARCH=$(egrep -o "^arch = .*$" "$COWRIE_CONFIG_FILE" | cut -d= -f2 |tr -d "^ ")
   if [ -z "$AWS_ZONE" ]; then AWS_ZONE="undetermined"; fi
   if [ -z "$PUBLIC_IP" ]; then PUBLIC_IP="undetermined"; fi
   if [ -z "$KERNEL_VERSION" ]; then KERNEL_VERSION="default"; fi 
   if [ -z "$KERNEL_BUILD" ]; then KERNEL_BUILD="default"; fi 
   # If unspecified, it defaults to the EC2 instance's architecture
   if [ -z "$HARDWARE_PLATFORM" ]; then HARDWARE_PLATFORM="x86_64"; fi
   if [ -z "$ELF_ARCH" ]; then ELF_ARCH="default"; fi 
   sed -i'' "s/__AWS_REGION__/$AWS_ZONE/" ~ubuntu/scripts/log-processor.env
   sed -i'' "s/__AWS_PUBLIC_IP__/$PUBLIC_IP/" ~ubuntu/scripts/log-processor.env
   sed -i'' "s/__AWS_INSTANCE_ID__/$INSTANCE_ID/" ~ubuntu/scripts/log-processor.env
   sed -i'' "s/__COWRIE_KERNEL_VERSION__/$KERNEL_VERSION/" ~ubuntu/scripts/log-processor.env
   sed -i'' "s/__COWRIE_KERNEL_BUILD__/$KERNEL_BUILD/" ~ubuntu/scripts/log-processor.env
   sed -i'' "s/__COWRIE_CONFIG__/$COWRIE_CONFIG/" ~ubuntu/scripts/log-processor.env
   sed -i'' "s/__COWRIE_HARDWARE_PLATFORM__/$HARDWARE_PLATFORM/" ~ubuntu/scripts/log-processor.env
   sed -i'' "s/__COWRIE_ELF_ARCH__/$ELF_ARCH/" ~ubuntu/scripts/log-processor.env
}


export DEBIAN_FRONTEND=noninteractive
# We expect user-data to return a string which corresponds to 
# an existing directory in ~ubuntu/scripts/available-configs/ 
export COWRIE_CONFIG="$(curl -s http://169.254.169.254/latest/user-data/)"
export CONFIG_DIRECTORY="/home/ubuntu/scripts/available-configs/$COWRIE_CONFIG"
export COWRIE_CONFIG_FILE="$CONFIG_DIRECTORY/cowrie/cowrie.cfg"

cleanup
configure_system
install_dependencies

# Check that we have STS credentials or shut down the instance.
# Without STS creds we cannot upload data to S3.
( aws sts get-caller-identity | jq -r ".Arn" | grep "assumed-role" ) || ( halt -p && exit 1 )

install_cowrie
configure_cowrie
configure_log_processor
start_honeypot
