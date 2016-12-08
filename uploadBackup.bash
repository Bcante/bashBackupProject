#!/bin/bash
NAME="SwagCityRockers"

#On a un tableau associatif nomFichierBackup -> hashSurLeSite

#Fonction d'initialisation pour vérifier qu'on a bien notre associations de fichiers mis en ligne
function init {
	local FILETMP="sent"
	if [ ! -f "$FILETMP" ]; then				
		touch "$FILETMP"			
	fi
}

# $1 : Le nom (et que le nom) du fichier qu'on veut récupérer.
function uploadBackup () {
	local fileToUpload="$1"
	local reponse=$(curl "https://daenerys.xplod.fr/backup/upload.php?login=$NAME" -F "file=@$fileToUpload")
	echo "Réponse serveur: $reponse"
	#Set l'IFS sur "=" et permet de split la réponse du serveur entre le code de retour et le hash
	IFS== read status hashsite <<< $reponse
	#On vérifie que le site a bien reçu
	echo "Pour l'upload de $fileToUpload"
	echo "$status"
	echo "$hashsite"

	if [ "${status:0:2}" = "OK" ]; then
		addToFile $fileToUpload $hashsite
	fi
}

# $1 : Le nom (et que le nom) du fichier qu'on veut récupérer.
function getMyFile () {
	#Exemple: curl "https://daenerys.xplod.fr/backup/download.php?login=SwagCityRockers&hash=d5acf475af0ba81529cdd21d50b18be1"
	#On part à la recherche du hash correspondant dans notre fichier
	local hash=""
	regex="[a-zA-Z0-9\_]+\s([a-zA-Z0-9]+)"
	while read -u 10 p; do
		echo $p
		if [[ $p =~ $regex ]]; then
			local hash="${BASH_REMATCH[1]}"
			echo "match hash is "$hash
		fi
	done 10<sent
	echo "https://daenerys.xplod.fr/backup/download.php?login=$NAME&hash=$hash"
	curl "https://daenerys.xplod.fr/backup/download.php?login=$NAME&hash=$hash"
}

#Vérifie si le fichier fait partie de ma liste de fichiers mis en ligne. Si ce n'est pas le cas, alors j'écris son nom et son hash
# $1 : Le nom du fichier a vérifier
# $2 : Le hash lié au fichier
function addToFile () {
	local resGrep=`grep sent -e $1`

	if [ "$resGrep" = "" ] 
		then
			echo "Rajout du fichier $1 (hash: $2) a mes envois..."
			echo "$1 $2" >> sent
		else 
			echo "J'ai déjà mis en 	ligne le fichier $1"
	fi;
}

init
uploadBackup stop
getMyFile "stop"