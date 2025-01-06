#!/bin/bash

# .·:'''''''''''''''''''''''''''''''''''''''''''''':·.
# : :  ____                       _                : :
# : : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___  : :
# : : | |_) / _` | '_ ` _ \| '_ \| | | | / __/ __| : :
# : : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \ : :
# : : |_|   \__,_|_| |_| |_| .__/|_|\__,_|___/___/ : :
# : :                      |_|                     : :
# '·:..............................................:·'

#===================================================================#

# Variables de couleurs ansii 256
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
PINK='\033[38;5;206m'

# Variable pour contrôler le mode verbose.
verbose=false

# Variable pour la vérification de l'installation ou non des services.
apache_installed=0
phpmyadmin_installed=0
mysql_installed=0
php_installed=0

#===================================================================#

welcome()
{
    if [ "$verbose" = true ]; then
        echo -e "${PINK}$1${RESET}"
    fi
    echo -e "${PINK}$1${RESET}" >> /var/log/ApacheAutomatisation.log
}

# Fonctions d'affichage.
logs()
{   
    local color="$1"
    shift
    date_formated=$(date +"%d-%m-%Y %H:%M:%S")

    if [ "$verbose" = true ]; then
        echo -e "${PINK}[🍋 PAMPLUSS]${RESET}[$date_formated]${color} $1 ${RESET}"
    fi
    echo -e "${PINK}[🍋 PAMPLUSS]${RESET}[$date_formated]${color} $1 ${RESET}" >> /var/log/ApacheAutomatisation.log
}

logs_error()
{
    date_formated=$(date +"%d-%m-%Y %H:%M:%S")
    echo -e "${PINK}[🍋 PAMPLUSS]${RESET}[$date_formated]${RED} $1 ${RESET}"
    echo -e "${PINK}[🍋 PAMPLUSS]${RESET}[$date_formated]${RED} $1 ${RESET}" >> /var/log/ApacheAutomatisation.log
}

logs_info()
{
    logs "$YELLOW" "$*"
}

logs_success()
{
    logs "$GREEN" "$*"
}

logs_end()
{
    verbinit=$verbose
    verbose=true
    logs "$BLUE" "$*"
    verbose=$verbinit
}


# Fonction de gestion de l'affichage des erreurs.
error_handler()
{
    if [ $1 -ne 0 ]
    then
        logs_error "$2"
        exit $1
    fi
}

#===================================================================#

# Fonction pour vérifier si une variable est définie.
check_variable() 
{
  local var_name=$1
  if [ -z "${!var_name+x}" ]; then
    logs_error "La variable $var_name n'est pas définie."
    exit 2
  fi
}

# Fonction pour exécuter des commandes avec redirection conditionnelle.
run_command() 
{
    if [ "$verbose" = "true" ]; then
        "$@" 2>&1 | tee -a /var/log/ApacheAutomatisation.log
    else
        "$@" 2>&1 | tee -a /var/log/ApacheAutomatisation.log &>/dev/null
    fi
}

#===================================================================#

# Vérification de la configuration de la machine hôte.
if [ "$EUID" -ne 0 ]
then
    logs_error "Ce script doit être exécuté avec des privilèges root."
    exit 1
fi

# Analyse des options de ligne de commande.
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --verbose)
            verbose=true
            shift
            ;;
        *)
            logs_error "Erreur : option invalide : $1"
            exit 1
            ;;
    esac
done

#===================================================================#