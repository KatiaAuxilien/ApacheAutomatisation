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
# Installation de PhpMyAdmin                                        #
#===================================================================#

logs_info "Services complexes > PhpMyAdmin > Installation et configuration en cours ..."

    # Installer phpMyAdmin
    logs_info "Services complexes > PhpMyAdmin > Installation en cours ..."
        # sudo DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin
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
        
        sudo sed -i "s/^.*\$cfg\['Servers'\]\[\$i\]\['password'\] = '';/\$cfg['Servers'][\$i]['password'] = '$PHPMYADMIN_PASSWORD';/" /etc/phpmyadmin/config.inc.php
        error_handler $? "Services complexes > PhpMyAdmin > La configuration du mot de passe a échouée."
 
        sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
        # error_handler $? "Services complexes > PhpMyAdmin > La création du symlink /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf a échouée."

    logs_success "Services complexes > PhpMyAdmin > Configuration basique terminée."
    logs_info "Services complexes > PhpMyAdmin > Sécurisation > Configuration avancée en cours ..."

    logs_info "Services complexes > PhpMyAdmin > Sécurisation > HTTPS > Génération du certificat et de la clé privée en cours ..."

        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.crt -keyout /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=phpmyadmin.$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
        error_handler $? "Services complexes > Apache > HTTPS > La génération de demande de signature de certifcat du site phpmyadmin.$DOMAIN_NAME a échouée"

        openssl x509 -in /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.crt -text -noout
        error_handler $? "Services complexes > Apache > HTTPS > La vérification du certificat a échouée."
        
        sudo chmod 600 /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.key
        sudo chown root:root /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.crt
        sudo chmod 440 /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.crt

        #Création des Virtual Host
        touch /etc/apache2/sites-available/phpmyadmin.conf
        error_handler $? "Services complexes > Apache > HTTPS > La création du fichier /etc/apache2/sites-available/phpmyadmin.conf a échouée."

    logs_success "Services complexes > PhpMyAdmin > Sécurisation > HTTPS > Génération du certificat et de la clé privée terminée."
    
    logs_info "Services complexes > PhpMyAdmin > Sécurisation > Configuration de la page phpmyadmin.$DOMAIN_NAME en cours ..."

        echo "
Listen $PHPMYADMIN_PORT
<VirtualHost *:80>
  ServerAdmin $WEB_ADMIN_ADDRESS
  erverName phpmyadmin.$DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule ^ https://%{HTTP_HOST}:$PHPMYADMIN_PORT%{REQUEST_URL} [R,L]
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin $WEB_ADMIN_ADDRESS
    DocumentRoot /usr/share/phpmyadmin
    ServerName phpmyadmin.$DOMAIN_NAME

    RewriteEngine On
    RewriteCond %{SERVER_PORT} 443
    RewriteRule ^ https://%{HTTP_HOST}:$PHPMYADMIN_PORT%{REQUEST_URL} [R,L]

    SSLEngine on
    SSLCertificateFile /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.crt
    SSLCertificateKeyFile /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.key

    <Directory /usr/share/phpmyadmin>
        Options -Indexes
        DirectoryIndex index.php
        AllowOverride All
        Require all granted
    </Directory>
 
    ErrorLog ${APACHE_LOG_DIR}/phpmyadmin_error.log
    CustomLog ${APACHE_LOG_DIR}/phpmyadmin_access.log combined
</VirtualHost>

<VirtualHost *:$PHPMYADMIN_PORT>
    ServerAdmin $WEB_ADMIN_ADDRESS
    DocumentRoot /usr/share/phpmyadmin
    ServerName phpmyadmin.$DOMAIN_NAME

    SSLEngine on
    SSLCertificateFile /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.crt
    SSLCertificateKeyFile /etc/apache2/certificate/phpmyadmin."$DOMAIN_NAME"_server.key

    <Directory /usr/share/phpmyadmin>
        Options -Indexes
        DirectoryIndex index.php
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/phpmyadmin_error.log
    CustomLog ${APACHE_LOG_DIR}/phpmyadmin_access.log combined
</VirtualHost>" > /etc/apache2/sites-available/phpmyadmin.conf
        error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > L'écriture du fichier /etc/apache2/sites-available/phpmyadmin.conf a échouée."

        sudo ufw allow $PHPMYADMIN_PORT/tcp
        error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > L'autorisation du port personnalisé pour phpMyAdmin a échouée."
        
        sudo ufw reload
        error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > Le redémarrage du pare-feu a échoué."

        sudo a2ensite phpmyadmin.conf
        error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > Activation du site a échouée."

        echo "127.0.0.1 phpmyadmin.$DOMAIN_NAME" >> /etc/hosts
        error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > L'écriture dans /etc/hosts échouée."

    logs_success "Services complexes > PhpMyAdmin > Sécurisation > Configuration de la page phpmyadmin.$DOMAIN_NAME terminée."
    logs_info "Services complexes > PhpMyAdmin > Sécurisation > .htaccess > Configuration en cours ..."

        sudo touch /usr/share/phpmyadmin/.htaccess
        error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > .htaccess > La création du fichier /usr/share/phpmyadmin/.htaccess a échouée."

        echo "AuthType Basic
AuthName \"Accès protégé\"
AuthUserFile /var/www/.htpasswd
require valid-user
Options -Indexes" > /usr/share/phpmyadmin/.htaccess
        error_handler $? "Services complexes > PhpMyAdmin > Sécurisation > .htaccess > L'écriture dans /usr/share/phpmyadmin/.htaccess a échouée."

    logs_success "Services complexes > PhpMyAdmin > Sécurisation > .htaccess > Configuration terminée."

    logs_success "Services complexes > PhpMyAdmin > Sécurisation > Configuration avancée terminée."

    # Redémarrer Apache pour appliquer les changements
    logs_info "Services complexes > PhpMyAdmin > Apache > Redémarrage en cours ..."

        sudo systemctl reload apache2
        error_handler $? "Services complexes > PhpMyAdmin > Apache > Le redémarrage a échouée."

    logs_success "Services complexes > PhpMyAdmin > Apache > Redémarrage terminé."

logs_end "Services complexes > PhpMyAdmin > Installation et configuration avancée terminée."
#===================================================================#