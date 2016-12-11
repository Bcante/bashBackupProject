#!/bin/bash

dialog --yes-label "Continuer" --no-label "Annuler"\
	--title "Installation de SwagCityRockers"\
	--yesno "Ce programme va installer SwagCityRockers et vous permettre de le paramètrer." 40 100

if [ $? != 0 ]; then
	echo "Au revoir !"
	exit 1
fi

## Vérifie qu'on est root
user=$(whoami)
if [ $user != "root" ]; then
	dialog --ok-label "Tant pis, j'aurais essayé..."\
			--title "Installation de SwagCityRockers"\
			--msgbox "Ce script doit effectuer des modifications sur votre système, il a donc besoin de tous les droits.\
			\nVeuillez exécuter ce script en tant de super utilisateur." 40 100
	exit 1
fi

## Installation des composants requis
dialog --prgbox "apt-get -y install tar gnupg2 dialog curl wget sed sendmail mailutils sendmail-bin" 40 100

#source confMail.bash
## Préparation des mails
#confMail EN BORDEL

## Préparation pour GPG
#gpg2 --gen-key
