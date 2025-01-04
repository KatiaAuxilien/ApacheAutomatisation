#!/bin/bash

#======================================================================#
source ../.common.sh
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

# Vérification du lancement en droits admin
source ./.common.sh
#TODO : Vérification des variables fournies dans le .env

#===================================================================#
# Prépartion de l'arborescence                                      #
#===================================================================#

logs_info "Services complexes > Mise à jour des paquets en cours ..."
    sudo apt update -y
    error_handler $? "Services complexes > La mise à jour des paquets a échouée."
logs_success "Services complexes > Mise à jour des paquets terminée."

#===================================================================#
# Installation et configuration de PHP                              #
#===================================================================#
# Installer PHP et les extensions couramment utilisées
logs_info "Services complexes > PHP > Installation et configuration en cours ..."

    logs_info "Services complexes > PHP > Installation de php en cours ..."
        sudo apt-get install -y php php-mysql php-xml php-mbstring php-curl php-zip php-gd php-json
        error_handler $? "Services complexes > PHP > L'installation de php-mysql, php-xml, php-mbstring, php-curl, php-zip et php-gd a échouée."
    logs_success "Services complexes > PHP > Installation de php terminée."

    logs_info "Services complexes > PHP > Apache > Redémarrage en cours ..."
        # Redémarrer Apache pour appliquer les changements
        sudo systemctl restart apache2
        error_handler $? "Services complexes > PHP > Apache > Le redémarrage a échouée."
    logs_success "Services complexes > PHP > Apache > Redémarrage en terminé."

    # Vérifier la version de PHP installée
    logs_info "Services complexes > PHP > Vérification en cours ..."
        php -v
        error_handler $? "Services complexes > PHP > L'installation de php a échouée."
    logs_success "Services complexes > PHP > Vérification terminée."

    # logs_info "Services complexes > PHP > Redémarrage en cours ..."
    #     sudo systemctl restart php8.3-fpm
    #     error_handler $? "Services complexes > PHP > L'installation de php a échouée."
    # logs_success "Services complexes > PHP > Redémarrage terminée."

logs_success "Services complexes > PHP > Installation et configuration avancée terminée."