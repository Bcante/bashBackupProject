#!/bin/bash

echo "Ce programme va installer et configurer SwagCityRockers, notre solution de backup."
echo "Afin de procéder à l'installation, vous devez passer en super-utilisateur (tapez votre mot de passe root)."

whoami >> user.txt
echo $HOME >> home.txt
su -c './installAsRoot.bash'