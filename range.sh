#!/bin/bash

########################
## Script de Scoony
########################
## Installation bin: wget -q https://raw.githubusercontent.com/Z0uZOU/Range/master/range.sh -O range.sh && sed -i -e 's/\r//g' range.sh && shc -f range.sh -o range.bin && chmod +x range.bin && rm -f *.x.c && rm -f range.sh
## Installation sh: wget -q https://raw.githubusercontent.com/Z0uZOU/Range/master/range.sh -O range.sh && sed -i -e 's/\r//g' range.sh && chmod +x range.sh
## Micro-config
version="Version: 2.0.0.34" #base du système de mise à jour
description="Range et renomme les téléchargements" #description pour le menu
description_eng="" #description pour le menu
script_github="https://raw.githubusercontent.com/Z0uZOU/Range/master/range.sh" #emplacement du script original
changelog_github="https://raw.githubusercontent.com/Z0uZOU/Range/master/changelog" #emplacement du changelog de ce script
langue_fr="https://raw.githubusercontent.com/Z0uZOU/Range/master/lang/french.lang"
langue_eng="https://raw.githubusercontent.com/Z0uZOU/Range/master/lang/english.lang"
icone_github="https://github.com/Z0uZOU/Range/raw/master/.cache-icons/range.png" #emplacement de l'icône du script
required_repos="" #ajout de repository
required_tools="" #dépendances du script
required_tools_pip="" #dépendances du script (PIP)
script_cron="*/15 * * * *" #ne définir que la planification
verification_process="" #si ces process sont détectés on ne notifie pas (ou ne lance pas en doublon)
lien_filebot="https://github.com/Z0uZOU/Range/tree/master/FileBot" #lien vers l'installer de filebot 
########################
 
#### Vérification de la langue du system
if [[ "$1" == "--langue=FR" ]] || [[ "$1" == "--langue=ENG" ]]; then
  if [[ "$1" == "--langue=FR" ]]; then
    affichage_langue="french"
  else
    affichage_langue="english"
  fi
else
  os_langue=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
  if [[ "$os_langue" == "fr" ]]; then
    affichage_langue="french"
  else
    affichage_langue="english"
  fi
fi
 
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
 
#### Chargement du fichier pour la langue (ou installation)
if [[ "$affichage_langue" == "french" ]]; then
  langue_distant_check=`wget -q -O- "$langue_fr" | sed 's/\r//g' | wc -c`
else
  langue_distant_check=`wget -q -O- "$langue_eng" | sed 's/\r//g' | wc -c`
fi
langue_local_check=`cat "$mon_script_langue" 2>/dev/null | wc -c`
if [[ "$langue_distant_check" != "$langue_local_check" ]]; then
  if [[ "$affichage_langue" == "french" ]]; then
    echo "mise à jour du fichier de language disponible"
    echo "téléchargement de la mise à jour et installation..."
    wget -q "$langue_fr" -O "$mon_script_langue" 
    sed -i -e 's/\r//g' $mon_script_langue
  else
    echo "language file update available"
    echo "downloading and applying update..."
    wget -q "$langue_eng" -O "$mon_script_langue"
    sed -i -e 's/\r//g' $mon_script_langue
  fi
fi
source $mon_script_langue
 
#### Vérification que le script possède les droits root
## NE PAS TOUCHER
if [[ "$EUID" != "0" ]]; then
  if [[ "$CRON_SCRIPT" == "oui" ]]; then
    exit 1
  else
    if [[ "$CHECK_MUI" != "" ]]; then
      source $mon_script_langue
      echo "$mui_root_check"
    else
      echo "Vous devrez impérativement utiliser le compte root"
    fi
    exit 1
  fi
fi

#### Fonction pour envoyer des push
push-message() {
  push_title=$1
  push_content=$2
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
        --form-string "token=$token_app" \
        --form-string "user=$destinataire" \
        --form-string "title=$push_title" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=0" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
}
 
#### Fonction: dehumanize
dehumanise() {
  for v in "$@"
  do  
    echo $v | awk \
      'BEGIN{IGNORECASE = 1}
       function printpower(n,b,p) {printf "%u\n", n*b^p; next}
       /[0-9]$/{print $1;next};
       /K(iB|o)?$/{printpower($1,  2, 10)};
       /M(iB|o)?$/{printpower($1,  2, 20)};
       /G(iB|o)?$/{printpower($1,  2, 30)};
       /T(iB|o)?$/{printpower($1,  2, 40)};
       /KB$/{    printpower($1, 10,  3)};
       /MB$/{    printpower($1, 10,  6)};
       /GB$/{    printpower($1, 10,  9)};
       /TB$/{    printpower($1, 10, 12)}'
  done
}
 
#### Vérification de process pour éviter les doublons (commandes externes)
for process_travail in $verification_process ; do
  process_important=`ps aux | grep $process_travail | sed '/grep/d'`
  if [[ "$process_important" != "" ]] ; then
    if [[ "$CRON_SCRIPT" != "oui" ]] ; then
      if [[ "$CHECK_MUI" != "" ]]; then
        source $mon_script_langue
        echo $process_important"$mui_prevent_dupe_task"
      else
        echo $process_important" est en cours de fonctionnement, arrêt du script"
      fi
      fin_script=`date`
      if [[ "$CHECK_MUI" != "" ]]; then
        source $mon_script_langue
        echo -e "$mui_end_of_script"
      else
        if [[ "$CHECK_MUI" != "" ]]; then
          source $mon_script_langue
          echo -e "$mui_end_of_script"
        else
          echo -e "\e[43m -- FIN DE SCRIPT: $fin_script -- \e[0m "
        fi
      fi
    fi
    exit 1
  fi
done

