#!/bin/bash

## Définition des variables globales
nomduprog="SwagCityRockers"
user=$(whoami)

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

echo "Ce programme va installer et configurer $nomduprog, notre solution de backup.\n\
	Afin de procéder à l'installation, vous devez avoir sudo d'installé et lancer ce script en tant que l'utilisateur qui fera les sauvegardes."

sudo -i

## Vérifie qu'on est root
root=$(whoami)
if [ $root != "root" ]; then
	echo "Ce script doit effectuer des modifications sur votre système, il a donc besoin de tous les droits.\
		\nVeuillez relancer le script et entrer votre mot de passe a nouveau."
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
until [[ $mail =~ "^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$" ]]
do
	dialog --stdout --no-cancel --ok-label "Entrer une autre adresse email" \
	--title "Configuration de gpg"
	--msgbox "L'adresse email que vous avez entré n'est pas valide, veuillez réessayer."
	askEmail
done

askPassPhrase
until [[ $pass = $passconfirm ]]
do
	dialog --stdout --no-cancel --ok-label "Entrer à nouveau le mot de passe" \
	--title "Configuration de gpg"
	--msgbox "Les deux mots de pass entrés ne sont pas identiques, veuillez réessayer."
	askPassPhrase
done
pass=$(echo -n $pass | sha256sum)

cat > config <<EOF
      Key-Type: DSA
      Key-Length: 1024
      Subkey-Type: ELG-E
      Subkey-Length: 1024
      Name-Real: $nom
      Name-Comment: $nom
      Name-Email: $mail
      Expire-Date: 0
      Passphrase: $mdp
      %pubring config.pub
      %secring config.sec
      %commit
EOF

dialog --stdout\
	--prgbox "gpg2 --verbose --batch --gen-key config" 20 70
rm config

## Création des fichiers et dossiers de config
outputdir="/var/mesbackups"
mkdir $outputdir
touch backup.conf
touch parameters.conf

## Changement du propriétaire et des accès
chown $user $outputdir
chown $user backup.conf
chown $user parameters.conf

echo "USER $nom\n
PASSPHRASE $pass\n
MAIL $mail\n
OUTPUTDIR $outputdir" >> parameters.conf