#Final Script
#!/bin/bash


#Step 1. Prerequisistes and Openstack Packages
USER_NAME='root'
PASSWORD='DoNotConnect547'

echo "**********-----------Installing Packages and setting up Host networking------------*************"

# Modifying hosts file and setting up IP
echo PASSWORD | sudo cp hosts /etc/hosts
sudo ifconfig eno1 10.0.0.11 netmask 255.0.0.0
sudo ifconfig eno1 up

# Install Openstack packages
echo PASSWORD | sudo apt install -y software-properties-common
sudo add-apt-repository cloud-archive:pike
sudo apt update && apt dist-upgrade
sudo apt install -y python-openstackclient
sudo apt upgrade -y

# Install SQL
echo PASSWORD | sudo apt install -y mariadb-server python-pymysql
sudo cp 99-openstack.cnf /etc/mysql/mariadb.conf.d/99-openstack.cnf
sudo service mysql restart
sudo mysql_secure_installation                    #User will have to Enter a PASSWORD and some other options

# Install message queue
echo PASSWORD | sudo apt install -y rabbitmq-server
sudo rabbitmqctl add_user openstack $PASSWORD
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"


# Install Memcached
sudo apt install -y  memcached python-memcache
sudo cp memcached.conf /etc/memcached.conf
sudo service memcached restart

echo "******************--------------Done with the prerequisites and Installation of OS packages-------------*********"



#Step 2. Installing KEYSTONE
echo "******************--------------Installing and configuring KEYSTONE----------------***********************"

# Install and configure the DATABASE
echo PASSWORD | sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "CREATE DATABASE keystone;"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse " GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '$PASSWORD';"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '$PASSWORD';"

echo PASSWORD | sudo apt install -y keystone  apache2 libapache2-mod-wsgi
sudo cp keystone.conf /etc/keystone/keystone.conf
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage bootstrap --bootstrap-password $PASSWORD \
  --bootstrap-admin-url http://controller:35357/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

echo PASSWORD | sudo cp apache2.conf /etc/apache2/apache2.conf
sudo service apache2 restart


. ./admin-openrc.sh                                 #Source admin credentials


# Create a domain, projects, users, and roles

openstack project create --domain default \
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" demo

openstack user create --domain default \
  --password-prompt demo
openstack role create user
openstack role add --project demo --user demo user

#verification of KEYSTONE
echo "Verifyig KEYSTONE operation by requesting authentication token"

openstack token issue

echo "*************-----------------Done with KEYSTONE-----------------**************" 



#Step 3. Installing GLANCE

echo "*************-----------------Installing GLANCE-------------------**************"

# Install and configure DATABASE
echo PASSWORD | sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "CREATE DATABASE glance;"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse " GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
IDENTIFIED BY '$PASSWORD';"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
IDENTIFIED BY '$PASSWORD';"

. ./admin-openrc.sh 															#Source admin credentials

openstack user create --domain default --password-prompt glance                 #User will have to Enter a PASSWORD
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image

openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292

echo PASSWORD | sudo apt install -y glance

sudo cp glance-api.conf /etc/glance/glance-api.conf
sudo cp glance-registry.conf /etc/glance/glance-registry.conf
sudo su -s /bin/sh -c "glance-manage db_sync" glance

sudo service glance-registry restart
sudo service glance-api restart

#Verifying GLANCE
. ./admin-openrc.sh

echo "Verifying GLANCE installation by creating the image"
openstack image create "cirros" --file cirros-0.3.5-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack image list

echo "*******************----------------Done Installing GLANCE-----------------**********************"


#Step 4. Installing NOVA

echo "*******************-----------------Installing NOVA-------------------*********************"

#Creating the database

echo PASSWORD | sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "CREATE DATABASE nova_api;"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "CREATE DATABASE nova;"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "CREATE DATABASE nova_cell0;"


#Permissions

echo PASSWORD | sudo mysql -u$USER_NAME -p$PASSWORD  -Bse " GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$PASSWORD';"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$PASSWORD';"

sudo mysql -u$USER_NAME -p$PASSWORD  -Bse " GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$PASSWORD';"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$PASSWORD';"

