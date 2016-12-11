#!/bin/bash

fichierConf="kublike.conf"

# Chiffrement de la sauvegarde
## $1 nom du fichier a encrypter
## suivi de cat $fichierConf
## - $2 est le nom du destinataire
## - $3 est la passphrase du tar
function encrypt {
	gpg2 --symmetric --batch --yes --recipient $2 --passphrase $3 --encrypt $1
	rm -f $1
}

# Déchiffrement de la sauvegarde
## $1 nom du fichier a décrypter
## suivi de cat $fichierConf
## - $3 est la passphrase du tar
function decrypt {
	gpg2 --passphrase $3 --decrypt $1
}