#!/bin/bash
GROUPNAME="SwagCityRockers"

# Pour tester, on prend que les fichiers du dir courant pour les upload.
function graphUpMyFile {
	local fileToUpload=$(dialog --title "Sélectionner le fichier à uploader" --stdout --fselect "" 0 0)
	upload $fileToUpload
}

# Corps de la méthode pour mettre en ligne un fichier
# $1 : Le fichier à mettre en ligne 
function upload () {
	local fileToUpload=$1
	local reponse=$(curl "https://daenerys.xplod.fr/backup/upload.php?login=$GROUPNAME" -F "file=@$fileToUpload")
}

function getMyFile () {
	#Exemple: curl "https://daenerys.xplod.fr/backup/download.php?login=SwagCityRockers&hash=d5acf475af0ba81529cdd21d50b18be1"
	#On part à la recherche du hash correspondant dans notre fichier (la fonction appelée va modifier ASSOCIATEDHASH)
	displayUploadedFilesv2
	if [ "$ASSOCIATEDHASH" != "" ]; then
		wget "https://daenerys.xplod.fr/backup/download.php?login=$GROUPNAME&hash=$ASSOCIATEDHASH" -O $ASSOCIATEDGROUPNAME
	else
		dialog --title "Impossible d'afficher les backups" --msgbox "Soit vous avez annulé l'opération précédente, soit vous n'avez pas encore mis en ligne de backup." 0 0
	fi
}

# Vérifie si le fichier fait partie de ma liste de fichiers mis en ligne. 
function displayUploadedFilesv2 {
	curl -s "https://daenerys.xplod.fr/backup/list.php?login=$GROUPNAME" | jq '.[] | .name' > filelist
	curl -s "https://daenerys.xplod.fr/backup/list.php?login=$GROUPNAME" | jq '.[] | .hash' > hashlist
	#Suppression des quotes
	$(sed -i 's/\"//g' filelist)
	$(sed -i 's/\"//g' hashlist)
	local LIGNE=0
	local menuOptions=
	ASSOCIATEDHASH=""

	# Cette boucle parcours le fichier contenant tout ce que j'ai pu upload sur le serveur. Pour chaque fichier en ligne, je 
	# le rajoute à menuOptions qui va ensuite contenir tous les fichiers qu'on peut récupérer
	for i in `cat filelist`; do
		LIGNE=$[LIGNE+1]
		local menuOptions="${menuOptions} $LIGNE $i"
	done
	echo $menuOptions

	if [ "$LIGNE" != "0" ]; then
		local numLigne=$(dialog --stdout --menu "Sélectionner le fichier à récupérer depuis le cloud (tm)" 0 0 0 $menuOptions)
		echo $fileToUpload
		ASSOCIATEDHASH=$(sed "${numLigne}q;d" hashlist)
		ASSOCIATEDGROUPNAME=$(sed "${numLigne}q;d" filelist)
		rm filelist
		rm hashlist
	fi

}