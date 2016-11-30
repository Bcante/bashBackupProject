#!/bin/bash

# Exit codes : 
# 1 : File or ressource not found
# 2 : Access right problem

error=""
conf="backup.conf"
backupdir="backups/"

# Vérification des paramètres de lancement
if [ $# -gt 0 ]; then
	for (( i=0; i<=$#; i+=1 ))
	do
		index=$((i+1))
		if [ ${!i} = "--conf" ];then
			if [ $index -gt "$#" ]; then
				echo "Usage --conf <config file>"
			else
				if [ -f ${!index} ]; then
					if [ -r ${!index} ]; then
						echo "Conf file found ${!index}"
						conf=${!index}
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
						echo "Backup Directory found ${!index}"
						backupdir=${!index}
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
	if ! [ -z $error ]; then
		echo $error;
		#TODO : Récupérer code d'erreur du bloc for précédent
	fi
else
	if [ -f $conf ]; then
		if ! [ -r $conf ]; then
			error="Config File not readable"$'\n'
		fi
	else
		error="$error File not found"$'\n'
	fi
	if [ -d $backupdir ]; then
		if ! [ -r $backupdir ]; then
			error="$error BackupDir not readable"$'\n'
		fi
	else
		error="$error BackupDir not found"$'\n'
	fi
	if ! [ -z "$error" ]; then
		echo $error
		exit 1
	fi
fi



# Début de traitement des backups
# TODO : rename les var files file en générique
files=$(cat $conf)
found=""
# Lecture du fichier contennat les différents chemins à sauvegarder
for file in $files; do
	if [ -f $file ] || [ -d $file ]; then
		if [ -r $file ]; then
			found=${found}"\n"$file
		else
			error=${error}"\nProblème de droit d'accès : "$file
		fi
	else
		if ! [ -d $file ]; then
			error=${error}"\nFichier inexistant : "$file
		fi
	fi
done;
if ! [ -z "$error" ]; then
	echo -e $error
	# TODO : choisir un exit code
	exit 4;
fi

echo ----------------
echo -e $found
echo ----------------

# Création de la sauvegarde 
date=$(date +%d-%m-%Y_%H-%M)
name=${backupdir}${date}.tar.gz

# Différence entre deux backups effectuées au même moment

if [ -f $name ]; then
	count=$(find ${backupdir}${date}* -maxdepth 1 -type f | wc -l)
	name=${backupdir}${date}_${count}.tar.gz
fi
tar -zcvf $name --files-from test

# Vérification de l'existence de moins de 100 backups