sudo mysql -u$USER_NAME -p$PASSWORD  -Bse " GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$PASSWORD';"
sudo mysql -u$USER_NAME -p$PASSWORD  -Bse "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$PASSWORD';"


. ./admin-openrc.sh                                     #Changed here

#1. Compute service creds
openstack user create --domain default --password-prompt nova       #Users will have to Enter Password here
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute

#2. API endpoints
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1
COM
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1

openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1

#3. placement_service
openstack user create --domain default --password-prompt placement      #Users will have to Enter Password here
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement

#4. Placement API endpoints
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778



# Installing components
echo PASSWORD | sudo -S apt install nova-api nova-conductor nova-consoleauth \
  nova-novncproxy nova-scheduler nova-placement-api -y

#Configuration changes
sudo -s cp  nova.conf /etc/nova/nova.conf


sudo su -s /bin/sh -c "nova-manage api_db sync" nova
sudo su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
sudo su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
sudo su -s /bin/sh -c "nova-manage db sync" nova

#Verifying nova cell list
echo "Verifying nova cell list"
echo PASSWORD | sudo nova-manage cell_v2 list_cells

# Finalize installation
sudo service nova-api restart
sudo service nova-consoleauth restart
sudo service nova-scheduler restart
sudo service nova-conductor restart
sudo service nova-novncproxy restart

echo "**************----------------------Done installing NOVA------------------********************"


#step 5. Installing Neutron
echo "**************----------------------Done Installing NEUTRON-----------------*******************
"
# Configure database
echo PASSWORD | sudo mysql -u$USER_NAME -p$PASSWORD -Bse "CREATE DATABASE neutron;"
sudo mysql -u$USER_NAME -p$PASSWORD -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY '$PASSWORD';"
sudo mysql -u$USER_NAME -p$PASSWORD -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY '$PASSWORD';"
  
. ./admin-openrc.sh                         #Changed here
        

# create the service credentials
openstack user create --domain default --password-prompt neutron        #User will have to Enter PASSWORD here
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network

  
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696

# Self-service networks
echo PASSWORD | sudo -S apt install -y neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent
  
sudo cp neutron.conf /etc/neutron/neutron.conf
sudo cp ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
sudo cp linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sudo cp l3_agent.ini /etc/neutron/l3_agent.ini
sudo cp dhcp_agent.ini /etc/neutron/dhcp_agent.ini

# Configure the metadata agent
sudo cp metadata_agent.ini /etc/neutron/metadata_agent.ini

# Configure the Compute service to use the Networking service
sudo cp nova.conf /etc/nova/nova.conf



echo PASSWORD | sudo -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

  
sudo service nova-api restart
sudo service neutron-server restart
sudo service neutron-linuxbridge-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-metadata-agent restart
sudo service neutron-l3-agent restart

echo "****************------------------Done Installing NEUTRON----------------*******************"



#Step 6. Installing HORIZON

echo "****************------------------Installing HORIZON------------------********************"

echo PASSWORD | sudo apt install openstack-dashboard -y


sudo cp local_settings.py /etc/openstack-dashboard/local_settings.py
sudo cp openstack-dashboard.conf /etc/apache2/conf-available/openstack-dashboard.conf

sudo service apache2 reload 


#RESTART ALL THE SERVICES HERE

echo "****************------------------Done Installing HORIZON-------------*******************"


#Step 7. Restarting all the services

echo "****************------------------Restarting all the services--------------********************"

echo PASSWORD | sudo service mysql restart
sudo rabbitmq-server restart
sudo service memcached restart

echo PASSWORD | sudo service apache2 restart

echo PASSWORD | sudo service glance-registry restart
sudo servie glance-api restart

echo PASSWORD | sudo service nova-api restart
sudo service nova-consoleauth restart
sudo service nova-scheduler restart
sudo service nova-conductor restart
sudo service nova-novncproxy restart

echo PASSWORD | sudo service nova-api restart
sudo service neutron-server restart
sudo service neutron-linuxbridge-agent restart
sudo service neutron-dhcp-agent restart
sudo service neutron-metadata-agent restart
sudo service neutron-l3-agent restart

echo PASSWORD | sudo service apache2 reload