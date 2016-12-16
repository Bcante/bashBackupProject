#!/bin/bash

function importGPG {
	curl --retry $TRY "https://daenerys.xplod.fr/supersynopsis_signature.pub" > pubkey.key
	local curlok=$(echo $?)
	if [ "$curlok" != "0" ]; then
		if [ "$QUIETFLAG" = "1" ]; then
			#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
			if [ "INCORRECT_MAIL_FLAG" != "1" ]; then
				echo "Tentative faite le: $DATE" | mail -s "Erreurs de connexion: Le serveur n'est pas disponnible." $mail #mailto	
			fi
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
	local filetmp='Saison '$1' Episode '$2'.txt'
	if [ -f "$WHERETO/$filetmp" ]; then				
		rm "$WHERETO/$filetmp"
	fi
	touch "$WHERETO/$filetmp"
}

#1 = ligne en cours du fichier curlRes2 
#2 = saison
#3 = episode
function formatSyno () {
	if [[ $1 =~ $REGEXSYNO ]]; then
		local syn01="${BASH_REMATCH[1]}"		
		local syn02="${BASH_REMATCH[2]}"
		local filetmp='Saison '$2' Episode '$3'.txt'
		if [[ "$syn01" != "" ]]; then
			echo "$syn01">"$WHERETO/$filetmp"		
		fi
		if [[ "$syn02" != "" ]]; then
			echo "$syn02">>"$WHERETO/$filetmp"
		fi
	fi
}

#Permet de rendre la fonction silencieuse. On initialise le fichier d'erreurs
function synoBeQuiet {
	exec 2>/dev/null
	QUIETFLAG=1
	if [ -f "$Errors.txt" ]; then				
		rm Errors.txt
	fi
	touch Errors.txt
	#On récupère l'adresse mail à qui envoyer le fichier grâce à notre backup.conf.
	getMail
}

function getMail {
	#En cas d'adresse mail invalide l'opération se déroule quand même, mais n'envoie pas de mail
	local oldIFS=$IFS
	IFS=$'\n'
	regex="MAIL\s(.*)"
	for i in `cat parameters.conf`; do
		if [[ $i =~ $regex ]]; then
			tmpMail="${BASH_REMATCH[1]}"
			if [[ $tmpMail =~ $MAILREGEX ]]; then
				mail=$tmpMail
			else	
				INCORRECT_MAIL_FLAG=1
			fi
		fi
	done
	IFS=$oldIFS
}

#Option -q : quiet: La sortie d'erreur n'est pas affichée, si des fichiers ne peuvent être vérifié on remplit un fichier
# qui sera envoyé par mail


#Fonction principale qui lance le téléchargement de tous les synopsis
function getSyno {
	IFS=$'\n'
	curl 'https://daenerys.xplod.fr/synopsis.php' | grep -e '"synopsis.php' | grep -E '<a.*>(.*)</a>' > curlRes
	local regex="s=([0-9]+).*e=([0-9]+).*Episode\s[0-9]+:\s(.+)<\/a>"
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
				checkFiles $saison $episode #TODO CA MARCHE PAS DE OUF
				formatSyno $d $saison $episode
			done 10<curlRes2

			if [ "$checkGPG" = "1" ]; then
				rm $WHERETO/PGP_S${saison}E${episode}
				if [ "$QUIETFLAG" = "1" ]; then
					#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
					echo "PGP_S${saison}E${episode}" >> Errors.txt
				fi
			fi
		fi
	done 10<curlRes
	
	#Si on est en mode quiet on s'envoie le résultat par mail
	if [ "$QUIETFLAG" = "1" ]; then
		if [ "$INCORRECT_MAIL_FLAG" != "1" ]; then
			#CETTE PARTIE NECESSITE UN FICHIER DE CONFIGURATION
			cat Errors.txt | mail -s "Erreurs de téléchargement des fichiers de synopsis" $mail #MATILO
			rm Errors.txt
		else
			echo "Adresse mail invalide: Le fichier de log ne peut être envoyé"
		fi
	fi
}

QUIETFLAG=0
TRY=3
WHERETO="/home/$USER/Got"
MAILREGEX="[A-Za-z0-9]+@[a-zA-Z]+\.[a-z]+"
INCORRECT_MAIL_FLAG=0
REGEXSYNO="^([a-zA-Z].*)<|<p class=\"left-align light\">(.*)<"

initFolder
while getopts "q" opt; do
  case $opt in
    q)
	  synoBeQuiet
	  getSyno				
	  rm $Errors.txt
	  echo "Les fichiers suivants ont été rejeté pour cause de signature non conforme: " >> Errors.txt
	  #Rediriger les erreurs vers le null
		;;
    \?)
      echo "Option non reconnue: -$OPTARG"
      ;;
  esac
done