#!/bin/bash

########################
## Script de Z0uZOU
########################
## Micro-config
version="Version: 3.0" #base du système de mise à jour
script_github="https://raw.githubusercontent.com/Z0uZOU/Range/master/range3.sh" #emplacement du script original
icone_github="https://github.com/Z0uZOU/Range/raw/master/.cache-icons/range.png" #emplacement de l'icône du script
repos_requis="" #ajout de repository
outils_requis="" #dépendances du script
outils_requis_pip="" #dépendances du script (PIP)
script_cron="*/15 * * * *" #ne définir que la planification
verification_process="" #si ces process sont détectés on ne notifie pas (ou ne lance pas en doublon)
########################


#### Vérification de la langue du system
if [[ "$@" =~ "--langue=" ]]; then
  affichage_langue=`echo "$@" | sed 's/.*--langue=//' | sed 's/ .*//' | tr '[:upper:]' '[:lower:]'`
else
  affichage_langue=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
fi
verif_langue=`curl -s "https://raw.githubusercontent.com/Z0uZOU/Range/master/MUI/$affichage_langue.lang"`
if [[ "$verif_langue" == "404: Not Found" ]]; then
  affichage_langue="en"
fi


#### Déduction des noms des fichiers (pour un portage facile)
mon_script_fichier=`basename "$0"`
mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
mon_script_base_maj=`echo ${mon_script_base^^}`
mon_dossier_config=`echo "/root/.config/"$mon_script_base`
mon_script_config=`echo $mon_dossier_config"/"$mon_script_base".conf"`
mon_script_langue=`echo $mon_dossier_config"/MUI/"$affichage_langue".lang"`
mon_script_desktop=`echo $mon_script_base".desktop"`
mon_script_updater=`echo $mon_script_base"-update.sh"`
mon_script_pid=`echo $mon_dossier_config"/lock-"$mon_script_base`
mon_path_log=`echo $mon_dossier_config"/log"`
date_log=`date +%Y%m%d`
heure_log=`date +%H%M`
mon_fichier_log=`echo $mon_path_log"/"$date_log"/"$heure_log".log"`


