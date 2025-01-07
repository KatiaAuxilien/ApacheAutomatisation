#!/bin/bash

# .·:'''''''''''''''''''''''''''''''''''''''''''''''''''''''':·.
# : :  ____                       _                          : :
# : : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___            : :
# : : | |_) / _` | '_ ` _ \| '_ \| | | | / __/ __|           : :
# : : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \           : :
# : : |_|   \__,_|_| |_| |_| .__/|_|\__,_|___/___/        _  : :
# : : | |__   __ _ _ __ ___|_|    _ __ ___   ___| |_ __ _| | : :
# : : | '_ \ / _` | '__/ _ \_____| '_ ` _ \ / _ \ __/ _` | | : :
# : : | |_) | (_| | | |  __/_____| | | | | |  __/ || (_| | | : :
# : : |_.__/ \__,_|_|  \___|     |_| |_| |_|\___|\__\__,_|_| : :
# '·:........................................................:·'

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

#===================================================================#
source ./../.common.sh
#===================================================================#

welcome ".·:'''''''''''''''''''''''''''''''''''''''''''''''''''''''':·."
welcome ": :  ____                       _                          : :"
welcome ": : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___            : :"
welcome ": : | |_) / _\` | '_ \` _ \| '_ \| | | | / __/ __|           : :"
welcome ": : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \           : :"
welcome ": : |_|   \__,_|_| |_| |_| .__/|_|\__,_|___/___/        _  : :"
welcome ": : | |__   __ _ _ __ ___|_|    _ __ ___   ___| |_ __ _| | : :"
welcome ": : | '_ \ / _\` | '__/ _ \_____| '_ \` _ \ / _ \ __/ _\` | | : :"
welcome ": : | |_) | (_| | | |  __/_____| | | | | |  __/ || (_| | | : :"
welcome ": : |_.__/ \__,_|_|  \___|     |_| |_| |_|\___|\__\__,_|_| : :"
welcome "'·:........................................................:·'"

#===================================================================#

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

# Demander la confirmation de désinstallation
while true; do
    read -p "Êtes-vous sûr de vouloir lancer la désinstallation ? Tapez 'yes' pour confirmer : " confirmation
    if [[ "$confirmation" =~ ^[yY][eE][sS]$ ]]; then
        break
    else
    		logs_end "Désinstallation annulée."
        exit 0
    fi
done

#===================================================================#
# 1. Vérifications de l'environnement et des variables              #
#===================================================================#

source ./.common.sh

logs_info "Vérification des services installés ..."

check_apache_installed
apache_installed=$?

check_php_installed
php_installed=$?

check_mysql_installed
mysql_installed=$?

check_phpmyadmin_installed
phpmyadmin_installed=$?

error_count=0

  if [ $apache_installed -eq 0 ]; then
      logs_error "Il n'y a pas d'installation d'apache."
	  let error_count++
  fi

  if [ $php_installed -eq 0 ]; then
      logs_error "Il n'y a pas d'installation de php."
	  let error_count++
  fi

  if [ $mysql_installed -eq 0 ]; then
      logs_error "Il n'y a pas d'installation mysql."
	  let error_count++
  fi

  if [ $phpmyadmin_installed -eq 0 ]; then
      logs_error "Il n'y a pas d'installation de phpmyadmin."
	  let error_count++
  fi

if [ $error_count -ne 0 ];then
	logs_end "Désinstallation annulée."
  exit 1
fi

logs_success "Vérification réussie, les services sont installés."

#===================================================================#

logs_info "Désinstallation en cours ..."

#===================================================================#
# 2. Désinstallation de PHP                                         #
#===================================================================#
	logs_info "PHP > Désinstallation en cours ..."

		# Désinstaller PHP et ses extensions
		run_command sudo apt-get remove --purge -y php*
		error_handler $? "PHP > Désinstallation de php* a échouée."

		run_command sudo rm -rf /etc/php
		error_handler $? "PHP > La suppression du dossier /etc/php a échouée."

	logs_success "PHP >  Désinstallation terminée."

