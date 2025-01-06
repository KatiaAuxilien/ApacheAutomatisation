#!/bin/bash

# .·:'''''''''''''''''''''''''''''''''''''''''''''':·.
# : :  ____                       _                : :
# : : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___  : :
# : : | |_) / _` | '_ ` _ \| '_ \| | | | / __/ __| : :
# : : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \ : :
# : : |_|  _\__,_|_| |_|_|_| .__/|_|\__,_|___/___/ : :
# : :   __| | ___   ___| | |_|__ _ __              : :
# : :  / _` |/ _ \ / __| |/ / _ \ '__|             : :
# : : | (_| | (_) | (__|   <  __/ |                : :
# : :  \__,_|\___/ \___|_|\_\___|_|                : :
# '·:..............................................:·'

#===================================================================#
#                            Sommaire                               #
#===================================================================#
# 1. Vérifications de l'environnement et des variables              #
# 2. Préparation de l'arborescence                                  #
# 3. Préparation pour docker                                        #
# 4. Installation de PhpMyAdmin et mysql                            #
# 5. Configuration de PhpMyAdmin                                    #
# 6. Configuration de mysql                                         #
# 7. Installation de Apache (+ des modules) et PHP                  #
# 8. Configuration de PHP                                           #
# 9. Configuration de Apache                                        #
# 10. Sécurisation de Apache                                        #
# 11. Lancement des services                                        #
# 12. Lancement du script d'initialisation de mysql                 #
# 13. Nettoyage                                                     #
# 14. Affichage des adresses IP des conteneurs                      #
# 15. Création d'un script de gestion des services                  #
#===================================================================#

#===================================================================#
source ../.common.sh
#===================================================================#

welcome ".·:'''''''''''''''''''''''''''''''''''''''''''''':·."
welcome ": :  ____                       _                : :"
welcome ": : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___  : :"
welcome ": : | |_) / _\` | '_ \` _ \| '_ \| | | | / __/ __| : :"
welcome ": : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \ : :"
welcome ": : |_|  _\__,_|_| |_|_|_| .__/|_|\__,_|___/___/ : :"
welcome ": :   __| | ___   ___| | |_|__ _ __              : :"
welcome ": :  / _\` |/ _ \ / __| |/ / _ \ '__|             : :"
welcome ": : | (_| | (_) | (__|   <  __/ |                : :"
welcome ": :  \__,_|\___/ \___|_|\_\___|_|                : :"
welcome "'·:..............................................:·'"

#===================================================================#

required_vars_start=(
"DOMAIN_NAME"
"NETWORK_NAME"
"WEB_CONTAINER_NAME"
"WEB_ADMIN_ADDRESS"
"WEB_PORT"
"WEB_ADMIN_USER"
"WEB_ADMIN_PASSWORD"
"SSL_KEY_PASSWORD"
"WEB_HTACCESS_PASSWORD"

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
"DB_VOLUME_NAME"
)

#===================================================================#
# 1. Vérifications de l'environnement et des variables              #
#===================================================================#

source ./.common.sh

logs_info "Vérification des services déjà installés ..."

error_count=0

  if [ $mysql_installed -eq 1 ]; then
      logs_error "Un conteneur avec l'image bitnami/mysql existe déjà."
      let error_count++
  fi

  if [ $phpmyadmin_installed -eq 1 ]; then
      logs_error "Un conteneur avec l'image phpmyadmin/phpmyadmin existe déjà."
      let error_count++
  fi

  if [ $apache_installed -eq 1 ]; then
      logs_error "Un conteneur avec l'image debian existe déjà."
      let error_count++
  fi

  if [ $db_container_name_exists -eq 1 ]; then
      logs_error "Un conteneur avec le nom $DB_CONTAINER_NAME existe déjà."
      let error_count++
  fi

  if [ $phpmyadmin_container_name_exists -eq 1 ]; then
      logs_error "Un conteneur avec le nom $PHPMYADMIN_CONTAINER_NAME existe déjà."
      let error_count++
  fi

  if [ $web_container_name_exists -eq 1 ]; then
      logs_error "Un conteneur avec le nom $WEB_CONTAINER_NAME existe déjà."
      let error_count++
  fi

if [ $error_count -ne 0 ];then
  exit 1
fi

logs_success "Vérification réussie, les services ne sont pas déjà installés."

#===================================================================#
# 2. Préparation de l'arborescence                                  #
#===================================================================#

logs_info "Préparation de l'arborescence en cours ..."

  run_command mkdir apache apache/www mysql
  error_handler $? "La création des dossiers a échouée."

  run_command chmod -R 755 apache
  error_handler $? "L'attribution des droits au dosser apache a échouée."

  run_command chmod -R 755 apache/www
  error_handler $? "L'attribution des droits au dossier apache/www a échouée."

  run_command chmod -R 755 mysql
  error_handler $? "L'attribution des droits au dossier mysql a échouée."

logs_success "Préparation de l'arborescence terminée."

#===================================================================#
# 3. Préparation pour docker                                        #
#===================================================================#

logs_info "Docker > Préparation de docker en cours ..."

  run_command sudo docker network create $NETWORK_NAME --driver bridge
  error_handler $? "Docker > La création du réseau docker $NETWORK_NAME a échouée."

  run_command touch docker-compose.yml
  error_handler $? "Docker > La création du fichier docker-compose.yml a échouée."

  run_command chmod -R 755 docker-compose.yml
  error_handler $? "Docker > L'attribution des droits fichier docker-compose.ym a échouée."

logs_success "Docker > Préparation de docker terminée."

#===================================================================#
# 4. Installation de PhpMyAdmin et mysql                            #
#===================================================================#

