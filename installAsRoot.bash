#!/bin/bash

function askEmail {
	mail=$(dialog --stdout --no-cancel  --ok-label "Suivant" \
		--title "Configuration de gpg" \
		--inputbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\nEntrez votre adresse email :" 20 70)
}

function askPassPhrase {
	pass=$(dialog --stdout --no-cancel  --ok-label "Suivant" \
		--title "Configuration de gpg" \
		--passwordbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\nEntrez votre mot de passe :" 20 70)

	passconfirm=$(dialog --stdout --no-cancel  --ok-label "Confirmer" \
		--title "Configuration de gpg" \
		--passwordbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\nConfirmez votre mot de passe :" 20 70)
}

#############################
## Début de l'installation ##
#############################
nomduprog="SwagCityRockers"
user=$(cat user.txt)
rm user.txt
homedir=$(cat home.txt)
rm home.txt

## Vérifie qu'on est root
root=$(whoami)
if [ $root != "root" ]; then
	echo "Ce script doit effectuer des modifications sur votre système, il a donc besoin de tous les droits."
	echo "Veuillez relancer le script et entrer votre mot de passe a nouveau."
	exit 1
fi

printf "Installation de dialog pour pouvoir procéder à l'installation de $nomduprog...\n"
apt-get -y install dialog

dialog --yes-label "Continuer" --no-label "Annuler"\
	--title "Installation de $nomduprog"\
	--yesno "Ce programme va installer $nomduprog et vous permettre de le paramètrer." 40 100

if [ $? != 0 ]; then
	echo "Au revoir !"
	exit 1
fi

## Installation des composants requis
dialog --prgbox "apt-get -y update" 40 100
dialog --prgbox "apt-get -y install tar gnupg2 curl wget sed sendmail mailutils sendmail-bin jq" 40 100

## Préparation pour GPG
nom=$(dialog --stdout --no-cancel --ok-label "Suivant" \
	--title "Configuration de gpg" \
	--inputbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\n
	Entrez votre nom pour signer les sauvegardes à votre nom :" 20 70)

askEmail
regexMail="^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
while ! [[ $mail =~ $regexMail ]]
do
	dialog --no-cancel --ok-label "Entrer une autre adresse email" \
	--title "Configuration de gpg"
	--msgbox "L'adresse email que vous avez entré n'est pas valide, veuillez réessayer." 20 70
	askEmail
done

askPassPhrase
while ! [[ $pass = $passconfirm ]]
do
	dialog --no-cancel --ok-label "Entrer à nouveau le mot de passe" \
	--title "Configuration de gpg"
	--msgbox "Les deux mots de pass entrés ne sont pas identiques, veuillez réessayer." 20 70
	askPassPhrase
done

cat > config <<EOF
      Key-Type: DSA
      Key-Length: 1024
      Subkey-Type: ELG-E
      Subkey-Length: 1024
      Name-Real: $nom
      Name-Comment: $nom
      Name-Email: $mail
      Expire-Date: 0
      Passphrase: $pass
      %pubring config.pub
      %secring config.sec
      %commit
EOF

dialog --prgbox "gpg2 --verbose --batch --gen-key config" 20 70
rm config

## Création des fichiers et dossiers de config
outputdir="/var/mesbackups"
workingdir="$homedir/backup"
mkdir $outputdir
mkdir $workingdir

touch $workingdir/backup.conf
touch $workingdir/parameters.conf

cp ./crontask.bash $workingdir/
cp ./getSynopsis.bash $workingdir/
cp ./gpg.bash $workingdir/
cp ./kublike.bash $workingdir/
cp ./menu.bash $workingdir/
cp ./uploadBackup.bash $workingdir/

chown -R $user $outputdir
chown -R $user $workingdir

echo "USER $nom" >> parameters.conf
echo "PASSPHRASE $pass" >> parameters.conf
echo "MAIL $mail" >> parameters.conf
echo "OUTPUTDIR $outputdir" >> parameters.conf