#### Tests des arguments
for parametre in $@; do
  if [[ "$parametre" == "--version" ]]; then
    echo "$version"
    exit 1
  fi
  if [[ "$parametre" == "--debug" ]]; then
    debug="yes"
  fi
  if [[ "$parametre" == "--edit-config" ]]; then
    nano $mon_script_config
    exit 1
  fi
  if [[ "$parametre" == "--efface-lock" ]]; then
    mon_lock=`echo "/root/.config/"$mon_script_base"/lock-"$mon_script_base`
    rm -f "$mon_lock"
    echo "Fichier lock effacé"
    exit 1
  fi
  if [[ "$parametre" == "--statut-lock" ]]; then
    statut_lock=`cat $mon_script_config | grep "maj_force=\"oui\""`
    if [[ "$statut_lock" == "" ]]; then
      echo "Système de lock activé"
    else
      echo "Système de lock désactivé"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--active-lock" ]]; then
    sed -i 's/maj_force="oui"/maj_force="non"/g' $mon_script_config
    echo "Système de lock activé"
    exit 1
  fi
  if [[ "$parametre" == "--desactive-lock" ]]; then
    sed -i 's/maj_force="non"/maj_force="oui"/g' $mon_script_config
    echo "Système de lock désactivé"
    exit 1
  fi
  if [[ "$parametre" == "--extra-log" ]]; then
    date_log=`date +%Y%m%d`
    heure_log=`date +%H%M`
    path_log=`echo "/root/.config/"$mon_script_base"/log/"$date_log`
    mkdir -p $path_log 2>/dev/null
    fichier_log_perso=`echo $path_log"/"$heure_log".log"`
    mon_log_perso="| tee -a $fichier_log_perso"
  fi
  if [[ "$parametre" == "--purge-process" ]]; then
    ps aux | grep $mon_script_base | awk '{print $2}' | xargs kill -9
    echo "Les processus de ce script ont été tués"
  fi
  if [[ "$parametre" == "--purge-log" ]]; then
    path_global_log=`echo "/root/.config/"$mon_script_base"/log"`
    cd $path_global_log
    mon_chemin=`echo $PWD`
    if [[ "$mon_chemin" == "$path_global_log" ]]; then
      printf "Êtes-vous sûr de vouloir effacer l'intégralité des logs de --extra-log? (oui/non) : "
      read question_effacement
      if [[ "$question_effacement" == "oui" ]]; then
        rm -rf *
        echo "Les logs ont été effacés"
      fi
    else
      echo "Une erreur est survenue, veuillez contacter le développeur"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--changelog" ]]; then
    wget -q -O- $changelog_github
    echo ""
    exit 1
  fi
  if [[ "$parametre" == --message=* ]]; then
    source $mon_script_config
    message=`echo "$parametre" | sed 's/--message=//g'`
    curl -s \
      --form-string "token=ansxn5akcp72c47i9g1safyjdxqd1w" \
      --form-string "user=use32hsG26Ti2jkmSpX7YteA12DkQr" \
      --form-string "title=$mon_script_base_maj MESSAGE" \
      --form-string "message=$message" \
      --form-string "html=1" \
      --form-string "priority=0" \
      https://api.pushover.net/1/messages.json > /dev/null
    exit 1
  fi
  if [[ "$parametre" == "--help" ]]; then
    if [[ "$CHECK_MUI" != "" ]]; then
      i=""
      for i in _ {a..z} {A..Z}; do eval "echo \${!$i@}" ; done | xargs printf "%s\n" | grep mui_menu_help > variables
      help_lignes=`wc -l variables | awk '{print $1}'`
      rm -f variables
      j=""
      mui_menu_help="mui_menu_help_"
      path_log=`echo "/root/.config/"$mon_script_base"/log/"$date_log`
      for j in $(seq 1 $help_lignes); do
        source $mon_script_langue
        mui_menu_help_display=`echo -e "$mui_menu_help$j"`
        echo -e "${!mui_menu_help_display}"
      done
      exit 1
    fi
    if [[ "$CHECK_MUI" == "" ]]; then
      path_log=`echo "/root/.config/"$mon_script_base"/log/"$date_log`
      echo -e "\e[1m$mon_script_base_maj\e[0m ($version)"
      echo "Objectif du programme: $description"
      echo "Auteur: Sc00nY <scoonydeus@gmail.com>"
      echo ""
      echo "Utilisation: \"$mon_script_fichier [--option]\""
      echo ""
      echo -e "\e[4mOptions:\e[0m"
      echo "  --version               Affiche la version de ce programme"
      echo "  --edit-config           Édite la configuration de ce programme"
      echo "  --extra-log             Génère un log à chaque exécution dans "$path_log
      echo "  --debug                 Lance ce programme en mode debug"
      echo "  --efface-lock           Supprime le fichier lock qui empêche l'exécution"
      echo "  --statut-lock           Affiche le statut de la vérification de process doublon"
      echo "  --active-lock           Active le système de vérification de process doublon"
      echo "  --desactive-lock        Désactive le système de vérification de process doublon"
      echo "  --maj-uniquement        N'exécute que la mise à jour"
      echo "  --changelog             Affiche le changelog de ce programme"
      echo "  --help                  Affiche ce menu"
      echo ""
      echo "Les options \"--debug\" et \"--extra-log\" sont cumulables"
      echo ""
      echo -e "\e[4mUtilisation avancée:\e[0m"
      echo "  --message=\"...\"         Envoie un message push au développeur (urgence uniquement)"
      echo "  --purge-log             Purge définitivement les logs générés par --extra-log"
      echo "  --purge-process         Tue tout les processus générés par ce programme"
      echo ""
      echo -e "\e[3m ATTENTION: CE PROGRAMME DOIT ÊTRE EXÉCUTÉ AVEC LES PRIVILÈGES ROOT \e[0m"
      echo "Des commandes comme les installations de dépendances ou les recherches nécessitent de tels privilèges."
      echo ""
      exit 1
    fi
  fi
done
  
#### je dois charger le fichier conf ici ou trouver une solution (script_url et maj_force)
dossier_config=`echo "/root/.config/"$mon_script_base`
if [[ -d "$dossier_config" ]]; then
  useless="1"
else
  mkdir -p $dossier_config
fi

if [[ -f "$mon_script_config" ]] ; then
  source $mon_script_config
else
    if [[ "$script_url" != "" ]] ; then
      script_github=$script_url
    fi
    if [[ "$maj_force" == "" ]] ; then
      maj_force="non"
    fi
fi

#### Vérification qu'au reboot les lock soient bien supprimés
if [[ -f "/etc/rc.local" ]]; then
  test_rc_local=`cat /etc/rc.local | grep -e 'find /root/.config -name "lock-\*" | xargs rm -f'`
  if [[ "$test_rc_local" == "" ]]; then
    sed -i -e '$i \find /root/.config -name "lock-*" | xargs rm -f\n' /etc/rc.local >/dev/null
  fi
else
  test_crontab=`crontab -l | grep "clean-lock"`
  if [[ "$test_crontab" == "" ]]; then
    crontab -l > mon_cron.txt
    sed -i '5i@reboot\t\t\tsleep 10 && /opt/scripts/clean-lock.sh' mon_cron.txt
    crontab mon_cron.txt
    rm -f mon_cron.txt
  fi
fi
 
#### Vérification qu'une autre instance de ce script ne s'exécute pas
computer_name=`hostname`
pid_script=`echo "/root/.config/"$mon_script_base"/lock-"$mon_script_base`
if [[ "$maj_force" == "non" ]] ; then
  if [[ -f "$pid_script" ]] ; then
    if [[ "$CHECK_MUI" != "" ]]; then
      source $mon_script_langue
      echo "$mui_pid_check"
      message_alerte=`echo -e "$mui_pid_push"`
    else
      echo "Il y a au moins un autre process du script en cours"
      message_alerte=`echo -e "Un process bloque mon script sur $computer_name"`
    fi
    ## petite notif pour scoony
    curl -s \
      --form-string "token=$token_app" \
      --form-string "user=$destinataire_1" \
      --form-string "title=$mon_script_base_maj HS" \
      --form-string "message=$message_alerte" \
      --form-string "html=1" \
      --form-string "priority=1" \
      https://api.pushover.net/1/messages.json > /dev/null
    exit 1
  fi
fi
touch $pid_script
 
#### Chemin du script
## necessaire pour le mettre dans le cron
cd /opt/scripts

#### Indispensable aux messages de chargement
mon_printf="\r                                                                                                               "

#### Nettoyage obligatoire et push pour annoncer la maj
if [[ -f "$mon_script_updater" ]] ; then
  rm "$mon_script_updater"
  source $mon_script_config 2>/dev/null
  version_maj=`echo $version | awk '{print $2}'`
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    message_maj=`echo -e "$mui_pushover_updated_msg"`
    message_titre=`echo -e "$mui_pushover_updated_title"`
  else
    message_maj=`echo -e "Le progamme $mon_script_base est désormais en version $version_maj"`
    message_titre=`echo -e "Mise à jour"`
  fi  
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
      --form-string "token=$token_app" \
      --form-string "user=$destinataire" \
      --form-string "title=$message_titre" \
      --form-string "message=$message_maj" \
      --form-string "html=1" \
      --form-string "priority=-1" \
      https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
