#!/bin/bash
echo "Installation de dialog pour pouvoir procéder à l'installation de SwagCityRocker..."
## Vérifie qu'on est root
user=$(whoami)
if [ $user != "root" ]; then
	echo "Ce script doit effectuer des modifications sur votre système, il a donc besoin de tous les droits.\
			\nVeuillez exécuter ce script en tant de super utilisateur."
	exit 1
fi
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
nom=""
email=""
mdp=""

dialog --ok-label "Valider" \
	--title "Configuration de gpg" \
	--form "Configuration de gpg (cryptage des sauvegardes).\nLe mot de passe choisi sera celui appliqué à toutes les sauvegardes" \
	20 70 0 \
	"Nom :"				1 1	"$nom"		1 25 35 20 \
	"E-mail :"			2 1	"$email"	2 25 35 30 \
	"Mot de passe :"	3 1	"$mdp"		3 25 35 10 \
2>/dev/null

#gpg2 --gen-key