#!/bin/bash

## Vérifie qu'on est root
user=$(whoami)
if [ $user != "root" ]; then
	echo "Ce script doit effectuer des modifications sur votre système, il a donc besoin de tous les droits.\
			\nVeuillez exécuter ce script en tant de super utilisateur."
	exit 1
fi

echo "Installation de dialog pour pouvoir procéder à l'installation de SwagCityRockers..."
apt-get -y install dialog

dialog --yes-label "Continuer" --no-label "Annuler"\
	--title "Installation de SwagCityRockers"\
	--yesno "Ce programme va installer SwagCityRockers et vous permettre de le paramètrer." 40 100

if [ $? != 0 ]; then
	echo "Au revoir !"
	exit 1
fi

## Installation des composants requis
dialog --prgbox "apt-get -y update" 40 100
dialog --prgbox "apt-get -y install tar gnupg2 curl wget sed sendmail mailutils sendmail-bin" 40 100

## Préparation pour GPG
nom=$(dialog --stdout --no-cancel --ok-label "Suivant" \
	--title "Configuration de gpg" \
	--inputbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\nEntrez votre nom pour signer les sauvegardes à votre nom :" 20 70)

mail=$(dialog --stdout --no-cancel  --ok-label "Suivant" \
	--title "Configuration de gpg" \
	--inputbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\nEntrez votre adresse email :" 20 70)
## faire un while pour vérifier que le mail est ok

mdp=$(dialog --stdout --no-cancel  --ok-label "Suivant" \
	--title "Configuration de gpg" \
	--passwordbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\nEntrez votre mot de passe :" 20 70)

mdpverif=$(dialog --stdout --no-cancel  --ok-label "Terminer" \
	--title "Configuration de gpg" \
	--passwordbox "Configuration de gpg, utilisé pour chiffrer les sauvegardes.\n\nValidez votre mot de passe :" 20 70)
## Faire un while pour vérifier que le mdp == la mdpverif

cat >config <<EOF
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
mkdir ./backups
touch backup.conf