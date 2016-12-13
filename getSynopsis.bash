#!/bin/bash
function importGPG {
	curl --retry $TRY "https://daenerys.xplod.fr/supersynopsis_signature.pub" > pubkey.key
	local curlok=$(echo $?)
	if [ "$curlok" != "0" ]; then
		if [ "$QUIETFLAG" = "1" ]; then
			#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
			echo "Tentative faite le: $DATE" | mail -s "Erreurs de connexion: Le serveur n'est pas disponnible." cantebenoit@hotmail.com #mailto
		else
			echo "Le site est indisponible, après avoir essayé $TRY fois."
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
	local filetmp='Saison_'$1'_Episode_'$2'.txt'
	if [ -f "$WHERETO/$filetmp" ]; then				
		rm $filetmp
	fi
	echo "Ah non ça existe pas $WHERETO/$filetmp"
	touch "$WHERETO/$filetmp"
}

#1 = ligne en cours du fichier curlRes2 
#2 = saison
#3 = episode
function formatSyno () {
	if [[ $1 =~ $REGEXSYNO ]]; then
		local syn01="${BASH_REMATCH[1]}"		
		local syn02="${BASH_REMATCH[2]}"
		local filetmp='Saison_'$2'_Episode_'$3'.txt'
		if [[ "$syn01" != "" ]]; then
			echo "$syn01">"$WHERETO/$filetmp"		
		fi
		if [[ "$syn02" != "" ]]; then
			echo "$syn02">>"$WHERETO/$filetmp"
		fi
	fi
}

#Permet de rendre la fonction silencieuse. On initialise le fichier de rejets
function synoBeQuiet {
	exec 2>/dev/null
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
	local regex="s=([0-9]+).*e=([0-9]+).*Episode\s[0-9]+:\s(.+)<\/a>"
	REGEXSYNO="^([a-zA-Z].*)<|<p class=\"left-align light\">(.*)<"
	importGPG

	#Pour toutes les lignes du fichier curlRes1 (celles indiquant ou trouver les synopsis)

	while read -u 10 p; do
		if [[ $p =~ $regex ]] ; then
			local saison="${BASH_REMATCH[1]}"		
			local episode="${BASH_REMATCH[2]}"
			#Récupération PGP		
			wget "https://daenerys.xplod.fr/supsyn.php?e=$episode&s=$saison" -O "$WHERETO/"'PGP_S'$saison'E'$episode -P "$WHERETO/"

			$(gpg --verify $WHERETO/PGP_S${saison}E${episode})
			local checkGPG=`echo $?`
			#Suppression des gpg si on a une mauvaise signature
			curl "https://daenerys.xplod.fr/synopsis.php?s=$saison&e=$episode" | grep -E '^([a-zA-Z].*)<|<p class="left-align light">(.*)<' > curlRes2
				
			while read -u 10 d; do
				echo "CALL CHECKFILES???"
				checkFiles $saison $episode #Permet de supprimer le fichier texte si il existe déjà
				formatSyno $d $saison $episode
			done 10<curlRes2

			if [ "$checkGPG" = "1" ]; then
				rm $WHERETO/PGP_S${saison}E${episode}
				if [ "$QUIETFLAG" = "1" ]; then
					#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
					echo "PGP_S${saison}E${episode}" >> Rejets
				fi
			fi
		fi
	done 10<curlRes
	
	#Si on est en mode quiet on s'envoie le résultat par mail
	if [ "$QUIETFLAG" = "1" ]; then
		#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
		cat Rejets | mail -s "Erreurs de téléchargement des fichiers de synopsis" cantebenoit@hotmail.com #MATILO
		rm Rejets
	fi
}

DATE=`date +%Y-%m-%d:%H:%M:%S`
QUIETFLAG=0
TRY=3
WHERETO="/home/$USER/Got"
MAILTO=

initFolder
while getopts "q" opt; do
  case $opt in
    q)
	  synoBeQuiet
	  getSyno
	  if [ -f "$Rejets" ]; then				
		rm $Rejets		
	  fi
	  touch Rejets
	  echo "Les fichiers suivants ont été rejeté pour cause de signature non conforme: " >> Rejets
	  #Rediriger les erreurs vers le null
		;;
    \?)
      echo "Option non reconnue: -$OPTARG"
      ;;
  esac
done

