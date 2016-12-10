#!/bin/bash
DATE=`date +%Y-%m-%d:%H:%M:%S`
QUIETFLAG=0
TRY=3
WHERETO="/home/$USER/got"

function importGPG {
	curl --retry $TRY "https://daenerys.xplod.fr/supersynopsis_signature.pub" > pubkey.key
	curlok=$(echo $?)
	if [ "$curlok" != "0" ]; then
		echo "Le site est indisponible, après avoir essayé $TRY fois."
		if [ "$QUIETFLAG" = "1" ]; then
			#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
			echo "Tentative faite le: $DATE" | mail -s "Erreurs de connexion: Le serveur n'est pas disponnible." cantebenoit@hotmail.com
		fi
		exit 1
	fi

	gpg --import pubkey.key
}

function initFolder {
	if [ ! -d "$WHERETO" ]; then
		mkdir "$WHERETO"			
	fi
}

#1 : Saison
#2 : Episode
function checkFiles () {
	FILETMP='Saison '$1' Episode '$2'.txt'
	if [ -f "$FILETMP" ]; then				
		rm $FILETMP		
	fi
	touch "$WHERETO/$FILETMP"
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
			echo "$SYNO1">>"$WHERETO/$FILETMP"		
		fi
		if [[ "$SYNO2" != "" ]]; then
			echo "$SYNO2">>"$WHERETO/$FILETMP"
		fi
	fi
}

#Permet de rendre la fonction silencieuse. On initialise le fichier de rejets
function synoBeQuiet {
	QUIETFLAG=1
	if [ -f "$Rejets" ]; then				
		rm $Rejets		
	fi
	touch Rejets
	echo "Les fichiers suivants ont été rejeté pour cause de signature non conforme: " >> Rejets
}

#Option -q : quiet: La sortie d'erreur n'est pas affichée, si des fichiers ne peuvent être vérifié on remplit un fichier
# qui sera envoyé par mail


#Fonction principale qui lance le téléchargement de tous les synopsis
function getSyno {
	IFS=$'\n'
	curl 'https://daenerys.xplod.fr/synopsis.php' | grep -e '"synopsis.php' | grep -E '<a.*>(.*)</a>' > curlRes
	regex="s=([0-9]+).*e=([0-9]+).*Episode\s[0-9]+:\s(.+)<\/a>"
	REGEXSYNO="^([a-zA-Z].*)<|<p class=\"left-align light\">(.*)<"
	importGPG

	#Pour toutes les lignes du fichier curlRes1 (celles indiquant ou trouver les synopsis)
	while read -u 10 p; do
		if [[ $p =~ $regex ]] ; then
			SAISON="${BASH_REMATCH[1]}"		
			EPISODE="${BASH_REMATCH[2]}"
			#Récupération PGP		
			wget "https://daenerys.xplod.fr/supsyn.php?e=$EPISODE&s=$SAISON" -O "$WHERETO/"'PGP_S'$SAISON'E'$EPISODE -P "$WHERETO/"

			$(gpg --verify $WHERETO/PGP_S${SAISON}E${EPISODE})
			checkGPG=`echo $?`
			#Suppression des gpg si on a une mauvaise signature
			curl "https://daenerys.xplod.fr/synopsis.php?s=$SAISON&e=$EPISODE" | grep -E '^([a-zA-Z].*)<|<p class="left-align light">(.*)<' > curlRes2
				
			while read -u 10 d; do
				formatSyno $d $SAISON $EPISODE
			done 10<curlRes2

			if [ "$checkGPG" = "1" ]; then
				rm $WHERETO/PGP_S${SAISON}E${EPISODE}
				if [ "$QUIETFLAG" = "1" ]; then
					#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
					echo "PGP_S${SAISON}E${EPISODE}" >> Rejets
				fi
			fi
		fi
	done 10<curlRes

	#Si on est en mode quiet on s'envoie le résultat par mail
	if [ "$QUIETFLAG" = "1" ]; then
		#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
		echo "Envoi du mail en cours..."
		cat Rejets | mail -s "Erreurs de téléchargement des fichiers de synopsis" cantebenoit@hotmail.com
		rm Rejets
	fi
}