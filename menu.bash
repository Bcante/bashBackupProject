#!/bin/bash

#Imporation des fichiers bashs contenant les fonctions qui nous intéressent
# source kublike.bash Commenté pour pas avoir le file not found / backupdir not found.
source uploadBackup.bash
source getSynopsis.bash

QUIT=0
CHOIX=0
MAILREGEX="[A-Za-z0-9]+@[a-zA-Z]+\.[a-z]+"
#Positionnement des variables globales par rapport au fichier de configuration

# $1 : L'option que l'utilisateur a rentré
function aiguillageMainMenu () {
	local choixTmp=$1
	local message=""
	case $choixTmp in
		1)
		  doTheBackup
		  ;;
		2)
		  graphUpMyFile
		  ;;
		3)
		  getMyFile
	  	  ;;
	  	4)
		  getSyno  
		  ;;
		5)
		  parametrage
		  ;;
		0)
		  QUIT=1
		  ;;  

		#Quand l'utilisateur appuie sur "annuler"
		"")
		  QUIT=1
		  ;;
	esac
}

#option 1) Permet de changer les fichier/dossiers a svg
#option 2) Permet de spécifier le dossier de sortie
function parametrage {
	local choixParam=$(dialog --stdout --title "Menu principal" --menu "Menu" 0 0 0 \
		"0" "Retour" \
		"1" "Modifier les dossiers à sauvegarder" \
		"2" "Modifier le dossier de destination" \
		"3" "Modifier l'adresse mail d'envoi silencieux")
	case $choixParam in
		1)
		  nano confFile
		  ;;
		2)
		  backupdir=$(dialog --title --stdout "Nouveau dossier de destination" --dselect /home/$USER/ 0 0)
			while read -u 10 p; do
			local regex="BACKUPDIR\s(.+)"
			if [[ $p =~ $regex ]]; then
				local oldValue="${BASH_REMATCH[1]}"
				sed -i -e "s@$oldValue@$backupdir@g" backup.conf
				#TODO: vérifier si le chemin fini bien par un "/" ?
			fi
			done 10<backup.conf
		  ;;
		3)
		  #On passe par une variable locale en attendant d'être sûr que c'est une adresse mail valide
		  #Et on oublie pas d'overwrite le fichier de configuration...
	      local mailTmp=$(dialog --stdout --inputbox "Nouvelle adresse mail" 0 0)
	      
	      if [[ "$mailTmp" =~ $MAILREGEX ]]; then
			mail="$mailTmp"

			while read -u 10 p; do
			local regex="MAIL\s(.+)"
			if [[ $p =~ $regex ]]; then
				local oldValue="${BASH_REMATCH[1]}"
				sed -i -e "s@$oldValue@$backupdir@g" backup.conf
				#TODO: vérifier si le chemin fini bien par un "/" ?
			fi
			done 10<backup.conf

		  else
		  	dialog --title "Adresse mail invalide" --msgbox "Merci d'entrer une adresse mail à peu près valide." 0 0
		  fi
		  ;;
		*)
		 ;;
	esac
}

#Se base sur le fichier backup.conf pour remplir les valeurs globales qui nous seront utiles pour la suite du programme
function init {
	while read -u 10 p; do
		#Récupération de l'adresse mail
		local regex="MAIL\s(.*)" 
		if [[ $p =~ $regex ]]; then
			mail="${BASH_REMATCH[1]}"
		fi

		local regexb="BACKUPDIR\s(.*)"
		if [[ $p =~ $regexb ]]; then
			backupdir="${BASH_REMATCH[1]}"
		else
			echo "no match"
		fi
	done 10<backup.conf
}

init


while [ $QUIT -eq 0 ]; do
	echo "mail: $mail"
echo "sortie: $backupdir"
	CHOIX=$(dialog --stdout --title "Menu principal" --menu "Menu" 0 0 0 \
		"0" "Quitter" \
		"1" "Faire un Backup" \
		"2" "Mettre en ligne un backup" \
		"3" "Télécharger un backup" \
		"4" "Télécharger les synopsis" \
		"5" "Paramétres")
	aiguillageMainMenu $CHOIX
done
echo "Au revoir"


