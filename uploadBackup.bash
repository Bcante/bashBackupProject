#!/bin/bash
NAME="SwagCityRockers"
FILETOUPLOAD="patriots.txt"
#On a un tableau associatif nomFichierBackup -> hashSurLeSite

declare -A MAP 

# $1 : Le nom (et que le nom) du fichier qu'on veut récupérer.
function miseEnLigne () {
	local reponse=$(curl "https://daenerys.xplod.fr/backup/upload.php?login=SwagCityRockers" -F "file=@$FILETOUPLOAD")
	
	#Set l'IFS sur "=" et permet de split la réponse du serveur entre le code de retour et le hash
	IFS== read status hashsite <<< $reponse
	echo "$status"
	echo "$hashsite"
}

# $1 : Le nom (et que le nom) du fichier qu'on veut récupérer.
function getMyFile () {
	#curl "https://daenerys.xplod.fr/backup/download.php?login=SwagCityRockers&hash=d5acf475af0ba81529cdd21d50b18be1"
	curl "https://daenerys.xplod.fr/backup/download.php?login=$NAME&hash=$HASH"
}