#!/bin/bash
curl 'https://daenerys.xplod.fr/synopsis.php' | grep -e '"synopsis.php' | grep -E '<a.*>(.*)</a>' > curlRes
regex="s=([0-9]+).*e=([0-9]+).*Episode\s[0-9]+:\s(.+)<\/a>"

if [ ! -d "/home/$USER/got" ]; then
	mkdir "/home/$USER/got"			
fi

while read -u 10 p; do
	if [[ $p =~ $regex ]] ; then
		SAISON="${BASH_REMATCH[1]}"		
		EPISODE="${BASH_REMATCH[2]}"
		#Récupération PGP		
		wget "https://daenerys.xplod.fr/supsyn.php?e=$EPISODE&s=$SAISON" -O "/home/$USER/got/"'PGP_S'$SAISON'E'$EPISODE -P "/home/$USER/got/"

		#Récupération synopsis
		curl "https://daenerys.xplod.fr/synopsis.php?s=$SAISON&e=$EPISODE" | grep -E '^([a-zA-Z].*)<|<p class="left-align light">(.*)<' > curlRes2
		REGEXSYNO="^([a-zA-Z].*)<|<p class=\"left-align light\">(.*)<"
		while read -u 10 d; do
			if [[ $d =~ $REGEXSYNO ]] ; then
				SYNO1="${BASH_REMATCH[1]}"		
				SYNO2="${BASH_REMATCH[2]}"
				
				FILETMP='Saison '$SAISON' Episode '$EPISODE'.txt'
				if [ -f "$FILETMP" ]; then				
					rm $FILETMP		
				fi
				touch "/home/$USER/got/$FILETMP"
				echo "$SYNO1">"/home/$USER/got/$FILETMP"
				echo "$SYNO2">>"/home/$USER/got/$FILETMP"
			fi		
		done 10<curlRes2
	fi
done 10<curlRes