logs_info "Docker > Préparation de la configuration du docker-compose.yml pour PhpMyAdmin et mysql en cours ..."

  run_command echo "services:
  $DB_CONTAINER_NAME:
    image: bitnami/mysql:latest
    container_name: $DB_CONTAINER_NAME
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_ADMIN_USERNAME
      MYSQL_PASSWORD: $DB_ADMIN_PASSWORD
      MYSQL_PORT_NUMBER: $DB_PORT
    ports:
      - "$DB_PORT:3306"
    volumes:
      - $DB_VOLUME_NAME:/bitnami/mysql/data/
    networks:
      - $NETWORK_NAME

  $PHPMYADMIN_CONTAINER_NAME:
    image: phpmyadmin/phpmyadmin
    container_name: $PHPMYADMIN_CONTAINER_NAME
    restart: always
    environment:
      PMA_HOST: $DB_CONTAINER_NAME
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      PMA_PORT: $DB_PORT
    ports:
      - "$PHPMYADMIN_PORT:$PHPMYADMIN_PORT"
    networks:
      - $NETWORK_NAME

volumes:
  $DB_VOLUME_NAME:

networks:
  $NETWORK_NAME:
    external: true" > docker-compose.yml
  error_handler $? "Docker > L'écriture du fichier docker-compose.yml a échouée."

logs_success "Docker > La préparation de la configuration du docker-compose.yml pour PhpMyAdmin et mysql est terminée."

#===================================================================#
# 5. Configuration de PhpMyAdmin                                    #
#===================================================================#

# logs_info "PhpMyAdmin > Préparation de la configuration en cours ..."
#TODO : Configurer PhpMyAdmin pour le TLS. (Page en HTTPS + .htaccess + modevasive + modsecurity)
# logs_success "PhpMyAdmin > Préparation de la configuration terminée."

#===================================================================#
# 6. Configuration de mysql                                         #
#===================================================================#

logs_info "mysql > Préparation de la requête d'initialisation de la base de données en cours ..."

# Créer une base de données d'intro
  DB_INIT_SQL_QUERIES=$(cat <<EOF
CREATE TABLE IF NOT EXISTS todo_list
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    content VARCHAR(255) NOT NULL,
    statut INT DEFAULT 0
);

INSERT INTO todo_list (content, statut) VALUES
('Sécuriser le site A.',0),
('Sécuriser le site B.',0),
('Créer une page secrète.',1),
('Faire fonctionner les services php, phpmyadmin, mysql et apache.',2);
EOF
)

logs_success "mysql > La préparation de la requête d'initialisation de la base de données est terminée."

#===================================================================#
# 7. Installation de Apache (+ des modules) et PHP                  #
#===================================================================#

logs_info "Apache & PHP > Préparation de la configuration d'installation en cours ..."

  run_command touch apache/Dockerfile
  error_handler $? "Apache & PHP > La création du fichier apache/Dockerfile a échouée."

  run_command echo "FROM debian:latest
RUN apt update -y
RUN apt-get install -y apache2 apache2-utils
RUN apt-get install -y php libapache2-mod-php php-mysql
RUN apt-get install -y libapache2-mod-security2 libapache2-mod-evasive openssl ssl-cert
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

EXPOSE $WEB_PORT
EXPOSE 443

COPY www/ /var/www/
COPY apache2.conf /etc/apache2/apache2.conf
COPY 000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY ports.conf /etc/apache2/ports.conf

RUN mkdir -p /etc/apache2/certificate/
COPY certificate/ /etc/apache2/certificate/

# RUN a2enmod php8.3
RUN a2enmod headers

# ModRewrite
RUN a2enmod rewrite

# SSL
RUN a2enmod ssl
RUN a2ensite default-ssl
RUN openssl req -subj '/CN=example.com/O=My Company Name LTD./C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem

# ModSecurity ModSecurity-crs
COPY mods/modsecurity.conf /etc/modsecurity/modsecurity.conf
COPY mods/security2.conf /etc/apache2/mods-enabled/security2.conf
COPY mods/modsecurity-crs /etc/apache2/modsecurity-crs
RUN a2enmod security2

#ModEvasive
COPY mods/evasive.conf /etc/apache2/mods-enabled/evasive.conf
RUN a2enmod evasive

#ModRateLimit

# htaccess
COPY .htpasswd /var/www/.htpasswd

# Configuration des sites
COPY sites-available/siteA.conf /etc/apache2/sites-available/siteA.conf
COPY sites-available/siteB.conf /etc/apache2/sites-available/siteB.conf
RUN a2ensite siteA.conf
RUN a2ensite siteB.conf


