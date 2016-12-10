#!/bin/bash

#Imporation des fichiers bashs contenant les fonctions qui nous intéressent
source uploadBackup.bash
source getSynopsis.bash

# $1 : L'option que l'utilisateur a rentré
function aiguillageMainMenu () {
	local choix=$1
	local message=""
	case $choix in
		1)
		  message="Fonctions Maxime."
		  dialog --msgbox "$message" 0 0
		  ;;
		2)
		  graphUpMyFile -q
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

#1) Permet de changer les fichier/dossiers a svg
#2) Permet de spécifier le dossier de sortie
function parametrage {
	local choixParam=$(dialog --stdout --title "Menu principal" --menu "Menu" 0 0 0 \
		"0" "Retour" \
		"1" "Éditer le fichier contenant les dossiers à sauvegarder" \
		"2" "Spécifier un nouveau dossier de sortie")
	case $choixParam in
		1)
		  nano confFile
		  ;;
		2)
		  local newDir=$(dialog --title --stdout "Nouveau dir de sortie" --dselect /home/$USER/ 0 0)
		  #Reste à modifier la ligne correspondante dans le fichier de conf...
		  ;;
		*)
		 ;;
	esac
	
}




while getopts "q" opt; do
  case $opt in
    q)
      echo "Passage en mode silencieux"
	  exec 2>/dev/null	
	  synoBeQuiet
	  #Rediriger les erreurs vers le null
      ;;
    \?)
      echo "Option non reconnue: -$OPTARG"
      ;;
  esac
done

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



