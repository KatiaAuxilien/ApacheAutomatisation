#!/bin/bash

#===================================================================#
#                            Sommaire                               #
#===================================================================#
# 1. Vérifications de l'environnement et des variables              #
# 2. Désinstallation de PHP                                         #
# 3. Désinstallation de Apache                                      #
# 4. Désinstallation de mysql                                       #
# 5. Désinstallation de PhpMyAdmin                                  #
# 6. Effacer les lignes /etc/hosts                                  #
# 7. Nettoyer les dépendances inutilisées                           #
#===================================================================#

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
# 1. Vérifications de l'environnement et des variables              #
#===================================================================#

source ./.common.sh

#===================================================================#

logs_info "Désinstallation en cours ..."

#===================================================================#
# 2. Désinstallation de PHP                                         #
#===================================================================#
	logs_info "PHP > Désinstallation en cours ..."

		# Désinstaller PHP et ses extensions
		sudo apt-get remove --purge -y php*
		error_handler $? "PHP > Désinstallation de php* a échouée."

		sudo rm -rf /etc/php
		error_handler $? "PHP > La suppression du dossier /etc/php a échouée."

	logs_success "PHP >  Désinstallation terminée."

#===================================================================#
# 3. Désinstallation de Apache                                      #
#===================================================================#
	logs_info "Apache > Désinstallation en cours ..."

		sudo systemctl stop apache2
		error_handler $? "Apache > L'arrêt du service apache a échouée."

		sudo systemctl disable apache2
		error_handler $? "Apache > La désactivation d'apache a échouée."

		# Désinstaller Apache
		sudo apt-get remove --purge -y apache2*
		error_handler $? "Apache > Désinstallation de apache2* a échouée."

		sudo rm -rf /etc/apache2
		error_handler $? "Apache > La suppression du dossier /etc/apache2 a échouée."

		sudo rm -rf /var/www/html
		error_handler $? "Apache > La suppression du dossier /var/www/html a échouée."

		sudo rm -rf /var/www/siteA
		error_handler $? "Apache > La suppression du dossier /var/www/siteA"

		sudo rm -rf /var/www/siteB
		error_handler $? "Apache > La suppression du dossier /var/www/siteB"
		
		sudo rm -rf /var/log/mod_evasive
		error_handler $? "Apache > La suppression du dossier /var/log/mod_evasive"

		# sudo apt remove --purge -y libapache2-mod-security2
		# error_handler $? "Apache > La désinstallation de libapache2-mod-security2 a échouée."
		
		# sudo apt remove --purge -y libapache2-mod-evasive 
		# error_handler $? "Apache > La désinstallation de libapache2-mod-evasive a échouée."
		
		# sudo apt remove --purge -y ssl-cert
		# error_handler $? "Apache >  a échouée."

	logs_success "Apache > Désinstallation terminée."

#===================================================================#
# 4. Désinstallation de mysql                                       #
#===================================================================#
	logs_info "MySQL >  Désinstallation en cours ..."

		# Désinstaller MySQL
		sudo apt-get remove --purge -y mysql-server*
		error_handler $? "MySQL > Désinstallation de mysql-server* a échouée."

		sudo rm -rf /etc/mysql
		error_handler $? "MySQL > La suppression du dossier /etc/mysql a échouée."

		sudo rm -rf /var/lib/mysql
		error_handler $? "MySQL > La suppression du dossier /var/lib/mysql a échouée."

		sudo rm -rf /var/log/mysql
		error_handler $? "MySQL > La suppression du dossier /var/log/mysql a échouée."

	logs_success "MySQL >  Désinstallation terminée."

#===================================================================#
# 5. Désinstallation de PhpMyAdmin                                  #
#===================================================================#
	logs_info "PhpMyAdmin >  Désinstallation en cours ..."
		
		# Désinstaller phpMyAdmin
		sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y phpmyadmin*
		error_handler $? "PhpMyAdmin > La désinstallation de phpmyadmin* a échouée."

		sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y phpmyadmin
		error_handler $? "PhpMyAdmin > La suppression des fichiers résiduels a échouée."

		sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y phpmyadmin
		error_handler $? "PhpMyAdmin > La suppression des dépendances inutilisées a échouée."

		sudo rm -rf /etc/phpmyadmin /usr/share/phpmyadmin /var/lib/phpmyadmin
		error_handler $? "PhpMyAdmin > La suppression des dossiers /etc/phpmyadmin /usr/share/phpmyadmin /var/lib/phpmyadmin a échouée."

		sudo rm  -rf /etc/apache2/conf-available/phpmyadmin.conf
		error_handler $? "PhpMyAdmin > La suppression du fichier /etc/apache2/conf-available/phpmyadmin.conf a échouée."

		sudo rm  -rf /etc/apache2/sites-available/phpmyadmin.conf
		error_handler $? "PhpMyAdmin > La suppression du fichier /etc/apache2/sites-available/phpmyadmin.conf a échouée."

	logs_success "PhpMyAdmin >  Désinstallation terminée."
#===================================================================#
# 6. Effacer les lignes /etc/hosts                                  #
#===================================================================#
logs_info "Suppression des lignes des services de /etc/hosts en cours ..."
	sed -i "/$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne $DOMAIN_NAME dans /etc/hosts a échouée."
	
	sed -i "/siteA.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne siteA.$DOMAIN_NAME dans /etc/hosts a échouée."
	
	sed -i "/siteB.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne siteB.$DOMAIN_NAME dans /etc/hosts a échouée."
	
	sed -i "/phpmyadmin.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne phpmyadmin.$DOMAIN_NAME dans /etc/hosts a échouée."

logs_success "Suppression des lignes des services de /etc/hosts terminée."

#===================================================================#
# 7. Nettoyer les dépendances inutilisées                           #
#===================================================================#
logs_info "Nettoyage des dépendances inutilisées en cours ..."

	sudo apt-get autoremove -y
	error_handler $? "Nettoyage des fichiers résiduels a échoué."

	sudo apt-get autoclean -y
	error_handler $? "Nettoyage les dépendances inutilisées a échoué."

logs_success "Nettoyage des dépendances inutilisées terminée."
#===================================================================#
logs_end "Désinstallation terminée."
