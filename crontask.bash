#!/bin/bash
source kublike.bash -q --backup /home/$user/parametres.conf
source getSynopsis.bash -q #Lance le getSynopsis.bash et génère donc auotmatiquement l'envoi de mail
source uploadBackup.bash

# Il faut donc que chaque heure (13:00, 14:00, 15:00, ... ), le script:
# - synchronise les synopsis, 
# - effectue une backup
# - l’upload sur le service d’upload de backups, le tout automatiquement.


init
doTheBackup #Fait le back up avec les synopsis"
upload "$name" #Upload le tout 