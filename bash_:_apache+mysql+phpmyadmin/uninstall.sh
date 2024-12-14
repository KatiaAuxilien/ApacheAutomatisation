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


echo "Voulez-vous vraiment désinstaller les services apache, php, phpmyadmin, mysql et ses configurations ? y/n"
read -r uninstall_apache

if [[ "$uninstall_apache" =~ ^[yY]$ ]] 
then

logs_info "Désintallation d'apache en cours ..."

	sudo systemctl stop apache2
	error_handler $? "L'arrêt du service apache a échouée."
	
	sudo systemctl disable apache2
	error_handler $? "La désactivation d'apache a échouée."
	
	sudo a2dissite siteA.conf
	#TODO

	sudo a2dissite siteB.conf
	#TODO

	sudo a2dismod ssl headers rewrite evasive security2
	#TODO

	sudo rm -rf /etc/apache2/certificate/"$DOMAIN_NAME"_server.crt
	#TODO

	sudo rm -rf /etc/apache2/certificate/"$DOMAIN_NAME"_server.key
	#TODO

	sudo apt remove --purge apache2 -y
	error_handler $? "La désinstallation d'apache a échouée."

	sudo rm -rf /etc/apache2
	error_handler $? "La suppression du dossier /etc/apache2"
	
	sudo rm -rf /var/log/apache2
	error_handler $? "La suppression du dossier /var/log/apache2"

	sudo rm -rf /var/www/siteA
	error_handler $? "La suppression du dossier /var/www/siteA"

	sudo rm -rf /var/www/siteB
	error_handler $? "La suppression du dossier /var/www/siteB"

	sudo rm -rf /var/www/.htpasswd
	#TODO

	sudo apt-get purge apache2 apache2-utils apache2-bin apache2.2-common -y
	error_handler $? "La désinstallation des services apache2 apache2-utils apache2-bin apache2.2-common a échouée."


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

# /etc/modsecurity/modsecurity.conf

logs_success "Désinstallation d'apache terminée."

logs_info "Désintallation de mod-security en cours ..."

	sudo apt remove --purge libapache2-mod-security2 -y
	error_handler $? "La désinstallation de libapache2-mod-security2 a échouée."
	
	sudo rm -rf /etc/apache2/mods-available/security2.conf
	#TODO

logs_success "Désinstallation de mod-security terminée."

logs_info "Désintallation de mod-evasive en cours ..."
	sudo apt remove --purge libapache2-mod-evasive -y
	error_handler $? "La désinstallation de libapache2-mod-evasive a échouée."

	sudo rm -rf /var/log/mod_evasive
	#TODO

	sudo rm -rf /etc/apache2/mods-available/evasive.conf
	#TODO

logs_success "Désinstallation de mod-evasive terminée."

logs_info "Désintallation de phpmyadmin et php en cours ..."
	sudo rm -rf /etc/phpmyadmin/.htpasswd
	#TODO

	sudo apt remove --purge phpmyadmin -y
	#TODO

	sudo apt remove --purge libapache2-mod-php -y
	#TODO

	sudo apt remove --purge php-mysql -y
	#TODO
logs_success "Désinstallation de phpmyadmin et php terminée."

logs_info "Désintallation de mysql en cours ..."
	sudo systemctl stop mysql
	#TODO

	sudo rm -rf /var/lib/mysql
	#TODO
	sudo rm -rf /var/lib/etc/mysql
	#TODO
	sudo deluser mysql-server
	#TODO
	sudo delgroup mysql
	#TODO
	sudo rm -rf /var/lib/mysql
	#TODO
	sudo rm -rf /etc/mysql/

	#TODO
	sudo apt remove --purge mysql-server -y
	#TODO

logs_success "Désinstallation de mysql terminée."

logs_end "Désinstallation complète des services de configurations. Tous les fichiers et paramètres ont été supprimés."

else
	logs_success "La désintallation d'apache a été annulée."
fi
exit 0
