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


echo "Voulez-vous vraiment désinstaller le serveur apache et ses configurations ? y/n"
read -r uninstall_openssl

if [[ "$response" =~ ^[yY]$ ]] 
then
	sudo systemctl stop apache2
	sudo systemctl disable apache2
	sudo apt remove --purge apache2 -y

	sudo rm -rf /etc/apache2
	sudo rm -rf /var/www/html
	sudo rm -rf/var/log/apache2

#apache2 -v
#sudo find / -name "*apache*" -exec rm -rf {} \

#/etc/apache2/certificate/private_key.pem
#/etc/apache2/certificate/cert_request.csr
#/etc/apache2/certificate/certificate.crt
#/etc/apache2/certificate/

#/var/www/siteA
#/var/www/siteA/index.html
#/etc/apache2/site-available/siteA.conf
#/var/www/siteA/confidential/confidential.html
#/var/www/siteA/confidential/.htaccess

#/var/www/siteB
#/var/www/siteB/index.html
#/var/www/siteB/confidential/confidential.html
#/etc/apache2/site-available/siteB.conf
#/var/www/siteB/confidential/.htaccess

#/var/www/.htpasswd
#/etc/apache2/mods-available/evasive.conf

	
	echo "Voulez-vous désinstaller openssl ? y/n"
	read -r uninstall_openssl

	if [[ "$response" =~ ^[yY]$ ]] 
	then
		logs_info "La désintallation d'openssl en cours ..."
		
		sudo apt remove --purge openssl -y
		error_handler $? "La désinstallation d'openssl a échouée."
		
		sudo rm -rf /usr/local/bin/openssl
		error_handler $? "La suppression du dossier /usr/local/bin/openssl a échouée."

		sudo rm -rf /usr/local/lib/libssl*
		error_handler $? "La suppression du dossier /usr/local/lib/libssl* a échouée."

		sudo rm -rf /usr/local/libcrypto*
		error_handler $? "La suppression du dossier /usr/local/libcrypto* a échouée."

		sudo rm -rf /usr/local/include/openssl
		error_handler $? "La suppression du dossier /usr/local/include/openssl a échouée."

		logs_success "La désinstallation d'openssl terminée."
	else
		logs_success "La désintallation d'openssl a été annulée."
	fi
else
	logs_success "La désintallation d'apache a été annulée."
fi


