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
# 2. Préparation de l'arborescence                                  #
# 3. Installation de Apache                                         #
# 4. Configuration de Apache                                        #
# 5. Sécurisation de Apache                                         #
# 6. Création des sites                                             #
# 7. Installation et configuration de PHP                           #
# 8. Installation et configuration de mysql                         #
# 9. Installation de PhpMyAdmin                                     #
#===================================================================#

#===================================================================#
source ../.common.sh
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
# 1. Vérifications de l'environnement et des variables              #
#===================================================================#

source ./.common.sh

logs_info "Vérification des services déjà installés ..."

check_phpmyadmin_installed
phpmyadmin_installed=$?

error_count=0

  if [ $apache_installed -eq 1 ]; then
      logs_error "Une installation d'apache existe déjà."
      let error_count++
  fi

  if [ $php_installed -eq 1 ]; then
      logs_error "Une installation de php existe déjà."
      let error_count++
  fi

  if [ $mysql_installed -eq 1 ]; then
      logs_error "Une installation de mysql existe déjà."
      let error_count++
  fi

  if [ $phpmyadmin_installed -eq 1 ]; then
      logs_error "Une installation de phpmyadmin existe déjà."
      let error_count++
  fi

if [ $error_count -ne 0 ];then
    logs_end "Installation annulée."
  exit 1
fi

logs_success "Vérification réussie, les services ne sont pas déjà installés."

#===================================================================#
# 2. Préparation de l'arborescence                                  #
#===================================================================#

logs_info "Mise à jour des paquets en cours ..."

    run_command sudo apt update -y
    error_handler $? "La mise à jour des paquets a échouée."

logs_success "Mise à jour des paquets terminée."

#===================================================================#
# 9. Installation de PhpMyAdmin                                     #
#===================================================================#

logs_info "PhpMyAdmin > Installation et configuration en cours ..."

    # Installer phpMyAdmin
    logs_info "PhpMyAdmin > Installation en cours ..."

        export DEBIAN_FRONTEND="noninteractive"

        run_command sudo apt install -yq phpmyadmin
        error_handler $? "PhpMyAdmin > L'installation a échouée."
        
        sudo debconf-set-selections <<EOF
phpmyadmin phpmyadmin/dbconfig-install boolean true"
phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD
phpmyadmin phpmyadmin/mysql/admin-pass password $DB_ADMIN_PASSWORD
phpmyadmin phpmyadmin/mysql/app-pass password $DB_ADMIN_PASSWORD
phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2
phpmyadmin phpmyadmin/dbconfig-reinstall boolean true
EOF
        run_command sudo dpkg-reconfigure -f noninteractive phpmyadmin
        error_handler $? "PhpMyAdmin > Configuration de l'installation a échouée."

        echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf

    logs_success "PhpMyAdmin > Installation terminée."

logs_end "Script terminée."