#!/bin/bash

logpath=/home/csc547/Desktop/zookeeper-3.4.11/zookeeper.out
EVACUATE=0

while true; do
	val=$( tail -n 10 $logpath | grep -c -i "GOODBYE" )
	if [ $val -eq 0 ]
		then 
		sleep 2
		echo "Compute2 is healthy!"
	else
		echo "Compute2 has failed!"
		echo "Begin Evacuation of Compute2"
		openstack compute service set --enable compute1 nova-compute

		while true
		do 
			nova host-evacuate Compute2 | grep -i 'true' &> /dev/null
			if [ $? -eq 0 ]
			then EVACUATE=1
				break;
			fi
			sleep 5
			echo "Still evacuating"
		done
	fi
	if [ $EVACUATE -eq 1 ]
		then echo "Evacuation of Compute2 is complete"
		break;
	fi
done