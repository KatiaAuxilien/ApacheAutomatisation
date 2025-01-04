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
"PHPMYADMIN_PORT"

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

		# Désinstaller Apache
		sudo apt-get remove --purge -y apache2*
		# error_handler $? " a échouée."

		sudo rm -rf /etc/apache2
		# error_handler $? "La suppression du dossier /etc/apache2"

		sudo rm -rf /var/www/html
		#error_handler $? "La suppression du dossier /var/www/html"

		sudo rm -rf /var/www/siteA
		error_handler $? "La suppression du dossier /var/www/siteA"

		sudo rm -rf /var/www/siteB
		error_handler $? "La suppression du dossier /var/www/siteB"

		# sudo rm -rf /var/log/apache2
		# error_handler $? "La suppression du dossier /var/log/apache2"

	logs_success "Services complexes > Apache > Désinstallation terminée."

#===================================================================#
# Nettoyer les dépendances inutilisées                              #
#===================================================================#

sed -i "/$DOMAIN_NAME/d" /etc/hosts
sed -i "/siteA.$DOMAIN_NAME/d" /etc/hosts
sed -i "/siteB.$DOMAIN_NAME/d" /etc/hosts

sudo apt-get autoremove -y
# error_handler $? " a échouée."

sudo apt-get autoclean -y
# error_handler $? " a échouée."
#===================================================================#

logs_end "Services complexes > Désinstallation terminée."