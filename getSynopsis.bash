#!/bin/bash
curl 'https://daenerys.xplod.fr/synopsis.php' | grep -e '"synopsis.php' | grep -E '<a.*>(.*)</a>' > curlRes
regex="s=([0-9]+).*e=([0-9]+).*Episode\s[0-9]+:\s(.+)<\/a>"

while read -u 10 p; do
	if [[ $p =~ $regex ]] ; then
		SAISON="${BASH_REMATCH[1]}"		
		EPISODE="${BASH_REMATCH[2]}"
		#Récupération PGP		
		wget "https://daenerys.xplod.fr/supsyn.php?e=$EPISODE&s=$SAISON" -O 'PGP_S'$SAISON'E'$EPISODE
		#Récupération synopsis
		curl "https://daenerys.xplod.fr/synopsis.php?s=$SAISON&e=$EPISODE" | grep -E '^([a-zA-Z].*)<|<p class="left-align light">(.*)<' > curlRes2
		REGEXSYNO="^([a-zA-Z].*)<|<p class=\"left-align light\">(.*)<"
		while read -u 10 d; do
			if [[ $d =~ $REGEXSYNO ]] ; then
				SYNO1="${BASH_REMATCH[1]}"		
				SYNO2="${BASH_REMATCH[2]}"
				touch 'RESUME_S'$SAISON'E'$EPISODE
				echo $SYNO1>>'RESUME_S'$SAISON'E'$EPISODE
				echo $SYNO2>>'RESUME_S'$SAISON'E'$EPISODE
			fi		
		done 10<curlRes2
	fi
done 10<curlRes