fi

#### Vérification de version pour éventuelle mise à jour
version_distante=`wget -O- -q "$script_github" | grep "Version:" | awk '{ print $2 }' | sed -n 1p | awk '{print $1}' | sed -e 's/\r//g' | sed 's/"//g'`
version_locale=`echo $version | awk '{print $2}'`
 
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
testvercomp () {
    vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]
    then
        echo "FAIL: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
    else
        echo "Pass: '$1 $op $2'"
    fi
}
compare=`testvercomp $version_locale $version_distante '<' | grep Pass`
if [[ "$compare" != "" ]] ; then
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'echo -e "$mui_update_available"' $mon_log_perso
    eval 'echo -e "$mui_update_download"' $mon_log_perso
  else
    eval 'echo "une mise à jour est disponible ($version_distante) - version actuelle: $version_locale"' $mon_log_perso
    eval 'echo "téléchargement de la mise à jour et installation..."' $mon_log_perso
  fi
  touch $mon_script_updater
  chmod +x $mon_script_updater
  echo "#!/bin/bash" >> $mon_script_updater
  mon_script_fichier_temp=`echo $mon_script_fichier"-temp"`
  echo "wget -q $script_github -O $mon_script_fichier_temp" >> $mon_script_updater
  echo "sed -i -e 's/\r//g' $mon_script_fichier_temp" >> $mon_script_updater
  if [[ "$mon_script_fichier" =~ \.sh$ ]]; then
    echo "mv $mon_script_fichier_temp $mon_script_fichier" >> $mon_script_updater
    echo "chmod +x $mon_script_fichier" >> $mon_script_updater
    echo "chmod 777 $mon_script_fichier" >> $mon_script_updater
    if [[ "$CHECK_MUI" != "" ]]; then
      source $mon_script_langue
      echo "$mui_update_done" >> $mon_script_updater
    else
      echo "echo mise à jour mise en place" >> $mon_script_updater
    fi
    echo "bash $mon_script_fichier $1 $2" >> $mon_script_updater
  else
    echo "shc -f $mon_script_fichier_temp -o $mon_script_fichier" >> $mon_script_updater
    echo "rm -f $mon_script_fichier_temp" >> $mon_script_updater
    compilateur=`echo $mon_script_fichier".x.c"`
    echo "rm -f *.x.c" >> $mon_script_updater
    echo "chmod +x $mon_script_fichier" >> $mon_script_updater
    echo "chmod 777 $mon_script_fichier" >> $mon_script_updater
    if [[ "$CHECK_MUI" != "" ]]; then
      source $mon_script_langue
      echo "$mui_update_done" >> $mon_script_updater
    else
      echo "echo mise à jour mise en place" >> $mon_script_updater
    fi
    echo "./$mon_script_fichier $1 $2" >> $mon_script_updater
  fi
  echo "exit 1" >> $mon_script_updater
  rm "$pid_script"
  bash $mon_script_updater
  exit 1
else
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    my_title_count=`echo -n "$mui_title" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
    line_lengh="78"
    before_after_count=$(bc -l <<<"scale=1; ( $line_lengh - $my_title_count ) / 2")
    if [[ $before_after_count =~ ".5" ]]; then
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
      after=`eval printf "%0.s-" {1..$before_after_count}`
    else
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      after=`eval printf "%0.s-" {1..$before_after_count}`
    fi
    eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_title" "$after"' $mon_log_perso
  else
    eval 'echo -e "\e[43m-- $mon_script_base_maj - VERSION: $version_locale --\e[0m"' $mon_log_perso
  fi
fi

#### Nécessaire pour l'argument --maj-uniquement
if [[ "$@" == "--maj-uniquement" ]]; then
  rm "$pid_script"
  exit 1
fi

#### Vérification de la conformité du cron
crontab -l > $dossier_config/mon_cron.txt
cron_path=`cat $dossier_config/mon_cron.txt | grep "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"`
if [[ "$cron_path" == "" ]]; then
  sed -i '1iPATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
if [[ "$affichage_langue" == "french" ]]; then
  cron_lang=`cat $dossier_config/mon_cron.txt | grep "LANG=fr_FR.UTF-8"`
else
  cron_lang=`cat $dossier_config/mon_cron.txt | grep "LANG=en_US.UTF-8"`
fi
if [[ "$cron_lang" == "" ]]; then
  if [[ "$affichage_langue" == "french" ]]; then
    sed -i '1iLANG=fr_FR.UTF-8' $dossier_config/mon_cron.txt
    cron_a_appliquer="oui"
  else
    sed -i '1iLANG=en_US.UTF-8' $dossier_config/mon_cron.txt
    cron_a_appliquer="oui"
  fi
fi
cron_variable=`cat $dossier_config/mon_cron.txt | grep "CRON_SCRIPT=\"oui\""`
if [[ "$cron_variable" == "" ]]; then
  sed -i '1iCRON_SCRIPT="oui"' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
if [[ "$cron_a_appliquer" == "oui" ]]; then
  crontab $dossier_config/mon_cron.txt
  rm -f $dossier_config/mon_cron.txt
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'echo -e "$mui_cron_path_updated"' $mon_log_perso
  else
    eval 'echo "-- Cron mis en conformité"' $mon_log_perso
  fi
else
  rm -f $dossier_config/mon_cron.txt
fi

#### Mise en place éventuelle d'un cron
if [[ "$script_cron" != "" ]]; then
  mon_cron=`crontab -l`
  verif_cron=`echo "$mon_cron" | grep "$mon_script_fichier"`
  if [[ "$verif_cron" == "" ]]; then
    if [[ "$CHECK_MUI" != "" ]]; then
      source $mon_script_langue
      eval 'echo -e "$mui_no_cron_entry"' $mon_log_perso
      eval 'echo -e "$mui_no_cron_creating"' $mon_log_perso
    else
      eval 'echo -e "\e[41mAUCUNE ENTRÉE DANS LE CRON\e[0m"' $mon_log_perso
      eval 'echo "-- Création..."' $mon_log_perso
    fi
    ajout_cron=`echo -e "$script_cron\t\t/opt/scripts/$mon_script_fichier > /var/log/$mon_script_log 2>&1"`
    if [[ "$CHECK_MUI" != "" ]]; then
      source $mon_script_langue
      eval 'echo -e "$mui_no_cron_adding"' $mon_log_perso
    else
      eval 'echo "-- Mise en place dans le cron..."' $mon_log_perso
    fi
    crontab -l > $dossier_config/mon_cron.txt
    echo -e "$ajout_cron" >> $dossier_config/mon_cron.txt
    crontab $dossier_config/mon_cron.txt
    rm -f $dossier_config/mon_cron.txt
    if [[ "$CHECK_MUI" != "" ]]; then
      source $mon_script_langue
      eval 'echo -e "$mui_no_cron_updated"' $mon_log_perso
    else
      eval 'echo "-- Cron mis à jour"' $mon_log_perso
    fi
  else
    if [[ "${verif_cron:0:1}" == "#" ]]; then
      if [[ "$CHECK_MUI" != "" ]]; then
        source $mon_script_langue
        my_title_count=`echo -n "$mui_script_in_cron_disable" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
        line_lengh="78"
        before_after_count="0"
        before_after_count=$(bc -l <<<"scale=1; ( $line_lengh - $my_title_count ) / 2")
        if [[ $before_after_count =~ ".5" ]]; then
          before_after_count=$((($line_lengh-$my_title_count)/2))
          before=`eval printf "%0.s-" {1..$before_after_count}`
          before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
          after=`eval printf "%0.s-" {1..$before_after_count}`
        else
          before_after_count=$((($line_lengh-$my_title_count)/2))
          before=`eval printf "%0.s-" {1..$before_after_count}`
          after=`eval printf "%0.s-" {1..$before_after_count}`
        fi
        printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_script_in_cron_disable" "$after"
      else
        eval 'echo -e "\e[101mLE SCRIPT EST PRÉSENT DANS LE CRON MAIS DÉSACTIVÉ\e[0m"' $mon_log_perso
      fi
    else
      if [[ "$CHECK_MUI" != "" ]]; then
        source $mon_script_langue
        my_title_count=`echo -n "$mui_script_in_cron" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
        line_lengh="78"
        before_after_count=$(bc -l <<<"scale=1; ( $line_lengh - $my_title_count ) / 2")
        if [[ $before_after_count =~ ".5" ]]; then
          before_after_count=$((($line_lengh-$my_title_count)/2))
          before=`eval printf "%0.s-" {1..$before_after_count}`
          before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
          after=`eval printf "%0.s-" {1..$before_after_count}`
        else
          before_after_count=$((($line_lengh-$my_title_count)/2))
          before=`eval printf "%0.s-" {1..$before_after_count}`
          after=`eval printf "%0.s-" {1..$before_after_count}`
        fi
        eval 'printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_script_in_cron" "$after"' $mon_log_perso
      else
        eval 'echo -e "\e[101mLE SCRIPT EST PRÉSENT DANS LE CRON\e[0m"' $mon_log_perso
      fi
    fi
  fi
fi
 
#### Vérification/création du fichier conf
if [[ -f $mon_script_config ]] ; then
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    my_title_count=`echo -n "$mui_conf_ok" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
    line_lengh="78"
    before_after_count=$(bc -l <<<"scale=1; ( $line_lengh - $my_title_count ) / 2")
    if [[ $before_after_count =~ ".5" ]]; then
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
      after=`eval printf "%0.s-" {1..$before_after_count}`
    else
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      after=`eval printf "%0.s-" {1..$before_after_count}`
    fi
    eval 'printf "\e[42m%s%s%s\e[0m\n" "$before" "$mui_conf_ok" "$after"' $mon_log_perso
  else
    eval 'echo -e "\e[42mLE FICHIER CONF EST PRESENT\e[0m"' $mon_log_perso
  fi
