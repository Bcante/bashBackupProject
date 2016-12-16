#!/bin/bash

#Imporation des fichiers bashs contenant les fonctions qui nous intéressent
#source kublike.bash # Commenté pour pas avoir le file not found / backupdir not found.
source uploadBackup.bash
source getSynopsis.bash
source kublike.bash

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
		echo "all set? $UIbackupdir $UIconf "
		  doTheBackup "--backupdir" "$UIbackupdir" "--conf" "$UIconf" 
		 	#echo "Je viens de faire $name"
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
		"3" "Modifier l'adresse mail d'envoi silencieux" \
		"4" "Déchiffrage d'une backup" \
		"5" "Différence entre deux backups")
	case $choixParam in
		1)
		  nano backup.conf
		  ;;
		2)
		  backupdir=$(dialog --title --stdout "Nouveau dossier de destination" --dselect /home/$USER/ 0 0)
			while read -u 10 p; do
			local ligne=$p
			local regex="BACKUPDIR\s(.+)"
			if [[ $ligne =~ $regex ]]; then
				local oldValue="${BASH_REMATCH[1]}"
				#On doit délimiter avec des @ au lieu de / car sinon les / du chemins seront mal interprétés par bash
				sed -i -e "s@$oldValue@$backupdir@g" parameters.conf
				#TODO: vérifier si le chemin fini bien par un "/" ?
			fi
			done 10<parameters.conf
		  ;;
		3)
		  #On passe par une variable locale en attendant d'être sûr que c'est une adresse mail valide
		  #Et on oublie pas d'overwrite le fichier de configuration...
	      local mailTmp=$(dialog --stdout --inputbox "Nouvelle adresse mail" 0 0 "$mail")
	      
	      if [[ "$mailTmp" =~ $MAILREGEX ]]; then
			mail="$mailTmp"

			while read -u 10 p; do
			local ligne=$p
			local regex="MAIL\s(.+)"
			if [[ $ligne =~ $regex ]]; then
				local oldValue="${BASH_REMATCH[1]}"
				sed -i -e "s/$oldValue/$mail/g" parameters.conf
				#TODO: vérifier si le chemin fini bien par un "/" ?
			fi
			done 10<parameters.conf

		  else
		  	dialog --title "Adresse mail invalide" --msgbox "Merci d'entrer une adresse mail à peu près valide." 0 0
		  fi
		  ;;
		4)
		#DéchiffreBU
		5)
		#DiffBu
		*)
		 ;;
	esac
}

#Se base sur le fichier backup.conf pour remplir les valeurs globales qui nous seront utiles pour la suite du programme
function actualiseParam {
	while read -u 10 p; do #TODO faire sauter la ligne EOF
		#Récupération de l'adresse mail
		local regex="MAIL\s(.*)" 
		if [[ "$p" =~ $regex ]]; then
			UImail="${BASH_REMATCH[1]}"
		fi

		local regexb="BACKUPDIR\s(.*)"
		if [[ "$p" =~ $regexb ]]; then
			UIbackupdir="${BASH_REMATCH[1]}"
		fi

		local regexc="CONF\s(.*)"
		if [[ "$p" =~ $regexc ]]; then
			UIconf="${BASH_REMATCH[1]}"
		fi
	done 10<parameters.conf
}
#Demande le mot de passe à l'utilisateur
function checkAccess {
	ACCESS_DENIED="1"
	while [ $ACCESS_DENIED = "1" ]; do
		local pass=$(dialog --title "Vérification identité" --stdout --inputbox "Veuillez entrez le mot de passe\
	que vous avez renseigné à l'installation.\n(laissez la chaîne vide ou appuyez sur annuler pour abandonner)" 0 0 "")
		
		local passHash=$(echo $pass | sha256sum)
		local basePass="a"

		#On regarde si ça correspond à ce qui a été renseigné à l'installation
		if [[ "$passHash" = "$basePass" ]]; then
			dialog --title "Authentification" --msgbox "Authentification réussie" 0 0
			ACCESS_DENIED=0
		elif [[ "$pass" = "" ]]; then
			echo "Au revoir"
			exit 1
		else
			dialog --title "Authentification" --msgbox "Mot de passe incorrect" 0 0
		fi
	done
}

#checkAccess

while [ $QUIT -eq 0 ]; do
	#On s'assure que les paramètres du fichier seront toujours mis à jour
	actualiseParam
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


