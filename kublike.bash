#!/bin/bash

# Exit codes : 
# 1 : File or ressource not found
# 2 : Access right problem

for (( i=0; i<=$#; i+=1 ))
do
	index=$((i+1))
	if [ ${!i} = "--conf" ];then
		if [ $index -gt "$#" ]; then
			echo "Usage --conf <config file>"
		else
			if [ -f ${!index} ]; then
				if [ -r ${!index} ]; then
					echo File found
				else
					echo File not readable
					exit 2
				fi
			else
				echo File not found
				exit 1
			fi
		fi
	elif [ ${!i} = "--backupdir" ]; then
		if [ $index -gt $# ]; then
			echo "Usage --backupdir <directory>"
		else
			if [ -d ${!index} ]; then
				if [ -r ${!index} ]; then
					echo Backup Directory found
				else
					echo Directory not readable
					exit 2
				fi
			else
				echo Backup Directory not found
				exit 1
			fi
		fi
	fi
done
