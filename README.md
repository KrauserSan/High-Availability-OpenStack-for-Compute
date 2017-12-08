# 2017-fall-team-06
High Availability Openstack


## Installation Instructions
### Prerequisites
1. Change the hostnames on the contoller and compute nodes respectively to `Controller` `Compute1` `Compute2`.

### Controller node
The **controller** directory contains the configuration files and the script needed for installation of OpenStack services on the controller.
1. Run the controller_script using the command `"sh controller_script.sh"` to install the required services on the controller.
2. When prompted for a password enter a suitable password.

### Compute nodes
The **Compute1** and **Compute2** directory contains the configuration files and the script needed to install Nova and Neutron services on the respective compute nodes.
1. Run the script using the command `sh compute1_script.sh` on compute1 and `sh compute2_script.sh` on compute2.

### Post Installation
After finishing the installation on compute nodes, go back to the **controller** and run the Discover_hosts script using the command `sh Discover_hosts.sh` to add the compute nodes to the cell database.

### High Availability
Run ping.sh on controller node for high availability.