else
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    my_title_count=`echo -n "$mui_no_conf_missing" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
    line_lengh="78"
    before_after_count=$(bc -l <<<"scale=1; ( $line_lengh - $my_title_count ) / 2")
    if [[ $before_after_count =~ ".5" ]]; then
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
      after=`eval printf "%0.s-" {1..$before_after_count}`
    else
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      after=`eval printf "%0.s-" {1..$before_after_count}`
    fi
    eval 'printf "\e[42m%s%s%s\e[0m\n" "$before" "$mui_no_conf_missing" "$after"' $mon_log_perso
    my_title_count=`echo -n "$mui_no_conf_creating" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
    line_lengh="78"
    before_after_count=$(bc -l <<<"scale=1; ( $line_lengh - $my_title_count ) / 2")
    if [[ $before_after_count =~ ".5" ]]; then
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
      after=`eval printf "%0.s-" {1..$before_after_count}`
    else
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      after=`eval printf "%0.s-" {1..$before_after_count}`
    fi
    eval 'printf "\e[42m%s%s%s\e[0m\n" "$before" "$mui_no_conf_creating" "$after"' $mon_log_perso
  else
    eval 'echo -e "\e[41mLE FICHIER CONF EST ABSENT\e[0m"' $mon_log_perso
    eval 'echo "-- Création du fichier conf..."' $mon_log_perso
  fi
  touch "$mon_script_config"
  chmod 777 "$mon_script_config"
  if [[ "$affichage_langue" == "french" ]]; then
    cat <<EOT >> "$mon_script_config"
####################################
## Configuration
####################################
 
#### Mise à jour forcée
## à n'utiliser qu'en cas de soucis avec la vérification de process (oui/non)
maj_force="non"
 
#### Chemin complet vers le script source (pour les maj)
script_url=""
 
#### Affichage de la section dépendances
## mettre oui/non
affiche_dependances="non"
 
##### Paramètres
## Sources
download_auto_films_hd=""
download_auto_films_sd=""
download_auto_films_animation_hd=""
download_auto_films_animation_sd=""
download_auto_series_hdtv=""
download_auto_series_dvdrip=""
download_auto_animation_hdtv=""
download_auto_animation_dvdrip=""
download_auto_series_vostfr=""
## Cibles
cible_auto_films_hd=""
cible_auto_films_sd=""
cible_auto_films_animation_hd=""
cible_auto_films_animation_sd=""
cible_auto_series_hdtv=""
cible_auto_series_dvdrip=""
cible_auto_animation_hdtv=""
cible_auto_animation_dvdrip=""
cible_auto_series_vostfr=""
 
quota_minimum="100Go"
 
#### Token de Plex
token=""
 
#### Paramètre du push
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
destinataire_1=""
destinataire_2=""
titre_push=""
 
####################################
## Fin de configuration
####################################
EOT
 else
    cat <<EOT >> "$mon_script_config"
####################################
## Settings
####################################
 
#### Overriding updates
## only use if the process dupe checker is stuck (oui/non)
maj_force="non"
 
#### Full path to script's source (for updates)
script_url=""
 
#### Display the dependencies checking
## use yes/no
display_dependencies="no"
 
##### Paramètres
## From
download_auto_films_hd=""
download_auto_films_sd=""
download_auto_films_animation_hd=""
download_auto_films_animation_sd=""
download_auto_series_hdtv=""
download_auto_series_dvdrip=""
download_auto_animation_hdtv=""
download_auto_animation_dvdrip=""
download_auto_series_vostfr=""
## To
cible_auto_films_hd=""
cible_auto_films_sd=""
cible_auto_films_animation_hd=""
cible_auto_films_animation_sd=""
cible_auto_series_hdtv=""
cible_auto_series_dvdrip=""
cible_auto_animation_hdtv=""
cible_auto_animation_dvdrip=""
cible_auto_series_vostfr=""
 
minimum_quota="100GiB"
 
#### Plex's Token
token=""
 
#### Paramètre du push
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
destinataire_1=""
destinataire_2=""
titre_push=""
 
####################################
## Fin de configuration
####################################
EOT
  fi
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'echo -e "$mui_no_conf_created"' $mon_log_perso
    eval 'echo -e "$mui_no_conf_edit"' $mon_log_perso
    eval 'echo -e "$mui_no_conf_help"' $mon_log_perso
  else
    eval 'echo "-- Fichier conf créé"' $mon_log_perso
    eval 'echo "Vous dever éditer le fichier \"$mon_script_config\" avant de poursuivre"' $mon_log_perso
    eval 'echo "Vous pouvez utiliser: ./"$mon_script_fichier" --edit-config"' $mon_log_perso
  fi
  rm $pid_script
  exit 1
