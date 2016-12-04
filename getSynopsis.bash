#!/bin/bash


function initFolder {
	if [ ! -d "/home/$USER/got" ]; then
		mkdir "/home/$USER/got"			
	fi
}

#1 : Saison
#2 : Episode
function checkFiles () {
	FILETMP='Saison '$1' Episode '$2'.txt'
	if [ -f "$FILETMP" ]; then				
		rm $FILETMP		
	fi
	touch "/home/$USER/got/$FILETMP"
}

#1 = ligne en cours du fichier curlRes2 
#2 = saison
#3 = episode
function formatSyno () {
	if [[ $1 =~ $REGEXSYNO ]]; then
		SYNO1="${BASH_REMATCH[1]}"		
		SYNO2="${BASH_REMATCH[2]}"
		FILETMP='Saison '$2' Episode '$3'.txt'
		if [[ "$SYNO1" != "" ]]; then
			echo "$SYNO1">>"/home/$USER/got/$FILETMP"		
		fi
		if [[ "$SYNO2" != "" ]]; then
			echo "$SYNO2">>"/home/$USER/got/$FILETMP"
		fi
		
	fi
}

IFS=$'\n'
curl 'https://daenerys.xplod.fr/synopsis.php' | grep -e '"synopsis.php' | grep -E '<a.*>(.*)</a>' > curlRes
regex="s=([0-9]+).*e=([0-9]+).*Episode\s[0-9]+:\s(.+)<\/a>"
REGEXSYNO="^([a-zA-Z].*)<|<p class=\"left-align light\">(.*)<"

#Pour toutes les lignes du fichier curlRes1 (celles indiquant ou trouver les synopsis)
while read -u 10 p; do
	if [[ $p =~ $regex ]] ; then
		SAISON="${BASH_REMATCH[1]}"		
		EPISODE="${BASH_REMATCH[2]}"
		checkFiles $SAISON $EPISODE

		#Récupération PGP		
		wget "https://daenerys.xplod.fr/supsyn.php?e=$EPISODE&s=$SAISON" -O "/home/$USER/got/"'PGP_S'$SAISON'E'$EPISODE -P "/home/$USER/got/"

		#Récupération synopsis
		curl "https://daenerys.xplod.fr/synopsis.php?s=$SAISON&e=$EPISODE" | grep -E '^([a-zA-Z].*)<|<p class="left-align light">(.*)<' > curlRes2
		
		while read -u 10 d; do
			formatSyno $d $SAISON $EPISODE
		done 10<curlRes2
	fi
done 10<curlRes


