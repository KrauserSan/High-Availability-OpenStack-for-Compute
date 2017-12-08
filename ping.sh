#!/bin/bash

EVACUATE=0

while true
 do
   ping -c 1 10.0.0.12 2>&1 >/dev/null
   if [ $? -eq 0 ];
     then echo "Compute 1 is reachable";
   else echo "Compute 1 is not reachable";
      openstack compute service set --enable compute2 nova-compute
      
      while true
      do 
        nova host-evacuate compute1 | grep -i 'true' &> /dev/null 
        if [ $? -eq  0 ] 
         then  echo "Evacuating "
         EVACUATE=1
	 break;
        fi
        sleep 2
        echo "Still evacuating"
      done 
   
   fi
   echo "Evacuate value : $EVACUATE"   
   if [ $EVACUATE -eq 1  ]
    then echo "Exiting second loop"
      break;
   fi
   sleep 2
done 