fi
#### Vérification/création du fichier ini
if [[ -f "$mon_script_ini" ]] ; then
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    my_title_count=`echo -n "$mui_ini_ok" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
    line_lengh="78"
    before_after_count=$(bc -l <<<"scale=1; ( $line_lengh - $my_title_count ) / 2")
    if [[ $before_after_count =~ ".5" ]]; then
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
      after=`eval printf "%0.s-" {1..$before_after_count}`
    else
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      after=`eval printf "%0.s-" {1..$before_after_count}`
    fi
    eval 'printf "\e[42m%s%s%s\e[0m\n" "$before" "$mui_ini_ok" "$after"' $mon_log_perso
  else
    eval 'echo -e "\e[42mLE FICHIER INI EST PRESENT\e[0m"' $mon_log_perso
  fi
else
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'echo -e "$mui_ini_missing"' $mon_log_perso
    eval 'echo -e "$mui_ini_creating"' $mon_log_perso
  else
    eval 'echo -e "\e[41mLE FICHIER INI EST ABSENT\e[0m"' $mon_log_perso
    eval 'echo "-- Création du fichier ini..."' $mon_log_perso
  fi
  touch $mon_script_ini
  chmod 777 $mon_script_ini
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'echo -e "$mui_ini_created"' $mon_log_perso
  else
    eval 'echo "-- Fichier ini créé"' $mon_log_perso
  fi
fi

echo "------------------------------------------------------------------------------"

if [[ "$display_dependencies" == "yes" ]] || [[ "$affiche_dependances" == "oui" ]]; then
  #### VERIFICATION DES DEPENDANCES
  ##########################
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_dependencies"' $mon_log_perso
  else
    eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mVÉRIFICATION DES DÉPENDANCES  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
  fi

  #### Vérification et installation des repositories (apt)
  for repo in $required_repos ; do
    ppa_court=`echo $repo | sed 's/.*ppa://' | sed 's/\/ppa//'`
    check_repo=`grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep "$ppa_court"`
    if [[ "$check_repo" == "" ]]; then
      add-apt-repository $repo -y
      update_a_faire="1"
    else
      if [[ "$CHECK_MUI" != "" ]]; then
        source $mon_script_langue
        eval 'echo -e "$mui_required_repository"' $mon_log_perso
      else
        eval 'echo -e "[\e[42m\u2713 \e[0m] Le dépôt apt: "$repo" est installé"' $mon_log_perso
      fi
    fi
  done
  if [[ "$update_a_faire" == "1" ]]; then
    apt update
  fi

  #### Vérification et installation des outils requis si besoin (apt)
  for tools in $required_tools ; do
    check_tool=`dpkg --get-selections | grep -w "$tools"`
    if [[ "$check_tool" == "" ]]; then
      apt-get install $tools -y
    else
      if [[ "$CHECK_MUI" != "" ]]; then
        source $mon_script_langue
        eval 'echo -e "$mui_required_apt"' $mon_log_perso
      else
        eval 'echo -e "[\e[42m\u2713 \e[0m] La dépendance: "$tools" est installée"' $mon_log_perso
      fi
    fi
  done

  #### Vérification et installation des outils requis si besoin (pip)
  for tools_pip in $required_tools_pip ; do
    check_tool=`pip freeze | grep "$tools_pip"`
      if [[ "$check_tool" == "" ]]; then
        pip install $tools_pip
      else
        if [[ "$CHECK_MUI" != "" ]]; then
          source $mon_script_langue
          eval 'echo -e "$mui_required_pip"' $mon_log_perso
        else
          eval 'echo -e "[\e[42m\u2713 \e[0m] La dépendance: "$tools_pip" est installée"' $mon_log_perso
        fi
      fi
  done
fi

#### Ajout de ce script dans le menu
if [[ -f "/etc/xdg/menus/applications-merged/scripts-scoony.menu" ]] ; then
  useless=1
else
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'echo -e "$mui_creating_menu_entry"' $mon_log_perso
  else
    echo "... création du menu"
  fi
  mkdir -p /etc/xdg/menus/applications-merged
  touch "/etc/xdg/menus/applications-merged/scripts-scoony.menu"
  cat <<EOT >> /etc/xdg/menus/applications-merged/scripts-scoony.menu
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
<Name>Applications</Name>
 
<Menu> <!-- scripts-scoony -->
<Name>scripts-scoony</Name>
<Directory>scripts-scoony.directory</Directory>
<Include>
<Category>X-scripts-scoony</Category>
</Include>
</Menu> <!-- End scripts-scoony -->
 
</Menu> <!-- End Applications -->
EOT
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    echo -e "$mui_created_menu_entry"
  else
    echo "... menu créé"
  fi
fi
 
if [[ -f "/usr/share/desktop-directories/scripts-scoony.directory" ]] ; then
  useless=1
else
## je met l'icone en place
  wget -q http://i.imgur.com/XRCxvJK.png -O /usr/share/icons/scripts.png
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    echo "$mui_creating_menu_folder"
  else
    echo "... création du dossier du menu"
  fi
  if [[ ! -d "/usr/share/desktop-directories" ]] ; then
    mkdir -p /usr/share/desktop-directories
  fi
  touch "/usr/share/desktop-directories/scripts-scoony.directory"
  cat <<EOT >> /usr/share/desktop-directories/scripts-scoony.directory
[Desktop Entry]
Type=Directory
Name=Scripts Scoony
Icon=/usr/share/icons/scripts.png
EOT
fi
 
if [[ -f "/usr/local/share/applications/$mon_script_desktop" ]] ; then
  useless=1
else
  wget -q $icone_github -O /usr/share/icons/$mon_script_base.png
  if [[ -d "/usr/local/share/applications" ]]; then
    useless="1"
  else
    mkdir -p /usr/local/share/applications
  fi
  touch "/usr/local/share/applications/$mon_script_base.desktop"
  cat <<EOT >> /usr/local/share/applications/$mon_script_base.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Type=Application
Terminal=true
Name=Script $mon_script_base
Icon=/usr/share/icons/$mon_script_base.png
Exec=/opt/scripts/$mon_script_fichier --menu
Comment[fr_FR]=$description
Comment=$description
Categories=X-scripts-scoony;
EOT
fi
 
####################
## On commence enfin
####################

#### Initialisation
maj_necessaire="0"

if [[ "$display_dependencies" == "yes" ]] || [[ "$affiche_dependances" == "oui" ]]; then
#### Vérification de FileBot
  filebot_present=`filebot -version 2>/dev/null`
  if [[ "$filebot_present" =~ "FileBot" ]] || [[ "$filebot_present" =~ "Unrecognized option" ]]; then
    filebot_local=`filebot -version | awk '{print $2}' 2>/dev/null`
    if [[ "$filebot_present" =~ "Unrecognized option" ]]; then
      filebot_local="Inconnue"
    fi
    echo -e "[\e[42m\u2713 \e[0m] La dépendance: filebot est installée ("$filebot_local")"
  else
    wget -O- -q $lien_filebot > $dossier_config/filebot.txt &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
    i=$(( (i+1) %4 ))
    printf "\rVérification de la dernière version de FileBot... ${spin:$i:1}"
    sleep .1
    done
    printf "$mon_printf" && printf "\r"
    filebot_distant=`cat $dossier_config/filebot.txt | grep "filebot_" | sed -n '1p' | sed 's/.*filebot_//' | sed 's/_amd64.deb<\/a><\/span>.*//'`
    useless="1"
    filebot_lien_download=`cat $dossier_config/filebot.txt | grep "filebot_$filebot_distant" | sed -n '1p' | sed 's/.*href=\"\///' | sed 's/\">.*//' | sed 's/\/blob\//\/raw\//'`
    wget -q -O filebot.deb "https://github.com/$filebot_lien_download" &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\rTéléchargement de la dernière version de FileBot... ${spin:$i:1}"
      sleep .1
    done
    printf "$mon_printf" && printf "\r"
    dpkg -i filebot.deb >/dev/null 2>&1 &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\rInstallation de la dernière version de FileBot... ${spin:$i:1}"
      sleep .1
    done
    printf "$mon_printf" && printf "\r"
    rm -f filebot.deb
    echo -e "[\e[42m\u2713 \e[0m] FileBot est installé (version "$filebot_distant")"
  fi
  rm -f $dossier_config/filebot.txt
  
## Vérification de Java
  java_local=`java -version 2>&1 >/dev/null | grep 'openjdk version' | awk '{print $3}' | sed -e 's/"//g'`
  if [[ "$java_local" == "" ]]; then
    eval 'echo -e "[\e[41m\u2717 \e[0m] Java est nécessaire... installation lancée"' $mon_log_perso
    java_repo=`add-apt-repository ppa:openjdk-r/ppa`
    java_update=`apt update`
    java_install=`apt install openjdk-11-jre -y`
  else
    eval 'echo -e "[\e[42m\u2713 \e[0m] La dépendance: Java est installé ("$java_local")"' $mon_log_perso
  fi
fi
 
#### Détection des variables (download_auto*)
for i in _ {a..z} {A..Z}; do eval "echo \${!$i@}" ; done | xargs printf "%s\n" | grep download_auto > variables
mes_dossiers_auto=`cat variables`
rm variables

#### Vérification de la configuration
if [[ "$CHECK_MUI" != "" ]]; then
  source $mon_script_langue
  eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_configuration"' $mon_log_perso
else
  eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mVERIFICATION DE LA CONFIGURATION  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
fi
for verif_config in $mes_dossiers_auto ; do
  source=${!verif_config}
  cible_var=`echo $verif_config | sed -e 's/download/cible/g'`
  cible=${!cible_var}
  if [[ "$source" != "" ]]; then
    if [[ "$cible" != "" ]]; then
      eval 'echo -e "[\e[42m\u2713 \e[0m] $source \u2192 $cible"' $mon_log_perso
    else
      eval 'echo -e "[\e[41m\u2717 \e[0m] Soucis de configuration"' $mon_log_perso
    fi
  else
    if [[ "$cible" == "" ]]; then
      useless="1"
    else
      eval 'echo -e "[\e[41m\u2717 \e[0m] Soucis de configuration"' $mon_log_perso
    fi
  fi
done

#### Chmod des dossiers source
if [[ "$CHECK_MUI" != "" ]]; then
  source $mon_script_langue
  eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_chmod"' $mon_log_perso
else
  eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mCHMOD ET CONTROLE DES DOSSIERS  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
fi
for dossier in $mes_dossiers_auto ; do
  dossier_actuel=${!dossier}
  if [[ "$dossier_actuel" != "" ]]; then
    if [[ -d "$dossier_actuel" ]]; then
      chmod 777 -R "$dossier_actuel"
      eval 'echo -e "[\e[42m\u2713 \e[0m] Source: "$dossier_actuel' $mon_log_perso
    else
      eval 'echo -e "[\e[41m\u2717 \e[0m] Source: "$dossier_actuel' $mon_log_perso
    fi
  fi
done

#### Chmod des dossiers cible
for dossier in $mes_dossiers_auto ; do
  dossier_var=`echo $dossier | sed -e 's/download/cible/g'`
  dossier_actuel=${!dossier_var}
  if [[ "$dossier_actuel" != "" ]]; then
    if [[ -d "$dossier_actuel" ]]; then
      chmod 777 -R "$dossier_actuel"
      cible_hdd=`df -Hl "$dossier_actuel" | grep '/dev/' | awk '{print $4}' | sed 's/M/ Mo/' | sed 's/T/ To/' | sed 's/G/ Go/'`
      eval 'echo -e "[\e[42m\u2713 \e[0m] Cible: "$dossier_actuel "("$cible_hdd")"' $mon_log_perso
    else
      mkdir -p "$dossier_actuel"
      chmod 777 -R "$dossier_actuel"
      cible_hdd=`df -Hl "$dossier_actuel" | grep '/dev/' | awk '{print $4}' | sed 's/M/ Mo/' | sed 's/T/ To/' | sed 's/G/ Go/'`
      eval 'echo -e "[\e[41m\u2717 \e[0m] Cible: "$dossier_actuel" ("$cible_hdd") (Création du dossier)"' $mon_log_perso
    fi
  fi
done

## Envoie à FileBot
if [[ "$CHECK_MUI" != "" ]]; then
  source $mon_script_langue
  eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_filebot"' $mon_log_perso
else
  eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mVERIFICATION DE FILEBOT  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
fi
if [[ "$quota_minimum" != "" ]]; then
  eval 'echo " ..  Quota minimum configuré: "$quota_minimum' $mon_log_perso
else
  eval 'echo " ..  Pas de quota minimum configuré"' $mon_log_perso
  quota_minimum="0"
fi
mes_dossiers_a_nettoyer=()
for dossier in $mes_dossiers_auto ; do
  source_actuelle=${!dossier}
  cible_var=`echo $dossier | sed -e 's/download/cible/g'`
  cible_actuelle=${!cible_var}
  if [[ "$source_actuelle" != "" ]] && [[ "$cible_actuelle" != "" ]]; then
    if [[ "$dossier" =~ "film" ]] || [[ "$dossier" =~ "movie" ]]; then
      dossier_source=${!dossier}
      agent="TheMovieDB"
      format="movieFormat"
      output="{n} ({y})"
    else
      dossier_source=${!dossier}
      agent="TheTVDB"
      format="seriesFormat"
      output="{n}/{'Saison '+s.pad(2)}/{n} - {sxe} - {t}"
    fi
    dossier_var=`echo $dossier | sed -e 's/download/cible/g'`
    dossier_cible=${!dossier_var}
    mes_medias=()
    find "$dossier_source" -type f -iname '*[avi|mp4|mkv]' -print0 >tmpfile 
    while IFS= read -r -d $'\0'; do 
    mes_medias+=("$REPLY")
    done <tmpfile
    rm -f tmpfile
    if [[ "${mes_medias[@]}" != "" ]]; then
      dossier_source_taille=`df -Hl "$dossier_source" | grep '/dev/' | awk '{print $4}'`
      dossier_source_dehumanise=`dehumanise $dossier_source_taille`
      quota_minimum_dehumanise=`dehumanise $quota_minimum`
      if [[ $quota_minimum_dehumanise -lt $dossier_source_dehumanise ]]; then
        eval 'echo -e "[\e[42m\u2713 \e[0m] Traitement en cours dans "$dossier_source' $mon_log_perso
        maj_necessaire="1"
        filebot -script fn:amc -non-strict --conflict override --lang $os_langue --encoding UTF-8 --action move "$dossier_source" --def "$format=$output" --output "$dossier_cible" > filebot.txt 2>/dev/null &
        pid=$!
        spin='-\|/'
        i=0
        while kill -0 $pid 2>/dev/null
        do
        i=$(( (i+1) %4 ))
        printf "\r ..  Chargement... ${spin:$i:1}"
        sleep .1
        done
        printf "\r"
        sed -i '/MOVE/!d' filebot.txt
        media_fait=()
        while IFS= read -r -d $'\n'; do
        media_fait+=("$REPLY")
        done <filebot.txt
        rm -f filebot.txt
        for h in "${media_fait[@]}"; do
          filebot_source=`echo $h | grep "MOVE" | cut -d'[' -f3- | sed 's/] to .*//g'`
          nombre_crochet=`echo $h | grep -o "\[" | wc -m`
          if [[ "$nombre_crochet" == "6" ]]; then
            filebot_cible=`echo $h | grep "MOVE" | cut -d'[' -f4 | sed 's/].*//g'`
          fi
          if [[ "$nombre_crochet" == "8" ]]; then
            filebot_cible=`echo $h | grep "MOVE" | cut -d'[' -f5 | sed 's/].*//g'`
          fi
          if [[ "$nombre_crochet" == "10" ]]; then
            filebot_cible=`echo $h | grep "MOVE" | cut -d'[' -f6 | sed 's/].*//g'`
          fi
          eval 'echo "     Fichier: "$filebot_source' $mon_log_perso
          eval 'echo "     ... renommé/déplacé: "$filebot_cible' $mon_log_perso
        done
        mes_dossiers_a_nettoyer+=("$dossier_source")
      else
        eval 'echo -e "[\e[41m\u2717 \e[0m] Traitement non effectué dans "$dossier_source" : quota insuffisant"' $mon_log_perso
      fi
    else
      eval 'echo -e "[\e[41m\u2717 \e[0m] Aucun média détecté dans "$dossier_source' $mon_log_perso
    fi
  fi
done

#### Recherche de dupe
if [[ "$CHECK_MUI" != "" ]]; then
  source $mon_script_langue
  eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_doublons"' $mon_log_perso
else
  eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mRECHERCHE DE DOUBLONS  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
fi
eval 'echo " ..  Scan en cours"' $mon_log_perso
find "/mnt" -path '/mnt/sd*' -type f -iname '*[avi|mp4|mkv|divx]' > mes_medias.txt &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r ..  Chargement... ${spin:$i:1}"
  sleep .1
done
printf "\r"
sed -i '/\.srt/d' mes_medias.txt
sed -i 's/\.[^.]*$//' mes_medias.txt
sed -i '/\/mnt\/Plex\//d' mes_medias.txt
sed -i '/\/Plex\//!d' mes_medias.txt
sed -i '/desktop/d' mes_medias.txt
sed -i 's/.*\///' mes_medias.txt
sort mes_medias.txt | uniq -cd > mes_doublons.txt
mes_doublons=`cat mes_doublons.txt`
nombre_doublon=`wc -l < mes_doublons.txt`
rm mes_medias.txt
if [[ "$mes_doublons" == "" ]]; then
  eval 'echo -e "[\e[42m\u2713 \e[0m] Aucun doublon détecté"' $mon_log_perso
else
  eval 'echo -e "[\e[41m\u2717 \e[0m] Des doublons ont été détectés ("$nombre_doublon")"' $mon_log_perso
fi
if [[ "$mes_doublons" != "" ]]; then
  maj_necessaire="1"
  eval 'echo " ..  Mise à jour de la base de donnée"' $mon_log_perso
  updatedb
  eval 'echo " ..  Base de donnée mise à jour"' $mon_log_perso
  sed -i 's/^[ \t]*//' mes_doublons.txt
  sed -i 's/[^ ]* //' mes_doublons.txt
  sed -i '/desktop/d' mes_doublons.txt
  mes_medias=()
  while IFS= read -r -d $'\n'; do
  mes_medias+=("$REPLY")
  done <mes_doublons.txt
  rm -f mes_doublons.txt
  echo " ..  traitement des doublons"
  for i in "${mes_medias[@]}"; do
    eval 'echo -e "[\e[41m  \e[0m] Média trouvé: "$i' $mon_log_perso
    locate -ir "$i" > mon_doublon.txt
    sed -i '/\.srt/d' mon_doublon.txt
    sed -i '/\/mnt\/Plex\//d' mon_doublon.txt
    sed -i '/\/Plex\//!d' mon_doublon.txt
    mon_media=()
    while IFS= read -r -d $'\n'; do
    mon_media+=("$REPLY")
    done <mon_doublon.txt
    for j in "${mon_media[@]}"; do
      eval 'echo "     ... chemin: "$j' $mon_log_perso
    done
    while read -r line; do
    stat -c '%Y %n' "$line"
    done < mon_doublon.txt | sort -n -r | sed -n '1p' | sed 's/[^ ]* //' > bon.txt
    plus_recent=`cat bon.txt`
    eval 'echo "     ... le plus récent: "$plus_recent' $mon_log_perso
    grep -v "$plus_recent" mon_doublon.txt > a_supprimer.txt
    a_supprimer=()
    while IFS= read -r -d $'\n'; do
    a_supprimer+=("$REPLY")
    done <a_supprimer.txt
    for k in "${a_supprimer[@]}"; do
      eval 'echo "     ... suppression de: "$k' $mon_log_perso
      rm -f "$k"
    done
    rm -f /opt/scripts/mes_doublons.txt
    rm -f mon_doublon.txt
    rm -f bon.txt
    rm -f a_supprimer.txt
  done
fi

## Suppression des fichier inutiles et dossiers vides
if [[ "${mes_dossiers_a_nettoyer[@]}" != "" ]]; then
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_nettoyage"' $mon_log_perso
  else
    eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mNETTOYAGE DES DOSSIERS  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
  fi
  for dossier_source in "${mes_dossiers_a_nettoyer[@]}" ; do
    locate -ir /sample$ | sed '#'$dossier_source'#!d' > $dossier_config/tmpfolder & # -ir : ignore la casse
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r ..  Recherche en cours dans $dossier_source ... ${spin:$i:1}"
      sleep .1
    done
    locate -ir /proof$ | sed '#'$dossier_source'#!d' >> $dossier_config/tmpfolder & # -ir : ignore la casse
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r ..  Recherche en cours dans $dossier_source ... ${spin:$i:1}"
      sleep .1
    done
    locate -ir \]$ | sed '#'$dossier_source'#!d' >> $dossier_config/tmpfolder & # -ir : ignore la casse
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r ..  Recherche en cours dans $dossier_source ... ${spin:$i:1}"
      sleep .1
    done
    find "$dossier_source" -type f \( -iname \*.jpg -o -iname \*.png -o -iname \*.diz -o -iname \*.txt -o -iname \*.nfo -o -iname \*.db \) -print0 > $dossier_config/tmpfile &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r ..  Recherche en cours dans $dossier_source ... ${spin:$i:1}"
      sleep .1
    done
    printf "$mon_printf" && printf "\r"
    mes_dossiers_a_supprimer=()
    mes_fichiers_a_supprimer=()
    while IFS= read -r -d $'\n'; do
      mes_dossiers_a_supprimer+=("$REPLY")
    done <$dossier_config/tmpfolder
    while IFS= read -r -d $'\0'; do
      mes_fichiers_a_supprimer+=("$REPLY")
    done <$dossier_config/tmpfile
    if [[ $mes_dossiers_a_supprimer != "" ]] ; then
      for i in "${mes_dossiers_a_supprimer[@]}"; do
        test_source=`echo $i | grep -o $dossier_source`
        if [[ "$test_source" != "" ]] ; then
          if [[ -d "$i" ]]; then
            eval 'echo -e " ..  suppression de : "$i' $mon_log_perso
            rm -rf "$i"
          fi
        fi
      done
    fi
    if [[ $mes_fichiers_a_supprimer != "" ]] ; then
      for i in "${mes_fichiers_a_supprimer[@]}"; do
        test_source=`echo $i | grep -o $dossier_source`
        if [[ "$test_source" != "" ]] ; then
          if [[ -f "$i" ]]; then
            eval 'echo -e " ..  suppression de : "$i' $mon_log_perso
            rm -f "$i"
          fi
      fi
      done
    fi
    find $dossier_source -depth -type d -empty -not -path "$dossier_source" > $dossier_config/tmpfolder &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r ..  Recherche en cours dans $dossier_source ... ${spin:$i:1}"
      sleep .1
    done
    printf "$mon_printf" && printf "\r"
    dossiers_vides=()
    while IFS= read -r -d $'\n'; do
      dossiers_vides+=("$REPLY")
    done <$dossier_config/tmpfolder
    if [[ "${dossiers_vides[@]}" != "" ]]; then
      for l in "${dossiers_vides[@]}"; do
        test_source=`echo $l | grep -o $dossier_source`
        if [[ "$test_source" != "" ]] ; then
          if [[ -d "$l" ]]; then
            eval 'echo -e " ..  suppression de : "$l' $mon_log_perso
            rmdir "$l"
          fi
        fi
      done
    fi
  done
  rm -f $dossier_config/tmpfolder
  rm -f $dossier_config/tmpfile
  eval 'echo -e "[\e[42m\u2713 \e[0m] Procédure de nettoyage terminée"' $mon_log_perso
fi

#### Suppression des dossiers vides
if [[ "$CHECK_MUI" != "" ]]; then
  source $mon_script_langue
  eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_dossiers_vides"' $mon_log_perso
else
  eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mRECHERCHE DE DOSSIERS VIDES  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
fi
echo " ..  Scan en cours"
find "/mnt/" -depth -path '/mnt/sd*' -type d -empty | sed '/\/Plex\//!d' > dossiers_vides.txt &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r ..  Chargement... ${spin:$i:1}"
  sleep .1
done
printf "\r"
dossiers_vides=()
while IFS= read -r -d $'\n'; do
  dossier_a_supprimer=`echo $REPLY | sed 's/\(.*\)\/.*/\1/' | grep '/Plex/'`
  if [[ "$dossier_a_supprimer" != "" ]]; then
    dossiers_vides+=("$REPLY")
  fi
done <dossiers_vides.txt
rm dossiers_vides.txt
if [[ "${dossiers_vides[@]}" != "" ]]; then
  eval 'echo -e "[\e[41m\u2717 \e[0m] Des dossiers vides ont été détectés"' $mon_log_perso
  for l in "${dossiers_vides[@]}"; do
    eval 'echo "     Dossier: "$l' $mon_log_perso
    rmdir "$l"
    eval 'echo "     ... suppression effectuée"' $mon_log_perso
  done
else
  eval 'echo -e "[\e[42m\u2713 \e[0m] Aucun dossier vide détecté"' $mon_log_perso
fi

#### Mise à jour de Plex
if [[ "$CHECK_MUI" != "" ]]; then
  source $mon_script_langue
  eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_plex"' $mon_log_perso
else
  eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mVERIFICATION DE PLEX  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
fi
verification_plex=`wget -q -O- http://localhost:32400/web | grep "<title>Plex</title>"`
if [[ "$verification_plex" != "" ]]; then
  eval 'echo -e "[\e[42m\u2713 \e[0m] Serveur Plex en fonctionnement"' $mon_log_perso
  if [[ "$maj_necessaire" == "1" ]]; then
    eval 'echo -e "[\e[42m\u2713 \e[0m] Mise à jour de la librairie en cours"' $mon_log_perso
    cd /root
    url_refresh=`echo "http://127.0.0.1:32400/library/sections/all/refresh?X-Plex-Token="$token`
    wget -q "$url_refresh"
    rm -rf refresh?X-Plex-Token=$token
  else
    eval 'echo -e "[\e[41m\u2717 \e[0m] Aucun nouveau média, mise à jour de librairie pas nécessaire"' $mon_log_perso
  fi
