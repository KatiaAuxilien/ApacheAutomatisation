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
"WEB_ADMIN_ADDRESS"
"WEB_PORT"
"WEB_ADMIN_USER"
"WEB_ADMIN_PASSWORD"
"SSL_KEY_PASSWORD"

"PHPMYADMIN_HTACCESS_PASSWORD"
"PHPMYADMIN_ADMIN_ADDRESS"
"PHPMYADMIN_ADMIN_USERNAME"
"PHPMYADMIN_ADMIN_PASSWORD"

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
# Désinstallation de PhpMyAdmin                                     #
#===================================================================#
	logs_info "Services complexes > PhpMyAdmin >  Désinstallation en cours ..."
		
		sudo a2disconf phpmyadmin.conf
		# Désinstaller phpMyAdmin
		sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y phpmyadmin*
		# error_handler $? " a échouée."
		sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y phpmyadmin
		sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y phpmyadmin
		sudo rm -rf /etc/phpmyadmin /usr/share/phpmyadmin /var/lib/phpmyadmin
		sudo rm  -rf /etc/apache2/conf-available/phpmyadmin.conf
		sudo rm  -rf /etc/apache2/sites-available/phpmyadmin.conf

		# sudo systemctl stop phpmyadmin
		# error_handler $? " a échouée."

		# sudo apt-get remove --purge -y phpmyadmin
		# error_handler $? " a échouée."

		# sudo apt-get autoremove -y
		# error_handler $? " a échouée."

		# sudo apt-get remove --purge -y phpmyadmin
		# error_handler $? " a échouée."

		# sudo apt-get autoremove -y
		# error_handler $? " a échouée."

		# sudo apt-get autoclean -y
		# error_handler $? " a échouée."

	logs_success "Services complexes > PhpMyAdmin >  Désinstallation terminée."
#===================================================================#
# Nettoyer les dépendances inutilisées                              #
#===================================================================#

sed -i "/phpmyadmin.$DOMAIN_NAME/d" /etc/hosts


sudo apt-get autoremove -y
# error_handler $? " a échouée."

sudo apt-get autoclean -y
# error_handler $? " a échouée."
#===================================================================#

logs_end "Services complexes > Désinstallation terminée."