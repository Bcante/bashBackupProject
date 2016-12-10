#!/bin/bash

#Improtation des fichiers bashs contenant les fonctions qui nous intéressent
source uploadBackup.bash

# $1 : L'option que l'utilisateur a rentré
function aiguillage () {
	local choix=$1
	local message=""
	case $choix in
	1)
	  message="Fonctions maximes."
	  dialog --msgbox "$message" 0 0
	  ;;
	2)
	  upMyFile
	  ;;
	3)
	  getMyFile
  	  ;;
	0)
	  quit=1
	  ;;  
	*)
	  message="Vous n'avez pas le droit d'être ici!"
	  ;;
	esac
}

quit=0
while [ $quit -eq 0 ]; do
	choix=$(dialog --stdout --title "Menu principal" --menu "Menu" 0 0 0 \
		"0" "Quitter" \
		"1" "Faire un Backup" \
		"2" "Mettre en ligne un backup" \
		"3" "Télécharger un backup") 
	aiguillage $choix
done
echo "Au revoir"