else
  service plexmediaserver restart
  my_message=`echo -e "[ <b>ERREUR</b> ] Le serveur est en erreur, redémarrage demandé."`
  push-message "Range" "$my_message"
  eval 'echo -e "[\e[41m\u2717 \e[0m] Serveur Plex pas lancé"' $mon_log_perso
fi

#### Recherche de dossiers log vides
if [[ "$maj_necessaire" == "0" ]] ; then
  if [[ "$CHECK_MUI" != "" ]]; then
    source $mon_script_langue
    printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_dossiers_log_vides"
  else
    echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mRECHERCHE DE DOSSIERS LOG VIDES  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"
  fi
  rm -f "$fichier_log_perso"
  dossier_log=`echo $dossier_config"/log"`
  if [[ ! -d "$dossier_log" ]]; then mkdir -p "$dossier_log"; fi
  find $dossier_log -depth -type d -empty -not -path "$dossier_log" > $dossier_config/dossiers_vides.txt &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r ..  Recherche de dossier(s) log vide(s)... ${spin:$i:1}"
    sleep .1
  done
  printf "$mon_printf" && printf "\r"
  dossiers_vides=()
  while IFS= read -r -d $'\n'; do
    dossiers_vides+=("$REPLY")
  done <$dossier_config/dossiers_vides.txt
  rm -f $dossier_config/dossiers_vides.txt
  if [[ "${dossiers_vides[@]}" != "" ]]; then
    echo -e "[\e[41m\u2717 \e[0m] Des dossiers log vides ont été détectés"
    for l in "${dossiers_vides[@]}"; do
      test_source=`echo $l | grep -o $dossier_log`
      if [[ "$test_source" != "" ]] ; then
        if [[ -d "$l" ]]; then
          echo -e "     ... suppression de : "$l
          rmdir "$l"
        fi
      fi
    done
  else
    echo -e "[\e[42m\u2713 \e[0m] Aucun dossier log vide détecté"
  fi