#### Vérification que le script possède les droits root
## NE PAS TOUCHER
if [ "$(whoami)" != "root" ]; then
  if [[ "$CRON_SCRIPT" == "oui" ]]; then
    exit 1
  else
    source <(curl -s https://raw.githubusercontent.com/Z0uZOU/Range/master/MUI/$affichage_langue.lang)
    echo "$mui_root_check"
    exit 1
  fi
fi


#### Chargement du fichier pour la langue (ou installation)
if [[ -f "$mon_script_langue" ]]; then
  distant_md5=`curl -s "https://raw.githubusercontent.com/Z0uZOU/Range/master/MUI/$affichage_langue.lang" | md5sum | cut -f1 -d" "`
  local_md5=`md5sum "$mon_script_langue" 2>/dev/null | cut -f1 -d" "`
  if [[ $distant_md5 != $local_md5 ]]; then
    wget --quiet "https://raw.githubusercontent.com/Z0uZOU/Range/master/MUI/$affichage_langue.lang" -O "$mon_script_langue"
    chmod +x "$mon_script_langue"
  fi
else
  wget --quiet "https://raw.githubusercontent.com/Z0uZOU/Range/master/MUI/$affichage_langue.lang" -O "$mon_script_langue"
  chmod +x "$mon_script_langue"
fi
source $mon_script_langue


#### Fonction pour envoyer des push
push-message() {
  push_title=$1
  push_content=$2
  push_priority=$3
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
        --form-string "token=$token_app" \
        --form-string "user=$destinataire" \
        --form-string "title=$push_title" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=$push_priority" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
}


#### Vérification de process pour éviter les doublons (commandes externes)
for process_travail in $verification_process ; do
  process_important=`ps aux | grep $process_travail | sed '/grep/d'`
  if [[ "$process_important" != "" ]] ; then
    if [[ "$CRON_SCRIPT" != "oui" ]] ; then
      echo "$process_travail $mui_prevent_dupe_task"
      end_of_script=`date`
      source $mon_script_langue
      my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | sed 's/é/e/g' | wc -c`
      line_lengh="78"
      before_count=$((($line_lengh-$my_title_count)/2))
      after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
      before=`eval printf "%0.s-" {1..$before_count}`
      after=`eval printf "%0.s-" {1..$after_count}`
      printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"
    fi
    exit 1
  fi
done


#### Tests des arguments
for parametre in $@; do
  if [[ "$parametre" == "--debug" ]]; then
    debug="yes"
  fi
  if [[ "$parametre" == "--edit-config" ]]; then
    nano $mon_script_config
    exit 1
  fi
  if [[ "$parametre" == "--efface-lock" ]]; then
    mon_lock=`echo $mon_dossier_config"/lock-"$mon_script_base`
    rm -f "$mon_lock"
    echo -e "$mui_lock_removed"
    exit 1
  fi
  if [[ "$parametre" == "--statut-lock" ]]; then
    statut_lock=`cat $mon_script_config | grep "maj_force=\"oui\""`
    if [[ "$statut_lock" == "" ]]; then
      echo -e "$mui_lock_status_on"
    else
      echo -e "$mui_lock_status_off"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--active-lock" ]]; then
    sed -i 's/maj_force="oui"/maj_force="non"/g' $mon_script_config
    echo -e "$mui_lock_status_on"
    exit 1
  fi
  if [[ "$parametre" == "--desactive-lock" ]]; then
    sed -i 's/maj_force="non"/maj_force="oui"/g' $mon_script_config
    echo -e "$mui_lock_status_off"
    exit 1
  fi
  if [[ "$parametre" == "--extra-log" ]]; then
    mon_log_perso="| tee -a $mon_fichier_log"
  fi
  if [[ "$parametre" == "--purge-process" ]]; then
    pgrep -x "$mon_script_fichier" | xargs kill -9
    echo -e "$mui_purge_process"
    exit 1
  fi
  if [[ "$parametre" == "--purge-log" ]]; then
    cd $mon_path_log
    mon_chemin=`echo $PWD`
    if [[ "$mon_chemin" == "$mon_path_log" ]]; then
      printf "$mui_purge_log_question : "
      read question_effacement
      reponse_effacement=`echo $question_effacement | tr '[:upper:]' '[:lower:]'`
      if [[ "$reponse_effacement" == "$mui_purge_log_answer_yes" ]]; then
        rm -rf *
        echo -e "$mui_purge_log_done"
      fi
    else
      echo -e "$mui_purge_log_ko"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--help" ]]; then
    i=""
    for i in _ {a..z} {A..Z}; do eval "echo \${!$i@}" ; done | xargs printf "%s\n" | grep mui_menu_help > variables
    help_lignes=`wc -l variables | awk '{print $1}'`
    rm -f variables
    j=""
    mui_menu_help="mui_menu_help_"
    for j in $(seq 1 $help_lignes); do
      source $mon_script_langue
      mui_menu_help_display=`echo -e "$mui_menu_help$j"`
      echo -e "${!mui_menu_help_display}"
    done
    exit 1
  fi
done

#### Chargement du fichier conf si présent
if [[ -f "$mon_script_config" ]] ; then
  source $mon_script_config
fi

#### Vérification qu'au reboot les lock soient bien supprimés
test_crontab=`crontab -l | grep "clean-lock"`
if [[ "$test_crontab" == "" ]]; then
  crontab -l > $dossier_config/mon_cron.txt
  sed -i '5i@reboot\t\t\tsleep 10 && /opt/scripts/clean-lock.sh' $dossier_config/mon_cron.txt
  crontab $dossier_config/mon_cron.txt
  rm -f $dossier_config/mon_cron.txt
fi

#### Vérification qu'une autre instance de ce script ne s'exécute pas
if [[ "$maj_force" == "non" ]] ; then
  if [[ -f "$mon_script_pid" ]] ; then
    computer_name=`hostname`
    source $mon_script_langue
    echo "$mui_pid_check"
    push-message "$mui_pid_check_title" "$mui_pid_check" "1"
    exit 1
  fi
fi
touch $mon_script_pid

#### Chemin du script
## necessaire pour le mettre dans le cron
cd /opt/scripts

#### Indispensable aux messages de chargement
mon_printf="\r                                                                                                                                "

#### Nettoyage obligatoire et push pour annoncer la maj
if [[ -f "$mon_script_updater" ]] ; then
  rm "$mon_script_updater"
  push-message "$mui_pushover_updated_title" "$mui_pushover_updated_msg" "1"
fi


#### Vérification de version pour éventuelle mise à jour
distant_md5=`curl -s "$script_github" | md5sum | cut -f1 -d" "`
local_md5=`md5sum "$0" 2>/dev/null | cut -f1 -d" "`
if [[ $distant_md5 != $local_md5 ]]; then
  eval 'echo -e "$mui_update_available"' $mon_log_perso
  eval 'echo -e "$mui_update_download"' $mon_log_perso
  touch $mon_script_updater
  chmod +x $mon_script_updater
  echo "#!/bin/bash" >> $mon_script_updater
  mon_script_fichier_temp=`echo $mon_script_fichier"-temp"`
  echo "wget -q $script_github -O $mon_script_fichier_temp" >> $mon_script_updater
  echo "sed -i -e 's/\r//g' $mon_script_fichier_temp" >> $mon_script_updater
  echo "mv $mon_script_fichier_temp $mon_script_fichier" >> $mon_script_updater
  echo "chmod +x $mon_script_fichier" >> $mon_script_updater
  echo "chmod 777 $mon_script_fichier" >> $mon_script_updater
  echo "$mui_update_done" >> $mon_script_updater
  echo "bash $mon_script_fichier $@" >> $mon_script_updater
  echo "exit 1" >> $mon_script_updater
  rm "$mon_script_pid"
  bash $mon_script_updater
  exit 1
else
  source $mon_script_langue
  my_title_count=`echo -n "$mui_title" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_title" "$after"' $mon_log_perso
fi


#### Nécessaire pour l'argument --update
if [[ "$@" == "--update" ]]; then
  rm "$mon_script_pid"
  exit 1
fi





end_of_script=`date`
source $mon_script_langue
my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | sed 's/é/e/g' | wc -c`
line_lengh="78"
before_count=$((($line_lengh-$my_title_count)/2))
after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
before=`eval printf "%0.s-" {1..$before_count}`
after=`eval printf "%0.s-" {1..$after_count}`
eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"' $mon_log_perso
if [[ "$maj_necessaire" == "1" ]] && [[ -f "$fichier_log_perso" ]]; then
  cp $fichier_log_perso /var/log/$mon_script_base-last.log
fi
rm "$mon_script_pid"

if [[ "$1" == "--menu" ]]; then
  read -rsp $'Press a key to close the window...\n' -n1 key
fi
