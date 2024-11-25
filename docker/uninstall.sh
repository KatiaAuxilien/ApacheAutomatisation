#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

error_handler()
{
	if [ $1 -ne 0 ]
	then
		echo -e "${RED}Erreur : $2 ${RESET}"
		exit $1
	fi
}

logs()
{
	local color="$1"
	shift
	date_formated=$(date +"%d-%m-%Y %H:%M:%S")
	echo -e "${color}[$date_formated] $1 ${RESET}" | tee -a /var/log/apache_install.log
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

if [ "$EUID" -ne 0 ]
then
	echo -e "${RED}Ce script doit être exécuté avec des privilèges root.${RESET}"
	exit 1
fi

docker ps -a

echo -n "Entrez le nom du container docker à désinstaller : "
read container_name
echo -n "Confirmez le nom du container docker à désinstaller : "
read confirm_container_name
if [ "$container_name" != "$confirm_container_name" ]; then
	echo "${RED}Les noms de container docker ne correspondent pas.${RESET}"
	exit 1
fi


docker stop "$container_name"
error_handler $? "L'arret du container a échoué."

docker rm "$container_name"
error_handler $? "La suppression du container a échouée."

logs_success "$container_name supprimé."