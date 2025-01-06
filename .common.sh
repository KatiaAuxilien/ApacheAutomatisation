#!/bin/bash

#===================================================================#
# Variables de couleurs ansii.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Variable pour contrôler le mode verbose.
verbose=false

#===================================================================#
# Fonction de gestion de l'affichage des erreurs.
error_handler()
{
    if [ $1 -ne 0 ]
    then
        echo -e "${RED}Erreur : $2 ${RESET}"
        exit $1
    fi
}

# Fonctions d'affichage.
logs()
{
    if [ "$verbose" = true ]; then
        local color="$1"
        shift
        date_formated=$(date +"%d-%m-%Y %H:%M:%S")
        echo -e "${color}[$date_formated] $1 ${RESET}" | tee -a /var/log/ApacheAutomatisation.log
    fi
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
    logs "$BLUE" "$*"
}
#===================================================================#
# Fonction pour vérifier si une variable est définie.
check_variable() {
  local var_name=$1
  if [ -z "${!var_name+x}" ]; then
    echo "Services complexes > La variable $var_name n'est pas définie."
    exit 2
  fi
}

# Fonction pour exécuter des commandes avec redirection conditionnelle.
run_command() {
    if [ "$verbose" = true ]; then
        "$@"
    else
        "$@" &>/dev/null
    fi
}