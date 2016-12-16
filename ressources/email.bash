#!/bin/bash
if [ -z "$1" ]; then
	echo "Usage script <fichier avec les email dedans>"
	exit 1
fi
if ! [ -f "$1" ]; then
	echo "Fichier introuvable"
	exit 2
fi;
if ! [ -r "$1" ]; then
	echo "Fichier non ouvrable"
fi

notvalid=""
while read e; do
	[[ $e =~ [A-Za-z_\-\.]*@(([A-Za-z_]*[\-\.][A-Za-z_]*)*) ]] && echo "${BASH_REMATCH[1]}" || notvalid="$notvalid$e"$'\n'
done < $1

if ! [ -z "$notvalid" ]; then
	echo "Not valid :"$'\n'"$notvalid"
fi