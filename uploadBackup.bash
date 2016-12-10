#!/bin/bash
NAME="SwagCityRockers"

#Fonction d'initialisation pour vérifier qu'on a bien notre associations de fichiers mis en ligne
function init {
	local FILETMP="sent"
	if [ ! -f "$FILETMP" ]; then				
		touch "$FILETMP"			
	fi
}

# Pour testé, on prend que les fichiers du dir courant pour les upload.
function uploadBackup () {
	local fileToUpload=$(dialog --stdout --fselect "" 0 0)
	local reponse=$(curl "https://daenerys.xplod.fr/backup/upload.php?login=$NAME" -F "file=@$fileToUpload")
	#Set l'IFS sur "=" et permet de split la réponse du serveur entre le code de retour et le hash
	IFS== read status hashsite <<< $reponse
	#On vérifie que le site a bien reçu

	if [ "${status:0:2}" = "OK" ]; then
		addToFile $fileToUpload $hashsite
	fi
}


# $1 : Le nom (et que le nom) du fichier qu'on veut récupérer.
function getMyFile () {
	#Exemple: curl "https://daenerys.xplod.fr/backup/download.php?login=SwagCityRockers&hash=d5acf475af0ba81529cdd21d50b18be1"
	#On part à la recherche du hash correspondant dans notre fichier
	local fileToUpload=$(displayUploadedFiles)
	local hash=""
	local regex="$fileToUpload\s([a-zA-Z0-9]+)"
	while read -u 10 p; do
		echo $p
		if [[ $p =~ $regex ]]; then
			local hash="${BASH_REMATCH[1]}"
		fi
	done 10<sent
	wget "https://daenerys.xplod.fr/backup/download.php?login=$NAME&hash=$hash" -O $fileToUpload
}

# Vérifie si le fichier fait partie de ma liste de fichiers mis en ligne. 
# Si ce n'est pas le cas, alors j'écris son nom et son hash
# Sinon je met à jour le hash. 
# $1 : Le nom du fichier a vérifier
# $2 : Le hash lié au fichier
function addToFile () {
	#Repérer la ligne qui m'intéresse et changer le hash par le nouveau...
	local alreadyHere="0"
	while read -u 10 p; do
		echo $p
		local regex="$1\s([a-zA-Z0-9]+)"
		if [[ $p =~ $regex ]]; then
			local alreadyHere="1"
			local oldHash="${BASH_REMATCH[1]}"
			sed -i -e "s/$oldHash/$2/g" sent
		fi
	done 10<sent

	if [ $alreadyHere = "0" ]; then
		echo "Le fichier $1 n'est pas présent dans mon fichier de log"
		echo $1 $2 >> sent
		sed -i -e '$a\' sent
	fi
}

function displayUploadedFiles {
	local MENU_OPTIONS=
	local COUNT=0
	local OLDIFS=$IFS
	local IFS=$'\n'
	for p in `cat sent`
	do
		local regex="(.*)\s(.*)"
		#regex="([a-z\.A-Z0-9\_]+)\s([a-zA-Z0-9]+)"
		    if [[ $p =~ $regex ]]; then
		    	#echo "grp1: "${BASH_REMATCH[1]}
		    	#echo "grp2: "${BASH_REMATCH[2]}
		    	COUNT=$[COUNT+1]
	       		MENU_OPTIONS="${MENU_OPTIONS} ${BASH_REMATCH[1]} ${COUNT}"
		    fi
	done
	local IFS=$OLDIFS

	cmd=(dialog --menu "Quel fichier voulez vous récupérer?:" 22 76 16)
	options=("${MENU_OPTIONS}:1")
	fileToUpload=$(dialog --stdout --menu "Nigga" 0 0 0 $MENU_OPTIONS)
	echo $fileToUpload
}

getMyFile