#!/bin/bash

USER_NAME="root"
PASSWORD="DoNotConnect547"
IP_ADD=10.0.0.13


#Step 1. Installing OS packages
echo "********************-------------Installing the prerequisites and OpenStack packages--------------------*****************"

# Modify host
echo PASSWORD | sudo cp hosts /etc/hosts
sudo ifconfig eno1 $IP_ADD netmask 255.0.0.0
sudo ifconfig eno1 up

# Install Openstack packages
echo PASSWORD | sudo apt install -y software-properties-common
sudo apt update && apt dist-upgrade
sudo apt upgrade -y
sudo add-apt-repository cloud-archive:pike
sudo apt install -y python-openstackclient

echo "*********************---------------Done Installing the packages-----------------******************************"


#Step 2. Installing NOVA


echo "*********************----------------Installing NOVA--------------------******************************"


echo PASSWORD | sudo apt install nova-compute -y

sudo -s cp  nova2.conf /etc/nova/nova.conf


# Finalize installation
sudo service nova-compute restart

#GO and configure the controller

echo "************* Go to the Controller to run install_nova_controller ***********"

echo "*************--------------------------Done Installing NOVA----------------------*************************"



#Step 3. Installing Neutron


echo "**************---------------------------Installing NEUTRON--------------------****************************"

echo PASSWORD | sudo apt install neutron-linuxbridge-agent -y

sudo -s cp  neutron.conf /etc/neutron/neutron.conf
sudo -s cp  linuxbridge_agent2.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini


#finalize
echo PASSWORD | sudo service nova-compute restart
sudo service neutron-linuxbridge-agent restart

echo "*********************************-------------------------------Done Installing NEUTRON---------------------------***********************"

