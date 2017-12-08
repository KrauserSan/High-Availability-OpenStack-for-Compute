
#!/bin/bash

USER_NAME="root"
PASSWORD="DoNotConnect547"

source admin-openrc.sh
echo PASSWORD | sudo su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova


