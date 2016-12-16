#!/bin/bash

# Exit codes : 
# 1 : File or ressource not found
# 2 : Access right problem

###########################################
## Définition des fonctions du programme ##
###########################################

# Fonction d'affichage des erreurs
# Params : 
	# $1 : Message d'erreur
	# $2 : exit code

	
logger () {
	if [ $QUIETFLAG -eq 0 ]; then
		if [ $# -ge 1 ]; then
			if [ -n "$1" ]; then 
				if [ $QUIETFLAG -eq 0 ]; then
					dialog --title "Une erreur à été rencontrée" --msgbox "${1}" 0 0
				else
					if [ -z $ERRORS ]; then
						ERRORS="$1"
					else
						ERRORS="$ERRORS $1"
					fi
				fi
			fi
		else
			logger "Logger called but no params found" 1
		fi
		if [ $# -eq 2 ]; then
			if [ -n "$2" ]; then
				if [ $QUIETFLAG -eq 0 ]; then
					exit $2
				else
					if [ -z $ERRORS ]; then
						ERRORS="$1"
					else
						ERRORS="$ERRORS $1"
					fi
					echo $ERRORS >> Errors.txt
					sendMail
				fi
			fi
		fi
	fi
}

# Vérification des paramètres de lancement
function verifyParams {
	local pimpMyConf=false
	local pimpMyBackupDir=false
	if [ $# -gt 0 ]; then
		for (( i=0; i<=$#; i+=1 )); do
			local index=$((i+1))
			if [ "${!i}" = "--conf" ];then
				if [ $index -lt $# ]; then
					if [ -f ${!index} ]; then
						if [ -r ${!index} ]; then
							CONF=${!index}
							pimpMyConf=true
						else
							logger "File not readable" 2
						fi
					else
						logger "File not found" 1
					fi
				fi
			elif [ "${!i}" = "--BACKUPDIR" ]; then
				if [ $index -lt $# ]; then
					if [ -d ${!index} ]; then
						if [ -r ${!index} ]; then
							BACKUPDIR=${!index}
							pimpMyBackupDir=true
						else
							logger "Directory not readable" 2
						fi
					else
						logger "Backup Directory not found" 1
					fi
				fi
			elif [ "${!i}" = "-q" ] || [ "${!index}" = "-q" ]; then
				QUIETFLAG=1
			fi
		done
	else
		local error=""
		if [ -f $CONF ]; then
			if ! [ -r $CONF ]; then
				error="Config File not readable"$'\n'" "
			fi
		else
			if [ pimpMyConf ]; then
					touch $CONF
				else
					error="${error}File not found"$'\n'
				fi
		fi
		if ! [ -d $BACKUPDIR ]; then
			if [ pimpMyBackupDir ]; then
				mkdir $BACKUPDIR
			else
				error="${error} BackupDir not found"$'\n'" "
			fi
		fi
		if [ -n "$error" ]; then
			logger "$error" 1
		fi
	fi
}

# Lecture des chemins surveillés
function readPaths {
	local found=""
	local error=""
	# Lecture du fichier contenant les différents chemins à sauvegarder
	while read -r line; do
		if [ -f "$line" ] || [ -d "$line" ]; then
			if [ -r "$line" ]; then
				found+="$line "
			else
				error=${error}"\nProblème de droit d'accès : $line"
			fi
		else
			if ! [ -d $line ]; then
				error=${error}"\nFichier inexistant : $line"
			fi
		fi
	done < $CONF;
	if [ -z "$found" ]; then
		logger "Aucun fichier n'a été trouvé, vérifiez que le fichier de configuration contient au moins un fichier" 1
	else	
		doTheTar "$found"
	fi
	if [ $QUIETFLAG -eq 0 ] && [ -n "$error" ]; then
		dialog --title "Tous les fichiers n'ont pas étés trouvés, continuer ?" --yesno "$error" 0 0
		local answer=$?
		echo $answer
		if [ $answer -ne 0 ]; then
			exit 4
		fi
	fi
}

# Création du nom de la sauvegarde
function chooseBackupName {
	DATE=$(date +%Y-%m-%d_%H-%M)
	NAME=${BACKUPDIR}${DATE}.tar.gz
	# Différence entre deux backups effectuées au même moment
	if [ -f $NAME ]; then
		local count=$(find ${BACKUPDIR}${date}* -maxdepth 1 -type f | wc -l)
		NAME=${BACKUPDIR}${DATE}_${count}.tar.gz
	fi
}

# Création de la sauvegarde
function doTheTar {
	local files="$1" "${HOME}/Got"
	local error="$(tar vcfz ${NAME} ${files} 2>&1 > /dev/null)"
	if [ -n "$error" ]; then
		logger "$error"
	fi
}

# Maintien du nombre de backup a 100 maximum
function clearOldBackups {
	local backupCount=0
	backupCount=`ls $BACKUPDIR | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}(_[0-9]+)?\.tar\.gz" | wc -l`
	local returnCode=0
	if [ $backupCount -ge 100 ]; then
		file=`ls -tr backups | head -n 1`
		`rm ${BACKUPDIR}$file`
		returnCode=$?
	fi
	if [ $QUIETFLAG -eq 0 ]; then
		if [ "$returnCode" -eq 0 ]; then
			dialog --msgbox "La sauvegarde est terminée" 0 0
		else
			logger "Erreur lors du nettoyage de l'historique" 5
		fi	
	fi
}

# Fonction qui créé une backup
function doTheBackup {
	verifyParams "$@"
	chooseBackupName
	readPaths
	clearOldBackups
	encrypt "$NAME"
}

function decryptBackup {
	local tarGET=`dialog --stdout --title "Choisissez la backup à traiter" --fselect ${BACKUPDIR}/ 0 0`
	if [ -n tarGet ]; then
		local dirGET=`dialog --stdout --title "Choisissez la backup à traiter" --fselect ${BACKUPDIR}/ 0 0`
		if [ -n dirGET ]; then
			if [ -f $tarGet ]; then
				decrypt $tarGet ${tarGet:-4} 
			fi
		fi
	fi
}

function diffBackup {
	tarD=`dialog --stdout --title "Choisissez la première backup à comparer" --fselect $BACKUPDIR 0 0`
	if [ -n $tarD ]; then
		reTarD=`dialog --stdout --title "Choisissez la seconde backup à comparer" --fselect $BACKUPDIR 0 0`
		if [ -n $reTarD ]; then
			diffs=$(diff <(tar -tvf $tarD | rev | cut -d\/ -f1 | rev) <(tar -tvf $reTarD | rev | cut -d\/ -f1 | rev))
			if [ -z $diffs ]; then
				diffs="Les deux backups sont identiques"
			fi
			dialog --title "Différence(s) entre les backup" --msgbox "$diffs" 0 0
		fi
	fi
}

###############################
## Préparation des variables ##
###############################
CONF="backup.conf"
BACKUPDIR="/var/mesbackups/"
DATE=$(date +%Y-%m-%d_%H-%M)
NAME=""
ERRORS=""
###############################
## Source des autres scritps ##
###############################
source gpg.bash
source getSynopsis.bash

###############################
## Donneés de test pour diff ##
###############################
#echo "/home/bleacks/MEGAsync/MIAGE/L3/Script/bashBackupProject/test/file1.txt" > $CONF
#doTheBackup "--backupdir" "$BACKUPDIR" "--conf" "$CONF"
#echo "/home/bleacks/MEGAsync/MIAGE/L3/Script/bashBackupProject/test/file2.txt" >> $CONF
#doTheBackup "--backupdir" "$BACKUPDIR" "--conf" "$CONF"
#diffBackup

	# MUST HAVE
# TODO : Changer params d'entree pour le mode quiet
# TODO : Refactor la comparaison de backups pour eviter les problèmes
# TODO : Faire interpréter les chemins par bash pour remplacer les $USER et autres
# TODO : Ajouter une fonction qui utilise les droits admins pour créer répertoire de backup

	# OPTIONAL
# TODO : définir des normes de taille régulière

	# CHECK
# TODO : Refactor globaux
# TODO : Voir avec Val pour la fonction decrypt (params)
# TODO : Ajouter l'envoi des erreurs par mail lors de l'execution avec -q
# TODO : Créer les fichiers de base s'ils n'existent pas
# TODO : Ajouter un script qui vérifie que les répertoires de Conf sont bien créés
# TODO : rediriger les erreurs vers Errors.txt et delete la variable globale
# TODO : tester avec des chemins absolus
# TODO : vérifier que les valeurs retournées sont bien catch
# TODO : Ajouter une variable globale pour les erreurs