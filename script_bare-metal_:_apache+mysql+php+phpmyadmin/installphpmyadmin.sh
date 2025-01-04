#!/bin/bash

#======================================================================#
source ../.common.sh
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
# Installation de PhpMyAdmin                                        #
#===================================================================#

logs_info "Services complexes > PhpMyAdmin > Installation et configuration en cours ..."

    # Installer phpMyAdmin
    logs_info "Services complexes > PhpMyAdmin > Installation en cours ..."
        sudo apt-get install -y phpmyadmin
        error_handler $? "Services complexes > PhpMyAdmin > L'installation a échouée."
    logs_success "Services complexes > PhpMyAdmin > Installation terminée."

    # Configurer phpMyAdmin avec Apache
    logs_info "Services complexes > PhpMyAdmin > Activation du module mbstring en cours ..."
        sudo phpenmod mbstring
        error_handler $? "Services complexes > PhpMyAdmin > Activation du module mbstring a échouée."
    logs_success "Services complexes > PhpMyAdmin > Activation du module terminée."

    # Redémarrer Apache pour appliquer les changements
    logs_info "Services complexes > PhpMyAdmin > Apache > Redémarrage en cours ..."
        sudo systemctl restart apache2
        error_handler $? "Services complexes > PhpMyAdmin > Apache > Le redémarrage a échouée."
    logs_success "Services complexes > PhpMyAdmin > Apache > Redémarrage terminé."

    # Configurer phpMyAdmin pour utiliser la base de données créée
    logs_info "Services complexes > PhpMyAdmin > Configuration basique en cours ..."
        sudo sed -i "s/^.*\$cfg\['Servers'\]\[\$i\]\['auth_type'\] = 'cookie';/\$cfg['Servers'][\$i]['auth_type'] = 'cookie';/" /etc/phpmyadmin/config.inc.php
        error_handler $? "Services complexes > PhpMyAdmin > La configuration de l'authentification a échouée."

        sudo sed -i "s/^.*\$cfg\['Servers'\]\[\$i\]\['user'\] = 'root';/\$cfg['Servers'][\$i]['user'] = 'phpmyadmin';/" /etc/phpmyadmin/config.inc.php
        error_handler $? "Services complexes > PhpMyAdmin > La configuration de l'utilisateur a échouée."

        sudo sed -i "s/^.*\$cfg\['Servers'\]\[\$i\]\['password'\] = '';/\$cfg['Servers'][\$i]['password'] = '$PHPMYADMIN_PASSWORD';/" /etc/phpmyadmin/config.inc.php
        error_handler $? "Services complexes > PhpMyAdmin > La configuration du mot de passe a échouée."
        
        sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
        error_handler $? "Services complexes > PhpMyAdmin > La configuration symlink a échouée."

        sudo a2enconf phpmyadmin.conf
        error_handler $? "Services complexes > PhpMyAdmin > L'activation de la configuration phpmyadmin a échouée."

    logs_success "Services complexes > PhpMyAdmin > Configuration basique terminée."

    # logs_info "Services complexes > PhpMyAdmin > Sécurisation > ."

        # logs_info "Services complexes > PhpMyAdmin > Sécurisation > .htaccess > ."

            # sudo nano /etc/apache2/conf-available/phpmyadmin.conf
            #     AllowOverride All

            # sudo nano /usr/share/phpmyadmin/.htaccess

            # echo "AuthType Basic
            # AuthName "Restricted Files"
            # AuthUserFile /etc/phpmyadmin/.htpasswd
            # Require valid-user" > /usr/share/phpmyadmin/.htaccess
            # error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > a échouée."

            # sudo htpasswd -c /etc/phpmyadmin/.htpasswd username
            # error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > a échouée."

        # logs_success "Services complexes > PhpMyAdmin > Sécurisation > .htaccess > ."

    # logs_success "Services complexes > PhpMyAdmin > Sécurisation > ."

    # Redémarrer PhpMyAdmin pour appliquer les changements
    # logs_info "Services complexes > PhpMyAdmin > Redémarrage en cours ..."
    #     sudo systemctl restart phpmyadmin
    #     error_handler $? "Services complexes > PhpMyAdmin > Le redémarrage a échouée."
    # logs_success "Services complexes > PhpMyAdmin > Redémarrage terminé."

    # Redémarrer Apache pour appliquer les changements
    logs_info "Services complexes > PhpMyAdmin > Apache > Redémarrage en cours ..."
        sudo systemctl reload apache2
        error_handler $? "Services complexes > PhpMyAdmin > Apache > Le redémarrage a échouée."
    logs_success "Services complexes > PhpMyAdmin > Apache > Redémarrage terminé."

echo "127.0.0.1 phpmyadmin.$DOMAIN_NAME" >> /etc/hosts

logs_success "Services complexes > PhpMyAdmin > Installation et configuration avancée terminée."
#===================================================================#