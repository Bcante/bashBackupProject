#!/bin/bash

#Improtation des fichiers bashs contenant les fonctions qui nous intéressent
source uploadBackup.bash
source getSynopsis.bash

# $1 : L'option que l'utilisateur a rentré
function aiguillage () {
	local choix=$1
	local message=""
	case $choix in
	1)
	  message="Fonctions Maxime."
	  dialog --msgbox "$message" 0 0
	  ;;
	2)
	  upMyFile -q
	  ;;
	3)
	  getMyFile
  	  ;;
  	4)
	  getSyno  
	  ;;
	0)
	  quit=1
	  ;;  
	"")
	  quit=1
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
		"4" "Télécharger les synopsis")
	aiguillage $choix
done
echo "Au revoir"



