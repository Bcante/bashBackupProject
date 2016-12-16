#!/bin/bash

pass=""
user=""

function getUserAndPass {
	local regexpass="PASSPHRASE\s(.*)"
	local regexuser="USER\s(.*)"

	while read -u 10 p
	do
		if [[ $p =~ $regexpass ]]; then
			pass="${BASH_REMATCH[1]}"
		fi

		if [[ $p =~ $regexuser ]]; then
			user="${BASH_REMATCH[1]}"
		fi
	done 10<parameters.conf
}

# Chiffrement de la sauvegarde
## $1 nom du fichier a chiffrer
function encrypt {
	getUserAndPass
	gpg2 --symmetric --batch --yes --recipient "$user" --passphrase "$pass" --encrypt "$1"
	rm -f "$1"
}

# Déchiffrement de la sauvegarde
## $1 nom du fichier a déchiffrer
function decrypt {
	getUserAndPass
	echo $pass "bite" $pass
	#echo $pass | gpg --batch --passphrase-fd 0 --output "$2" --decrypt "$1"
	gpg2 --batch --yes --passphrase $pass --output "$2" --decrypt "$1"
}

## TODO cat le fichier directement dans mes fonctions
## sed -n 2p "$1"