fi


fin_script=`date`
if [[ "$CHECK_MUI" != "" ]]; then
  source $mon_script_langue
  my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_after_count=$((($line_lengh-$my_title_count)/2))
  if [[ $before_after_count =~ ".5" ]]; then
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      before_after_count=$(((($line_lengh-$my_title_count)/2)+1))
      after=`eval printf "%0.s-" {1..$before_after_count}`
    else
      before_after_count=$((($line_lengh-$my_title_count)/2))
      before=`eval printf "%0.s-" {1..$before_after_count}`
      after=`eval printf "%0.s-" {1..$before_after_count}`
  fi
  if [[ -f "$fichier_log_perso" ]]; then
    eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"' $mon_log_perso
  else
    printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"
  fi
else
  if [[ -f "$fichier_log_perso" ]]; then
    eval 'echo -e "\e[43m -- FIN DE SCRIPT: $fin_script -- \e[0m "' $mon_log_perso
  else
    echo -e "\e[43m -- FIN DE SCRIPT: $fin_script -- \e[0m "
  fi
fi
if [[ "$maj_necessaire" == "1" ]] && [[ -f "$fichier_log_perso" ]]; then
  cp $fichier_log_perso /var/log/$mon_script_base-last.log
fi
rm "$pid_script"

if [[ "$1" == "--menu" ]]; then
  read -rsp $'Press a key to close the window...\n' -n1 key
fi
