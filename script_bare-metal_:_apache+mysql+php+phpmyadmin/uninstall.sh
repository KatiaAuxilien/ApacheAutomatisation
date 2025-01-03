#!/bin/bash

#TODO : Messages de logs
#TODO : Vérification du lancement en droits admin
#TODO : Arrêt de tout les services
#TODO : Suppression des fichiers de configuration de Apache
#TODO : Suppression des fichiers de configuration HTTPS
#TODO : Suppression des fichiers de configuration de ModSecurity
#TODO : Suppression des fichiers de configuration  de ModEvasive
#TODO : Suppression des fichiers de configuration de ModRatelimit
#TODO : Suppression de la configuration des deux sites (siteA, siteB)
#TODO : Suppression de la configuration de la page confidentielle (.htaccess et .htpasswd)
#TODO : Désinstallation de Apache
#TODO : Désinstallation PhpMyAdmin
#TODO : Suppression des fichiers de configuration de PhpMyAdmin
#TODO : Désinstallation PHP
#TODO : Suppression des fichiers de configuration de PHP

#======================================================================#
source ./../.common.sh
#======================================================================#

required_vars_start=(
"DOMAIN_NAME"
"NETWORK_NAME"
"WEB_CONTAINER_NAME"
"WEB_ADMIN_ADDRESS"
"WEB_PORT"
"WEB_ADMIN_USER"
"WEB_ADMIN_PASSWORD"
"SSL_KEY_PASSWORD"

"PHPMYADMIN_CONTAINER_NAME"
"PHPMYADMIN_HTACCESS_PASSWORD"
"PHPMYADMIN_ADMIN_ADDRESS"
"PHPMYADMIN_ADMIN_USERNAME"
"PHPMYADMIN_ADMIN_PASSWORD"
"PHPMYADMIN_PORT"

"DB_CONTAINER_NAME"
"DB_PORT"
"DB_ROOT_PASSWORD"
"DB_ADMIN_USERNAME"
"DB_ADMIN_PASSWORD"
"DB_ADMIN_ADDRESS"
"DB_NAME"
)

#===================================================================#
# Vérifications de l'environnement et des variables                 #
#===================================================================#

source ./.common.sh

#===================================================================#
# Prépartion de l'arborescence                                      #
#===================================================================#


logs_info "Services complexes > Désinstallation en cours ..."

#===================================================================#
# Désinstallation de Apache                                         #
#===================================================================#
	logs_info "Services complexes > Apache > Désinstallation en cours ..."

		sudo systemctl stop apache2
		# error_handler $? "L'arrêt du service apache a échouée."

		sudo systemctl disable apache2
		# error_handler $? "La désactivation d'apache a échouée."

		sudo apt remove --purge -y apache2 apache2-utils apache2-bin apache2.2-common
		# error_handler $? "La désinstallation d'apache a échouée."
		
		sudo apt-get autoremove -y
		# error_handler $? " a échouée."

		sudo apt remove --purge -y libapache2-mod-security2
		# error_handler $? "La désinstallation de libapache2-mod-security2 a échouée."
		
		sudo apt-get autoremove -y
		# error_handler $? " a échouée."
		
		sudo apt remove --purge -y libapache2-mod-evasive 
		# error_handler $? "La désinstallation de libapache2-mod-evasive a échouée."
		
		sudo apt-get autoremove -y
		# error_handler $? " a échouée."
		
		sudo apt remove --purge -y ssl-cert
		# error_handler $? " a échouée."
		
		sudo apt-get autoremove -y
		# error_handler $? " a échouée."
		
		sudo rm -rf /etc/apache2
		# error_handler $? "La suppression du dossier /etc/apache2"

		sudo rm -rf /var/www/html
		#error_handler $? "La suppression du dossier /var/www/html"

		sudo rm -rf /var/log/apache2
		# error_handler $? "La suppression du dossier /var/log/apache2"

		sudo rm -rf /var/www/siteA
		# error_handler $? "La suppression du dossier /var/www/siteA"

		sudo rm -rf /var/www/siteB
		# error_handler $? "La suppression du dossier /var/www/siteB"
		
		sudo apt-get autoclean -y
		# error_handler $? " a échouée."
	logs_success "Services complexes > Apache > Désinstallation terminée."

#===================================================================#
# Désinstallation de mysql                                          #
#===================================================================#
	logs_info "Services complexes > MySQL >  Désinstallation en cours ..."

		# Arrêter le service MySQL
		sudo systemctl stop mysql
		# error_handler $? " a échouée."

		# Désinstaller les paquets MySQL
		sudo apt-get remove --purge -y mysql-server mysql-client mysql-common
		# error_handler $? " a échouée."

		# Supprimer les fichiers de configuration et les bases de données
		sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
		# error_handler $? " a échouée."

		# Supprimer les paquets MySQL résiduels
		sudo apt-get autoremove -y
		# error_handler $? " a échouée."

		sudo apt-get autoclean -y
		# error_handler $? " a échouée."

		# Vérifier la suppression
		sudo find / -name '*mysql*'
		# error_handler $? " a échouée."

	logs_success "Services complexes > MySQL >  Désinstallation terminée."
#===================================================================#
# Désinstallation de PHP                                            #
#===================================================================#
	logs_info "Services complexes > PHP >  Désinstallation en cours ..."

		# sudo systemctl stop php8.3-fpm
		# error_handler $? " a échouée."

		sudo apt-get remove --purge -y libapache2-mod-php
		# error_handler $? " a échouée."

		sudo apt-get autoremove -y
		# error_handler $? " a échouée."
		
		sudo apt-get remove --purge -y php libapache2-mod-php php-mysql php-xml php-mbstring php-curl php-zip php-gd
		# error_handler $? " a échouée."

		sudo rm -rf /etc/php /usr/lib/php /usr/share/php
		# error_handler $? " a échouée."
		
		sudo apt-get autoremove -y
		# error_handler $? " a échouée."
		
		sudo apt-get autoclean -y
		# error_handler $? " a échouée."

	logs_success "Services complexes > PHP >  Désinstallation terminée."
#===================================================================#
# Désinstallation de PhpMyAdmin                                     #
#===================================================================#
	logs_info "Services complexes > PhpMyAdmin >  Désinstallation en cours ..."
		
		sudo systemctl stop phpmyadmin
		# error_handler $? " a échouée."

		sudo apt-get remove --purge -y phpmyadmin
		# error_handler $? " a échouée."

		sudo apt-get autoremove -y
		# error_handler $? " a échouée."

		sudo rm -rf /etc/phpmyadmin /usr/share/phpmyadmin /var/lib/phpmyadmin
		# error_handler $? " a échouée."

		sudo apt-get remove --purge -y phpmyadmin
		# error_handler $? " a échouée."

		sudo apt-get autoremove -y
		# error_handler $? " a échouée."

		sudo apt-get autoclean -y
		# error_handler $? " a échouée."

	logs_success "Services complexes > PhpMyAdmin >  Désinstallation terminée."

logs_end "Services complexes > Désinstallation terminée."