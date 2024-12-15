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



DOMAIN_NAME="servicescomplexe.fr"
ADMIN_ADDRESS="admin@servicescomplexe.fr"
KEY_PASSWORD="0407"
ENC_PASSWORD="$apr1$01aqvm23$jVJgj3iBCH.2byoEGqdfT0"


if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer avant de continuer.${RESET}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer avant de continuer.${RESET}"
    exit 1
fi


if [ "$EUID" -ne 0 ]
then
	echo -e "${RED}Ce script doit être exécuté avec des privilèges root.${RESET}"
	exit 1
fi


echo -n "Entrez le nom du container docker : "
read container_name
echo -n "Confirmez le nom du container docker  : "
read confirm_container_name
if [ "$container_name" != "$confirm_container_name" ]; then
	echo -e "${RED}Les noms de container docker ne correspondent pas.${RESET}"
	exit 1
fi


docker build -t ubuntu:latest .

docker run -d -p 79:79 --name "$container_name" ubuntu:latest


log_success "Conteneur Docker lancé avec succès."

log_success "Votre serveur Apache est opérationnel."
