#!/bin/bash
NAME="SwagCityRockers"

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
	local regex="[a-zA-Z0-9\_]+\s([a-zA-Z0-9]+)"
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
			echo "$1 existe déjà: je vais changer son hash actuel par le nouveau."
			echo "Current hash: $oldHash"
			echo "New hash: $2"

			sed -i -e "s/$oldHash/$2/g" sent
		fi
	done 10<sent

	if [ $alreadyHere = "0" ]; then
		echo "Le fichier $1 n'est pas présent"
		echo $1 $2 >> sent
	fi
}

init
touch canttouchthis

uploadBackup canttouchthis
getMyFile canttouchthis

echo "hammer time!" >> canttouchthis

uploadBackup canttouchthis
getMyFile canttouchthis