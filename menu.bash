#!/bin/bash

#Imporation des fichiers bashs contenant les fonctions qui nous intéressent
# source kublike.bash Commenté pour pas avoir le file not found / backupdir not found
source uploadBackup.bash
source getSynopsis.bash

# $1 : L'option que l'utilisateur a rentré
function aiguillageMainMenu () {
	local choix=$1
	local message=""
	case $choix in
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
		  quit=1
		  ;;  

		#Quand l'utilisateur appuie sur "annuler"
		"")
		  quit=1
		  ;;
	esac
}

#option 1) Permet de changer les fichier/dossiers a svg
#option 2) Permet de spécifier le dossier de sortie
function parametrage {
	local choixParam=$(dialog --stdout --title "Menu principal" --menu "Menu" 0 0 0 \
		"0" "Retour" \
		"1" "Modifier les dossiers à sauvegarder" \
		"2" "Modifier le dossier de destination")
	case $choixParam in
		1)
		  nano confFile
		  ;;
		2)
		  NEWDIR=$(dialog --title --stdout "Nouveau dossier de destination" --dselect /home/$USER/ 0 0)
		  #Reste à modifier la ligne correspondante dans le fichier de conf...
		  ;;
		*)
		 ;;
	esac
	
}

quit=0
choix=0
while [ $quit -eq 0 ]; do
	choix=$(dialog --stdout --title "Menu principal" --menu "Menu" 0 0 0 \
		"0" "Quitter" \
		"1" "Faire un Backup" \
		"2" "Mettre en ligne un backup" \
		"3" "Télécharger un backup" \
		"4" "Télécharger les synopsis" \
		"5" "Paramétres")
	aiguillageMainMenu $choix
done
echo "Au revoir"



