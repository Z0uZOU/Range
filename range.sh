#!/bin/bash

########################
## Script de Scoony
########################
## Installation: wget -q https://pastebin.com/raw/cz5Hm09d -O selfcheck2.sh && sed -i -e 's/\r//g' selfcheck2.sh && shc -f selfcheck2.sh -o selfcheck2.bin && chmod +x selfcheck2.bin && rm -f *.x.c && rm -f selfcheck2.sh
## Micro-config
version="Version: 1.0.1.26" #base du système de mise à jour
description="Range et renomme les téléchargements" #description pour le menu
script_pastebin="https://pastebin.com/raw/6Kp8MFJ7" #emplacement du script original
icone_pastebin="http://i.imgur.com/JKZ5lDh.png" #emplacement de l'icône du script
required_repos="" #ajout de repository
required_tools="" #dépendances du script
required_tools_pip="" #dépendances du script (PIP)
script_cron="*/15 * * * *" #ne définir que la planification
verification_process="" #si ces process sont détectés on ne notifie pas (ou ne lance pas en doublon)
########################

#### Déduction des noms des fichiers (pour un portage facile)
mon_script_fichier=`basename "$0"`
mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
mon_script_base_maj=`echo ${mon_script_base^^}`
mon_script_config=`echo "/root/.config/"$mon_script_base"/"$mon_script_base".conf"`
mon_script_ini=`echo "/root/.config/"$mon_script_base"/"$mon_script_base".ini"`
mon_script_langue=`echo "/root/.config/"$mon_script_base"/"$affichage_langue".lang"`
mon_script_log=`echo $mon_script_base".log"`
mon_script_desktop=`echo $mon_script_base".desktop"`
mon_script_updater=`echo $mon_script_base"-update.sh"`