#===================================================================#
# 3. Désinstallation de Apache                                      #
#===================================================================#
	logs_info "Apache > Désinstallation en cours ..."

		run_command sudo systemctl stop apache2
		error_handler $? "Apache > L'arrêt du service apache a échouée."

		run_command sudo systemctl disable apache2
		error_handler $? "Apache > La désactivation d'apache a échouée."

		# Désinstaller Apache
		run_command sudo apt-get remove --purge -y apache2*
		error_handler $? "Apache > Désinstallation de apache2* a échouée."

		run_command sudo rm -rf /etc/apache2
		error_handler $? "Apache > La suppression du dossier /etc/apache2 a échouée."

		run_command sudo rm -rf /var/www/html
		error_handler $? "Apache > La suppression du dossier /var/www/html a échouée."

		run_command sudo rm -rf /var/www/siteA
		error_handler $? "Apache > La suppression du dossier /var/www/siteA"

		run_command sudo rm -rf /var/www/siteB
		error_handler $? "Apache > La suppression du dossier /var/www/siteB"
		
		run_command sudo rm -rf /var/log/mod_evasive
		error_handler $? "Apache > La suppression du dossier /var/log/mod_evasive"

		# run_command sudo apt remove --purge -y libapache2-mod-security2
		# error_handler $? "Apache > La désinstallation de libapache2-mod-security2 a échouée."
		
		# run_command sudo apt remove --purge -y libapache2-mod-evasive 
		# error_handler $? "Apache > La désinstallation de libapache2-mod-evasive a échouée."
		
		# run_command sudo apt remove --purge -y ssl-cert
		# error_handler $? "Apache >  a échouée."

	logs_success "Apache > Désinstallation terminée."

#===================================================================#
# 4. Désinstallation de mysql                                       #
#===================================================================#
	logs_info "MySQL >  Désinstallation en cours ..."

		# Désinstaller MySQL
		run_command sudo apt-get remove --purge -y mysql-server*
		error_handler $? "MySQL > Désinstallation de mysql-server* a échouée."

		run_command sudo rm -rf /etc/mysql
		error_handler $? "MySQL > La suppression du dossier /etc/mysql a échouée."

		run_command sudo rm -rf /var/lib/mysql
		error_handler $? "MySQL > La suppression du dossier /var/lib/mysql a échouée."

		run_command sudo rm -rf /var/log/mysql
		error_handler $? "MySQL > La suppression du dossier /var/log/mysql a échouée."

	logs_success "MySQL >  Désinstallation terminée."

#===================================================================#
# 5. Désinstallation de PhpMyAdmin                                  #
#===================================================================#
	logs_info "PhpMyAdmin >  Désinstallation en cours ..."
		
		export DEBIAN_FRONTEND="noninteractive"

		# Désinstaller phpMyAdmin
		run_command sudo apt-get remove --purge -yq phpmyadmin
		error_handler $? "PhpMyAdmin > La désinstallation de phpmyadmin* a échouée."

		run_command sudo apt-get purge -y phpmyadmin
		error_handler $? "PhpMyAdmin > La suppression des fichiers résiduels a échouée."

		run_command sudo apt-get remove -y phpmyadmin
		error_handler $? "PhpMyAdmin > La suppression des dépendances inutilisées a échouée."

		run_command sudo rm -rf /etc/phpmyadmin /usr/share/phpmyadmin /var/lib/phpmyadmin
		error_handler $? "PhpMyAdmin > La suppression des dossiers /etc/phpmyadmin /usr/share/phpmyadmin /var/lib/phpmyadmin a échouée."

		run_command sudo rm  -rf /etc/apache2/conf-available/phpmyadmin.conf
		error_handler $? "PhpMyAdmin > La suppression du fichier /etc/apache2/conf-available/phpmyadmin.conf a échouée."

		run_command sudo rm  -rf /etc/apache2/sites-available/phpmyadmin.conf
		error_handler $? "PhpMyAdmin > La suppression du fichier /etc/apache2/sites-available/phpmyadmin.conf a échouée."

	logs_success "PhpMyAdmin >  Désinstallation terminée."
#===================================================================#
# 6. Effacer les lignes /etc/hosts                                  #
#===================================================================#
logs_info "Suppression des lignes des services de /etc/hosts en cours ..."
	run_command sed -i "/$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne $DOMAIN_NAME dans /etc/hosts a échouée."
	
	run_command sed -i "/siteA.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne siteA.$DOMAIN_NAME dans /etc/hosts a échouée."
	
	run_command sed -i "/siteB.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne siteB.$DOMAIN_NAME dans /etc/hosts a échouée."
	
	run_command sed -i "/phpmyadmin.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne phpmyadmin.$DOMAIN_NAME dans /etc/hosts a échouée."

logs_success "Suppression des lignes des services de /etc/hosts terminée."

#===================================================================#
# 7. Nettoyer les dépendances inutilisées                           #
#===================================================================#
logs_info "Nettoyage des dépendances inutilisées en cours ..."

	run_command sudo apt-get autoremove -y
	error_handler $? "Nettoyage des fichiers résiduels a échoué."

	run_command sudo apt-get autoclean -y
	error_handler $? "Nettoyage les dépendances inutilisées a échoué."

logs_success "Nettoyage des dépendances inutilisées terminée."
#===================================================================#
logs_end "Désinstallation terminée."