CMD [\"apache2ctl\",\"-D\",\"FOREGROUND\"]" > apache/Dockerfile
  error_handler $? "Apache & PHP > L'écriture dans le fichier apache/Dockerfile a échouée."

logs_success "Apache & PHP > Préparation de la configuration d'installation terminée."

#===================================================================#
# 8. Configuration de PHP                                           #
#===================================================================#

# logs_info "PHP > Préparation de la configuration en cours ..."

# logs_success "PHP > Préparation de la configuration terminée."

#===================================================================#
# 9. Configuration de Apache                                        #
#===================================================================#

logs_info "Apache > Préparation de la configuration en cours ..."

  run_command touch apache/apache2.conf
  error_handler $? "Apache > La création du fichier apache/apache2.conf a échouée."

  run_command chmod -R 755 apache/apache2.conf
  error_handler $? "Apache > L'attribution des droits sur le fichier apache/apache2.conf a échouée."

  run_command echo "ServerRoot \"/etc/apache2\"

ServerName $DOMAIN_NAME

ServerAdmin $WEB_ADMIN_ADDRESS

#Mutex file:\${APACHE_LOCK_DIR} default

DefaultRuntimeDir \${APACHE_RUN_DIR}

PidFile \${APACHE_PID_FILE}

Timeout 300

KeepAlive On

MaxKeepAliveRequests 100

KeepAliveTimeout 5

User \${APACHE_RUN_USER}
Group \${APACHE_RUN_GROUP}

HostnameLookups Off

ErrorLog \${APACHE_LOG_DIR}/error.log

LogLevel warn

IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf

Include ports.conf

<Directory />
    Options FollowSymLinks
    AllowOverride None
    Require all denied
</Directory>

<Directory /usr/share>
    AllowOverride None
    Require all granted
</Directory>

<Directory /var/www/>
    Options -Indexes
    AllowOverride All
    Require all granted
</Directory>

AccessFileName .htaccess

<FilesMatch "^\.ht">
    Require all denied
</FilesMatch>


LogFormat \"%v:%p %h %l %u %t \\\"%r\\\" %>s %O \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\"\" vhost_combined
LogFormat \"%h %l %u %t \\\"%r\\\" %>s %O \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\"\" combined
LogFormat \"%h %l %u %t \\\"%r\\\" %>s %O\" common
LogFormat \"%{Referer}i -> %U\" referer
LogFormat \"%{User-agent}i\" agent

IncludeOptional conf-enabled/*.conf

IncludeOptional sites-enabled/*.conf" > apache/apache2.conf
  error_handler $? "Apache > L'écriture du fichier de configuration apache/apache2.conf a échouée."

# Configuration du port par défaut & HTTPS
  logs_info "Apache > Page d'accueil > Préparation de la configuration en cours ..."

    CERT_NAME="servicescomplexe"

    run_command touch apache/000-default.conf
    error_handler $? "Apache > Page d'accueil > La création du fichier apache/000-default.conf a échouée."

    run_command echo "<VirtualHost *:80>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]
</VirtualHost>

<VirtualHost *:443>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{SERVER_PORT} 443
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$CERT_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$CERT_NAME"_server.key

  <Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<VirtualHost *:$WEB_PORT>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $DOMAIN_NAME

  DocumentRoot /var/www/html

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$CERT_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$CERT_NAME"_server.key

  <Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" > apache/000-default.conf
    error_handler $? "Apache > Page d'accueil > L'écriture dans le fichier apache/000-default.conf a échouée."

    run_command touch apache/ports.conf
    error_handler $? "Apache > Page d'accueil > La création du fichier apache/ports.conf a échouée."

    run_command echo "
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen $WEB_PORT

<IfModule ssl_module>
  Listen 443
</IfModule>

<IfModule mod_gnutls.c>
  Listen 443
</IfModule>" > apache/ports.conf
    error_handler $? "Apache > Page d'accueil > L'écriture dans le fichier apache/ports.conf a échouée."

# Création de la page principale
    run_command mkdir apache/www/html/
    error_handler $? "Apache > Page d'accueil > La création du dossier apache/www/html/ a échouée."
    
    run_command touch apache/www/html/index.html
    error_handler $? "Apache > Page d'accueil > La création du fichier apache/www/html/index.html a échouée."
    
    run_command chmod -R 755 apache/www/html/index.html
    error_handler $? "Apache > Page d'accueil > L'attribution des droits au fichier apache/www/html/index.html a échouée."

    run_command echo "<!DOCTYPE html>
<html>
  <head>
    <title>Accueil de $DOMAIN_NAME</title>
    <meta charset=\"utf-8\"/>
    <style>
body{
  background-color: #C6E7FF;
  font-family: Avantgarde, TeX Gyre Adventor, URW Gothic L, sans-serif;
}
      </style>
  </head>
  <body>
    <h1>Bienvenue sur $DOMAIN_NAME ! 👋</h1>
    <p> ✨ <a href=\"https://siteA.$DOMAIN_NAME:$WEB_PORT\">Visiter siteA.$DOMAIN_NAME</a> </p>
    <p> ✨ <a href=\"https://siteB.$DOMAIN_NAME:$WEB_PORT\">Visiter siteB.$DOMAIN_NAME</a> </p>
  </body>
</html> " > apache/www/html/index.html
    error_handler $? "Apache > Page d'accueil > L'écriture du fichier apache/www/html/index.html a échouée."

  logs_success "Apache > Page d'accueil > Préparation de la configuration en terminée."
  
# Configuration du .htaccess
  logs_info "Apache > Sécurisation > .htaccess > Préparation de la configuration en cours ..."

    run_command sudo apt install -y apache2-utils
    error_handler $? "Apache > Sécurisation > .htaccess > L'installation de apache2-utils a échouée."

    run_command touch apache/.htpasswd
    error_handler $? "Apache > Sécurisation > .htaccess > La création du fichier apache/.htpasswd a échouée."

    run_command sudo htpasswd -b apache/.htpasswd admin $WEB_HTACCESS_PASSWORD
    error_handler $? "Apache > Sécurisation > .htaccess > L'ajout d'un utilisateur admin dans le fichier apache/.htpasswd a échouée."

  logs_info "Apache > Sécurisation > .htaccess > Préparation de la configuration terminée."
# Installation d'openssl
  logs_info "Apache > Sécurisation > HTTPS > Génération du certificat et de la clé en cours ..."

    run_command sudo apt-get install -y openssl
    error_handler $? "Apache > Sécurisation > HTTPS > L'installation d'openssl a échouée."

# Génération du certificat et de la clé pour le HTTPS

    run_command mkdir apache/certificate
    error_handler $? "Apache > Sécurisation > HTTPS > La création du dossier /apache/certificate a échouée."

    run_command sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out apache/certificate/"$CERT_NAME"_server.crt -keyout apache/certificate/"$CERT_NAME"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
    error_handler $? "Apache > Sécurisation > HTTPS > La génération de demande de signature de certificat a échouée."

    run_command openssl x509 -in apache/certificate/"$CERT_NAME"_server.crt -text -noout
    error_handler $? "Apache > Sécurisation > HTTPS > La vérification du certificat a échouée."

    run_command sudo chmod 600 apache/certificate/"$CERT_NAME"_server.key
    error_handler $? "Apache > Sécurisation > HTTPS > L'attribution des droits au fichier apache/certificate/"$CERT_NAME"_server.key a échouée."

    run_command sudo chown root:root apache/certificate/"$CERT_NAME"_server.crt
    error_handler $? "Apache > Sécurisation > HTTPS > L'attribution des droits au fichier apache/certificate/"$CERT_NAME"_server.crt a échouée."

    run_command sudo chmod 440 apache/certificate/"$CERT_NAME"_server.crt
    error_handler $? "Apache > Sécurisation > HTTPS > L'attribution des droits au fichier apache/certificate/"$CERT_NAME"_server.crt a échouée."

  logs_success "Apache > Sécurisation > HTTPS > Génération du certificat et de la clé terminée."

logs_info "Apache > Sites > Préparation de la configuration en cours ..."
# Création de deux sites (siteA, siteB)
  run_command mkdir apache/sites-available
  error_handler $? "Apache > Sites > La création du dossier apache/sites-available a échouée."

    for site_name in siteA siteB
    do
      logs_info "Apache > Sites > $site_name > Création du site $site_name en cours ..."
        
        run_command mkdir apache/www/$site_name
        error_handler $? "Apache > Sites > $site_name > La création du dossier apache/www/$site_name a échouée."

        run_command chmod -R 755 apache/www/$site_name
        error_handler $? "Apache > Sites > $site_name > L'attribution des droits sur le dossier www/$site_name a échouée."
        
        run_command sudo touch apache/www/$site_name/index.html
        error_handler $? "Apache > Sites > $site_name > La création du fichier apache/www/$site_name/index.html a échouée."

        run_command echo "<!DOCTYPE html>
<html>
    <head>
        <title>$site_name</title>
        <meta charset=\"utf-8\"/>
    <style>
body{
  background-color: #C6E7FF;
  font-family: Avantgarde, TeX Gyre Adventor, URW Gothic L, sans-serif;
}
      </style>
    </head>
    <body>
      <h1>Bienvenue sur le " $site_name " ! 👋</h1>
        <h2> N'allez pas sur l'autre site, ce site est malveillant !</h2>
        <a href=\"https://$site_name.$DOMAIN_NAME:79/confidential/confidential.php\"><h2> Page confidentiel ici</h2></a>
    </body>
</html>" > apache/www/$site_name/index.html
        error_handler $? "Apache > Sites > $site_name > L'écriture dans le fichier apache/www/$site_name/index.html a échouée."

        run_command sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt -keyout apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$site_name.$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
        error_handler $? "Apache > Sites > $site_name > La génération de demande de signature de certifcat du site $site_name a échouée"

        run_command openssl x509 -in apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt -text -noout
        error_handler $? "Apache > Sites > $site_name > La vérification du certificat a échouée."
        
        run_command sudo chmod 600 apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.key
        error_handler $? "Apache > Sites > $site_name > L'attribution des droits au fichier apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.key a échouée."

        run_command sudo chown root:root apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt
        error_handler $? "Apache > Sites > $site_name > L'attribution des droits au fichier apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt a échouée."

        run_command sudo chmod 440 apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt
        error_handler $? "Apache > Sites > $site_name > L'attribution des droits au fichier apache/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt a échouée."

        #Création des Virtual Host
        run_command touch apache/sites-available/$site_name.conf
        error_handler $? "Apache > Sites > $site_name > La création du fichier apache/sites-available/$site_name.conf a échouée."

        run_command echo "
<VirtualHost *:80>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $site_name.$DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]
</VirtualHost>

<VirtualHost *:443>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $site_name.$DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{SERVER_PORT} 443
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.key

  <Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/$site_name-error.log
  CustomLog \${APACHE_LOG_DIR}/$site_name-access.log combined
</VirtualHost>

<VirtualHost *:$WEB_PORT>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $site_name.$DOMAIN_NAME

  DocumentRoot /var/www/$site_name

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.key

  <Directory /var/www/$site_name>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/$site_name-error.log
  CustomLog \${APACHE_LOG_DIR}/$site_name-access.log combined
</VirtualHost>" > apache/sites-available/$site_name.conf
        error_handler $? "Apache > Sites > $site_name > L'écriture du fichier apache/sites-available/$site_name.conf a échouée."

  logs_success "Apache > Sites > $site_name > Création du site $site_name terminée."
# Création de la page confidentielle
  logs_info "Apache > Sites > $site_name > .htaccess > Création de la page confidentielle en cours ..."

        run_command mkdir apache/www/$site_name/confidential
        error_handler $? "Apache > Sites > $site_name > .htaccess > La création du dossier apache/www/$site_name/confidential a échouée."
        
        run_command chmod -R 755 apache/www/$site_name/confidential
        error_handler $? "Apache > Sites > $site_name > .htaccess > L'attribution des droits sur le dossier apache/www/$site_name/confidential a échouée."

        run_command touch apache/www/$site_name/confidential/confidential.php
        error_handler $? "Apache > Sites > $site_name > .htaccess > La création du fichier apache/www/$site_name/confidential/confidential.php a échouée."
        
        run_command chmod -R 755 apache/www/$site_name/confidential/confidential.php
        error_handler $? "Apache > Sites > $site_name > .htaccess > L'attribution des droits sur le dossier apache/www/$site_name/confidential/confidential.php a échouée."

        run_command echo "<!DOCTYPE html>
<html>
    <head>
        <title>Page protégée du site $site_name</title>
        <meta charset=\"utf-8\"/>
    </head>
    <style>
body{
  background-color: #C6E7FF;
  font-family: Avantgarde, TeX Gyre Adventor, URW Gothic L, sans-serif;
}
table {
  width: 100%;
  border: 1px solid;
}
.todo{
  background-color: #B06161;
  text-align: center;

}
.inprogess{
  background-color: #FFCF9D;
  text-align: center;
}
.done{
  background-color: #D0E8C5;
  text-align: center;
}
      </style>
      <script>

      </script>
    <body>
        <h1> TOP SECRET </h1>
<?php
    \$user = \""$DB_ADMIN_USERNAME"\";
    \$password = \""$DB_ADMIN_PASSWORD"\";
    \$database = \""$DB_NAME"\";
    \$table = \"todo_list\";


    \$session = new mysqli(\"$DB_CONTAINER_NAME\",\$user,\$password, \$database, $DB_PORT);

    if (\$session->connect_error)
    {
      die(\"Connection failed: \" . \$session->connect_error);
    }
    
    \$sql = \"SELECT * FROM \$table\";
    \$result = \$session->query(\$sql);

    echo \"<h2>Liste de tâches à faire</h2>\";

    echo \"<table>
    <tr> 
      <th>Tâche</th>
      <th>Statut</th>
    </tr>\";

    if (\$result->num_rows > 0) 
    {
       while( \$row = \$result->fetch_assoc() )
       { \$statut = \"\";
         if( \$row[\"statut\"] == 0 )
         { \$statut = \"<td class="todo"> A faire </td>\";
         }
         if( \$row[\"statut\"] == 1 )
         { \$statut = \"<td class="inprogess"> En cours </td>\";
         }
         if( \$row[\"statut\"] == 2 )
         { \$statut = \"<td class="done"> Fait </td>\";
         }

         echo \"<tr><td>\" . \$row[\"content\"] . \"</td>\" . \$statut . \"</tr>\";
       }
    } 
    else 
    {
      echo \"0 results\";
    }

    echo \"</table>\";
    \$session->close();

?>
    </body>
</html>" > apache/www/$site_name/confidential/confidential.php
        error_handler $? "Apache > Sites > $site_name > .htaccess > L'écriture dans le fichier apache/www/$site_name/confidential/confidential.php a échouée."

# Configuration de la page confidentielle (.htaccess et .htpasswd)

        run_command touch apache/www/$site_name/confidential/.htaccess
        error_handler $? "Apache > Sites > $site_name > .htaccess > La création du fichier apache/www/$site_name/confidential/.htaccess a échouée."

        run_command echo "AuthType Basic
        AuthName \"Accès protégé\"
        AuthUserFile /var/www/.htpasswd
        require valid-user
        Options -Indexes" > apache/www/$site_name/confidential/.htaccess
        error_handler $? "Apache > Sites > $site_name > .htaccess > L'écriture du fichier apache/www/$site_name/confidential/.htaccess a échouée."
  
      logs_success "Apache > Sites > $site_name > .htaccess > Création de la page confidentielle terminée."
    done
logs_success "Apache > Sites > Préparation de la configuration terminée."

#===================================================================#
# 10. Sécurisation de Apache                                        #
#===================================================================#

logs_info "Apache > Sécurisation > Préparation de la configuration avancée en cours ..."

  run_command mkdir apache/mods
  error_handler $? "Apache > Sécurisation > La création du dossier apache/mods a échouée."

# Sécurisation - Installation et configuration de ModSecurity
  logs_info "Apache > Sécurisation > ModSecurity > Préparation de la configuration en cours ..."

    run_command touch apache/mods/modsecurity.conf
    error_handler $? "Apache > Sécurisation > ModSecurity > La création du fichier apache/mods/modsecurity.conf a échoué."

    run_command echo "
# -- Rule engine initialization ----------------------------------------------

# Enable ModSecurity, attaching it to every transaction. Use detection
# only to start with, because that minimises the chances of post-installation
# disruption.
#
SecRuleEngine On


# -- Request body handling ---------------------------------------------------

# Allow ModSecurity to access request bodies. If you don't, ModSecurity
# won't be able to see any POST parameters, which opens a large security
# hole for attackers to exploit.
#
SecRequestBodyAccess On


# Enable XML request body parser.
# Initiate XML Processor in case of xml content-type
#
SecRule REQUEST_HEADERS:Content-Type \"^(?:application(?:/soap\+|/)|text/)xml\" \\
     \"id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML\"

# Enable JSON request body parser.
# Initiate JSON Processor in case of JSON content-type; change accordingly
# if your application does not use 'application/json'
#
SecRule REQUEST_HEADERS:Content-Type \"^application/json\" \\
     \"id:'200001',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON\"

# Sample rule to enable JSON request body parser for more subtypes.
# Uncomment or adapt this rule if you want to engage the JSON
# Processor for \"+json\" subtypes
#
#SecRule REQUEST_HEADERS:Content-Type \"^application/[a-z0-9.-]+[+]json\" \\
#     \"id:'200006',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON\"

# Maximum request body size we will accept for buffering. If you support
# file uploads then the value given on the first line has to be as large
# as the largest file you are willing to accept. The second value refers
# to the size of data, with files excluded. You want to keep that value as
# low as practical.
#
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072

# Store up to 128 KB of request body data in memory. When the multipart
# parser reaches this limit, it will start using your hard disk for
# storage. That is slow, but unavoidable.
#
SecRequestBodyInMemoryLimit 131072

# What do do if the request body size is above our configured limit.
# Keep in mind that this setting will automatically be set to ProcessPartial
# when SecRuleEngine is set to DetectionOnly mode in order to minimize
# disruptions when initially deploying ModSecurity.
#
SecRequestBodyLimitAction Reject

# Maximum parsing depth allowed for JSON objects. You want to keep this
# value as low as practical.
#
SecRequestBodyJsonDepthLimit 512

# Verify that we've correctly processed the request body.
# As a rule of thumb, when failing to process a request body
# you should reject the request (when deployed in blocking mode)
# or log a high-severity alert (when deployed in detection-only mode).
#
SecRule REQBODY_ERROR \"!@eq 0\" \\
\"id:'200002', phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2\"

# By default be strict with what we accept in the multipart/form-data
# request body. If the rule below proves to be too strict for your
# environment consider changing it to detection-only. You are encouraged
# _not_ to remove it altogether.
#
SecRule MULTIPART_STRICT_ERROR \"!@eq 0\" \\
\"id:'200003',phase:2,t:none,log,deny,status:400, \\
msg:'Multipart request body failed strict validation: \\
PE %{REQBODY_PROCESSOR_ERROR}, \\
BQ %{MULTIPART_BOUNDARY_QUOTED}, \\
BW %{MULTIPART_BOUNDARY_WHITESPACE}, \\
DB %{MULTIPART_DATA_BEFORE}, \\
DA %{MULTIPART_DATA_AFTER}, \\
HF %{MULTIPART_HEADER_FOLDING}, \\
LF %{MULTIPART_LF_LINE}, \\
SM %{MULTIPART_MISSING_SEMICOLON}, \\
IQ %{MULTIPART_INVALID_QUOTING}, \\
IP %{MULTIPART_INVALID_PART}, \\
IH %{MULTIPART_INVALID_HEADER_FOLDING}, \\
FL %{MULTIPART_FILE_LIMIT_EXCEEDED}'\"

# Did we see anything that might be a boundary?
#
SecRule MULTIPART_UNMATCHED_BOUNDARY \"!@eq 0\" \\
\"id:'200004',phase:2,t:none,log,deny,msg:'Multipart parser detected a possible unmatched boundary.'\"

# PCRE Tuning
# We want to avoid a potential RegEx DoS condition
#
SecPcreMatchLimit 100000
SecPcreMatchLimitRecursion 100000

# Some internal errors will set flags in TX and we will need to look for these.
# All of these are prefixed with \"MSC_\".  The following flags currently exist:
#
# MSC_PCRE_LIMITS_EXCEEDED: PCRE match limits were exceeded.
#
SecRule TX:/^MSC_/ \"!@streq 0\" \\
        \"id:'200005',phase:2,t:none,deny,msg:'ModSecurity internal error flagged: %{MATCHED_VAR_NAME}'\"


# -- Response body handling --------------------------------------------------

# Allow ModSecurity to access response bodies. 
# You should have this directive enabled in order to identify errors
# and data leakage issues.
# 
# Do keep in mind that enabling this directive does increases both
# memory consumption and response latency.
#
SecResponseBodyAccess On

# Which response MIME types do you want to inspect? You should adjust the
# configuration below to catch documents but avoid static files
# (e.g., images and archives).
#
SecResponseBodyMimeType text/plain text/html text/xml

# Buffer response bodies of up to 512 KB in length.
SecResponseBodyLimit 524288

# What happens when we encounter a response body larger than the configured
# limit? By default, we process what we have and let the rest through.
# That's somewhat less secure, but does not break any legitimate pages.
#
SecResponseBodyLimitAction ProcessPartial


# -- Filesystem configuration ------------------------------------------------

# The location where ModSecurity stores temporary files (for example, when
# it needs to handle a file upload that is larger than the configured limit).
# 
# This default setting is chosen due to all systems have /tmp available however, 
# this is less than ideal. It is recommended that you specify a location that's private.
#
SecTmpDir /tmp/

# The location where ModSecurity will keep its persistent data.  This default setting 
# is chosen due to all systems have /tmp available however, it
# too should be updated to a place that other users can't access.
#
SecDataDir /tmp/


# -- File uploads handling configuration -------------------------------------

# The location where ModSecurity stores intercepted uploaded files. This
# location must be private to ModSecurity. You don't want other users on
# the server to access the files, do you?
#
#SecUploadDir /opt/modsecurity/var/upload/

# By default, only keep the files that were determined to be unusual
# in some way (by an external inspection script). For this to work you
# will also need at least one file inspection rule.
#
#SecUploadKeepFiles RelevantOnly

# Uploaded files are by default created with permissions that do not allow
# any other user to access them. You may need to relax that if you want to
# interface ModSecurity to an external program (e.g., an anti-virus).
#
#SecUploadFileMode 0600


# -- Debug log configuration -------------------------------------------------

# The default debug log configuration is to duplicate the error, warning
# and notice messages from the error log.
#
#SecDebugLog /opt/modsecurity/var/log/debug.log
#SecDebugLogLevel 3


# -- Audit log configuration -------------------------------------------------

# Log the transactions that are marked by a rule, as well as those that
# trigger a server error (determined by a 5xx or 4xx, excluding 404,  
# level response status codes).
#
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus \"^(?:5|4(?!04))\"

# Log everything we know about a transaction.
SecAuditLogParts ABCEFHJKZ

# Use a single file for logging. This is much easier to look at, but
# assumes that you will use the audit log only ocassionally.
#
SecAuditLogType Serial
SecAuditLog /var/log/apache2/modsec_audit.log

# Specify the path for concurrent audit logging.
#SecAuditLogStorageDir /opt/modsecurity/var/audit/


# -- Miscellaneous -----------------------------------------------------------

# Use the most commonly used application/x-www-form-urlencoded parameter
# separator. There's probably only one application somewhere that uses
# something else so don't expect to change this value.
#
SecArgumentSeparator &

# Settle on version 0 (zero) cookies, as that is what most applications
# use. Using an incorrect cookie version may open your installation to
# evasion attacks (against the rules that examine named cookies).
#
SecCookieFormat 0

# Specify your Unicode Code Point.
# This mapping is used by the t:urlDecodeUni transformation function
# to properly map encoded data to your language. Properly setting
# these directives helps to reduce false positives and negatives.
#
SecUnicodeMapFile unicode.mapping 20127

# Improve the quality of ModSecurity by sharing information about your
# current ModSecurity version and dependencies versions.
# The following information will be shared: ModSecurity version,
# Web Server version, APR version, PCRE version, Lua version, Libxml2
# version, Anonymous unique id for host.
# NB: As of April 2022, there is no longer any advantage to turning this
# setting On, as there is no active receiver for the information.
SecStatusEngine Off" > apache/mods/modsecurity.conf
    error_handler $? "Apache > Sécurisation > ModSecurity > L'écriture du fichier apache/mods/modsecurity.conf a échoué."

    run_command touch apache/mods/security2.conf
    error_handler $? "Apache > Sécurisation > ModSecurity > La création du fichier apache/mods/security2.conf a échoué."

    run_command echo "<IfModule security2_module>
  # Default Debian dir for modsecurity's persistent data
  SecDataDir /var/cache/modsecurity

  # Include all the *.conf files in /etc/modsecurity.
  # Keeping your local configuration in that directory
  # will allow for an easy upgrade of THIS file and
  # make your life easier
        IncludeOptional /etc/modsecurity/*.conf

  # Include OWASP ModSecurity CRS rules if installed
  IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf
  IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.0/rules/*.conf
</IfModule>" > apache/mods/security2.conf
    error_handler $? "Apache > Sécurisation > ModSecurity > L'écriture du fichier apache/mods/security2.conf a échoué."

#  ModSecurity : Règles de base OWASP (CRS)

    logs_info "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) : Préparation de la configuration en cours ..."

      run_command wget https://github.com/coreruleset/coreruleset/archive/v3.3.0.tar.gz
      error_handler $? "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) > wget https://github.com/coreruleset/coreruleset/archive/v3.3.0.tar.gz a échoué."

      run_command tar xvf v3.3.0.tar.gz
      error_handler $? "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) > tar xvf v3.3.0.tar.gz a échoué."

      run_command rm -rf v3.3.0.tar.gz
      error_handler $? "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) > rm -rf v3.3.0.tar.gz a échoué."

      run_command mkdir apache/mods/modsecurity-crs/
      error_handler $? "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) > mv coreruleset-3.3.0/ apache/mods/modsecurity-crs/ a échoué."

      run_command sudo mv coreruleset-3.3.0/ apache/mods/modsecurity-crs/
      error_handler $? "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) > mv coreruleset-3.3.0/ apache/mods/modsecurity-crs/ a échoué."

      run_command sudo mv apache/mods/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf.example apache/mods/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf
      error_handler $? "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) > mv crs-setup.conf.example crs-setup.conf a échoué."

    logs_success  "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) > Préparation de la configuration terminée."

  logs_success "Apache > Sécurisation > ModSecurity > Préparation de la configuration terminée."

# Sécurisation - Installation et configuration de ModEvasive
  logs_info "Apache > Sécurisation > ModEvasive > Préparation de la configuration en cours ..."

    run_command touch apache/mods/evasive.conf
    error_handler $? "Apache > Sécurisation > ModEvasive > La création /apache/mods/evasive.conf a échouée."

    run_command echo "
    <IfModule mod_evasive20.c>
        DOSHashTableSize    3097
        DOSPageCount        2
        DOSSiteCount        50
        DOSPageInterval     1
        DOSSiteInterval     1
        DOSBlockingPeriod   10
        DOSEmailNotify      $WEB_ADMIN_ADDRESS
        DOSLogDir           \"/var/log/mod_evasive\"
    </IfModule>
    " > apache/mods/evasive.conf
    error_handler $? "Apache > Sécurisation > ModEvasive > L'écriture du fichier /apache/mods/evasive.conf a échouée."

  logs_success "Apache > Sécurisation > ModEvasive > Préparation de la configuration terminée."

#TODO BONUS : Sécurisation - Installation et configuration de ModRatelimit

logs_success "Apache > Sécurisation > Préparation de la configuration avancée terminée."

#===================================================================#
# 11. Lancement des services                                        #
#===================================================================#

logs_info "Docker > Lancement des services phpmyadmin et mysql."
  run_command sudo docker-compose up -d
  error_handler $? "Docker > Le lancement des services phpmyadmin et mysql a échoué."
logs_success "Docker > Services phpmyadmin et mysql lancés."

logs_info "Docker > Lancement des services php et apache."
  run_command docker build -t web-php-apache ./apache/.
  error_handler $? "Docker > La construction de l'image web-php-apache a échouée."

  run_command docker run -d --name $WEB_CONTAINER_NAME --network $NETWORK_NAME -p $WEB_PORT:$WEB_PORT web-php-apache
  error_handler $? "Docker > Le lancement de $WEB_CONTAINER_NAME a échoué."
logs_success "Docker > Services php et apache lancés."

sleep 10

#===================================================================#
# 12. Lancement du script d'initialisation de mysql                     #
#===================================================================#

logs_info "MySQL > Initialisation de la base de données $DB_NAME en cours ..."

  run_command docker exec -i $DB_CONTAINER_NAME mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "$DB_INIT_SQL_QUERIES" $DB_NAME
  error_handler $? "Le lancement de l'initialisation de $DB_NAME a échoué."

logs_success "MySQL > Base de données $DB_NAME initialisée."

#===================================================================#
# 13. Nettoyage                                                     #
#===================================================================#

logs_info "Nettoyage des dossiers et fichiers de configuration sur la machine hôte en cours ..."

# Suppression des fichiers de configuration de Apache, configuration HTTPS, configuration des deux sites (siteA, siteB), configuration de la page confidentielle (.htaccess et .htpasswd), fichiers de configuration de ModSecurity
  run_command sudo rm -rf apache
  error_handler $? "La suppression du dossier apache a échoué."

# Suppression des fichiers de configuration de PHP, mysql
  run_command sudo rm -rf docker-compose.yml
  error_handler $? "La suppression du fichier docker-compose.yml a échoué."

logs_success "Nettoyage des dossiers et fichiers de configuration sur la machine hôte terminée."

#===================================================================#
# 14. Affichage des adresses IP des conteneurs                      #
#===================================================================#

logs_info "

"

# Récupérer les adresses IP des conteneurs
WEB_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $WEB_CONTAINER_NAME)
DB_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DB_CONTAINER_NAME)
PHPMYADMIN_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PHPMYADMIN_CONTAINER_NAME)

# Mettre à jour le fichier /etc/hosts
logs_info "Mise à jour du fichier /etc/hosts en cours ..."

  run_command echo "$WEB_CONTAINER_IP $DOMAIN_NAME" >> /etc/hosts
  error_handler $? "L'écriture de $WEB_CONTAINER_IP $DOMAIN_NAME dans /etc/hosts échouée."

  run_command echo "$WEB_CONTAINER_IP siteA.$DOMAIN_NAME" >> /etc/hosts
  error_handler $? "L'écriture de $WEB_CONTAINER_IP siteA.$DOMAIN_NAME dans /etc/hosts échouée."

  run_command echo "$WEB_CONTAINER_IP siteB.$DOMAIN_NAME" >> /etc/hosts
  error_handler $? "L'écriture de $WEB_CONTAINER_IP siteB.$DOMAIN_NAME dans /etc/hosts échouée."

  run_command echo "$PHPMYADMIN_CONTAINER_IP phpmyadmin.$DOMAIN_NAME" >> /etc/hosts
  error_handler $? "L'écriture de $PHPMYADMIN_CONTAINER_IP phpmyadmin.$DOMAIN_NAME dans /etc/hosts échouée."

logs_success "Mise à jour du fichier /etc/hosts terminée."

# Afficher les adresses IP des conteneurs
run_command echo "Adresses IP des conteneurs du réseau docker $NETWORK_NAME :"
run_command echo "$WEB_CONTAINER_NAME :"
run_command echo "   $WEB_CONTAINER_IP:$WEB_PORT $DOMAIN_NAME"
run_command echo "$PHPMYADMIN_CONTAINER_NAME : "
run_command echo "   $PHPMYADMIN_CONTAINER_IP:$PHPMYADMIN_PORT phpmyadmin.$DOMAIN_NAME"
run_command echo "$DB_CONTAINER_NAME :"
run_command echo "   $DB_CONTAINER_IP:$DB_PORT"

#===================================================================#

logs_end "Installation et configuration des services apache, mysql, php et phpmyadmin sous docker terminée."

#===================================================================#
# 15. Création d'un script de gestion des services                  #
#===================================================================#
logs_info "Génération du script de gestion des services phpmyadmin, mysql et php:apache sous docker."

  run_command touch manage_services.sh
  error_handler $? "La création du fichier manage_services.sh a échouée."

  run_command echo "#!/bin/bash
source ./../.common.sh

# Fonction pour démarrer les services
start_services()
{
  logs_info \"Démarrage des services...\"

    run_command docker start $DB_CONTAINER_NAME
    error_handler \$? \"Le démarrage du service $DB_CONTAINER_NAME a échouée.\"

    run_command docker start $PHPMYADMIN_CONTAINER_NAME
    error_handler \$? \"Le démarrage du service $PHPMYADMIN_CONTAINER_NAME a échouée.\"

    run_command docker start $WEB_CONTAINER_NAME
    error_handler \$? \"Le démarrage du service $WEB_CONTAINER_NAME a échouée.\"

  logs_success \"Services démarrés.\"
}

# Fonction pour arrêter les start_services
stop_services()
{
  logs_info \"Arrêt des services...\"

    run_command docker stop $DB_CONTAINER_NAME
    error_handler \$? \"L'arrêt du service $DB_CONTAINER_NAME a échouée.\"

    run_command docker stop $PHPMYADMIN_CONTAINER_NAME
    error_handler \$? \"L'arrêt du service $PHPMYADMIN_CONTAINER_NAME a échouée.\"

    run_command docker stop $WEB_CONTAINER_NAME
    error_handler \$? \"L'arrêt du service $WEB_CONTAINER_NAME a échouée.\"

  logs_success \"Services arrêtés.\"
}

# Fonction pour redémarrer les services.
restart_services()
{
  logs_info \"Redémarrage des services...\"
  
    run_command docker stop $DB_CONTAINER_NAME
    error_handler \$? \"Le redémarrage du service $DB_CONTAINER_NAME a échouée.\"

    run_command docker stop $PHPMYADMIN_CONTAINER_NAME
    error_handler \$? \"Le redémarrage du service $PHPMYADMIN_CONTAINER_NAME a échouée.\"

    run_command docker stop $WEB_CONTAINER_NAME
    error_handler \$? \"Le redémarrage du service $WEB_CONTAINER_NAME a échouée.\"

  logs_success \"Services redémarrés.\"
}

# Fonction pour afficher les adresses ip des conteneurs
show_ip()
{
    # Récupérer les adresses IP des conteneurs
    WEB_CONTAINER_IP=\$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $WEB_CONTAINER_NAME)
    DB_CONTAINER_IP=\$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DB_CONTAINER_NAME)
    PHPMYADMIN_CONTAINER_IP=\$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PHPMYADMIN_CONTAINER_NAME)

    # Afficher les adresses IP des conteneurs
    echo \"Adresses IP des conteneurs du réseau docker $NETWORK_NAME :\"
    echo \"$WEB_CONTAINER_NAME :\"
    echo \"   \$WEB_CONTAINER_IP:$WEB_PORT $DOMAIN_NAME\"
    echo \"$PHPMYADMIN_CONTAINER_NAME : \"
    echo \"   \$PHPMYADMIN_CONTAINER_IP:$PHPMYADMIN_PORT phpmyadmin.$DOMAIN_NAME\"
    echo \"$DB_CONTAINER_NAME :\"
    echo \"   \$DB_CONTAINER_IP:$DB_PORT\"
}

# Fonction pour afficher l'aide.
show_help() 
{
  echo \"Usage: \$0 {start|stop|restart|help}\"
  echo \"  start     Démarrer les services.\"
  echo \"  stop      Arrêter les services.\"
  echo \"  restart   Redémarrer les services.\"
  echo \"  ip        Afficher les adresses ip des services dans le réseau $NETWORK_NAME.\"
  echo \"  help      Afficher l'aide.\"
}

# Vérifier le nombre d'arguments
if [ \"\$#\" -ne 1 ]; then
    echo \"Erreur: Nombre d'arguments incorrect.\"
    show_help
    exit 1
fi

# Vérifier l'argument passé
case \$1 in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    ip)
        show_ip
        ;;
    help)
        show_help
        ;;
    *)
        echo \"Erreur: Commande inconnue '$1'\"
        show_help
        exit 1
        ;;
esac" > manage_services.sh
  error_handler $? "L'écriture du fichier manage_services.sh a échouée."

  run_command chmod +x manage_services.sh
  error_handler $? "L'attribution des droits au fichier manage_services.sh a échouée."

logs_success "Génération du script de gestion des services phpmyadmin, mysql et php:apache sous docker terminée."

#===================================================================#

logs_end "Services apache, mysql, php et phpmyadmin sous docker prêts à l'emploi."
exit 0