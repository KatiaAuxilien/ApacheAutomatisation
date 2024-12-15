#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

error_handler()
{
    if [ $1 -ne 0 ]
    then
        echo -e "${RED}Erreur : $2 ${RESET}"
        exit $1
    fi
}

logs()
{
    local color="$1"
    shift
    date_formated=$(date +"%d-%m-%Y %H:%M:%S")
    echo -e "${color}[$date_formated] $1 ${RESET}" | tee -a install.log
}

logs_info()
{
    logs "$YELLOW" "$*"
}

logs_success()
{
    logs "$GREEN" "$*"
}

logs_end()
{
    logs "$BLUE" "$*"
}

# Fonction pour vérifier si une variable est définie
check_variable() {
  local var_name=$1
  if [ -z "${!var_name+x}" ]; then
    echo "La variable $var_name n'est pas définie."
    exit 2
  fi
}

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

"PHP_CONTAINER_NAME"
"PHPMYADMIN_CONTAINER_NAME"

"PHP_ROOT_PASSWORD"
"PHP_HTACCESS_PASSWORD"
"PHP_ADMIN_ADDRESS"
"PHP_ADMIN_USERNAME"
"PHP_ADMIN_PASSWORD"
"PHP_PORT"
"PHPMYADMIN_PORT"

"DB_CONTAINER_NAME"

"DB_HOST"
"DB_PORT"

"DB_ROOT_PASSWORD"

"DB_ADMIN_USERNAME"
"DB_ADMIN_PASSWORD"
"DB_ADMIN_ADDRESS"

"DB_NAME"
)


#======================================================================#

if [ "$EUID" -ne 0 ]
then
    echo -e "${RED}Ce script doit être exécuté avec des privilèges root.${RESET}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer avant de continuer.${RESET}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer avant de continuer.${RESET}"
    exit 1
fi

#TODO : Vérifier le format valide des variables

logs_info "Vérification des variables .env..."

    # Charger les variables depuis le fichier .env
    if [ ! -f .env ]; then
        echo "Erreur : fichier .env non trouvé."
        exit 1
    fi
    source .env

    for var in "${required_vars_start[@]}"; do
      check_variable "$var"
    done

logs_success "Les variables .env ont été vérifiées."



#======================================================================#


# Créer les répertoires nécessaires
mkdir -p apache/conf apache/html apache/logs apache/conf/certs php/conf php/logs


sudo apt-get install -y openssl
error_handler $? "L'installation d'openssl a échouée."

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out apache/conf/certs/certificate_web_server.crt -keyout apache/conf/certs/key_web_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
error_handler $? "La génération de demande de signature de certifcat a échouée"

openssl x509 -in apache/conf/certs/certificate_web_server.crt -text -noout
error_handler $? "La vérification du certificat a échouée."

sudo chmod 600 apache/conf/certs/key_web_server.key
sudo chown root:root apache/conf/certs/certificate_web_server.crt
sudo chmod 440 apache/conf/certs/certificate_web_server.crt


#======================================================================#


sudo docker network create $NETWORK_NAME

cat > docker-compose.yml <<EOF
version: '3.8'

services:
  php:
    image: php:7.4-apache
    container_name: \${PHP_CONTAINER_NAME}
    ports:
      - "\${PHP_PORT}:9000"
    volumes:
      - ./sites:/var/www/html
      - ./php/conf:/usr/local/etc/php
      - ./php/logs:/var/log/php
    networks:
      - $NETWORK_NAME

  apache:
    image: httpd:latest
    container_name: \${WEB_CONTAINER_NAME}
    ports:
      - "\${WEB_PORT}:80"
    volumes:
      - ./apache/conf:/usr/local/apache2/conf
      - ./apache/html:/usr/local/apache2/htdocs
      - ./apache/logs:/var/log/apache2
    environment:
      - DOMAINE_NAME=\${DOMAIN_NAME}
      - APACHE_ADMIN_USER=\${WEB_ADMIN_USER}
      - APACHE_ADMIN_PASSWORD=\${WEB_ADMIN_PASSWORD}
    depends_on:
      - php
      - mysql
    networks:
      - $NETWORK_NAME

  mysql:
    image: mysql:latest
    container_name: \${DB_CONTAINER_NAME}
    ports:
      - "\${DB_PORT}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: \${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: \${DB_NAME}
      MYSQL_USER: \${DB_ADMIN_USERNAME}
      MYSQL_PASSWORD: \${DB_ADMIN_PASSWORD}
    networks:
      - $NETWORK_NAME


  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: \${PHPMYADMIN_CONTAINER_NAME}
    ports:
      - "\${PHPMYADMIN_PORT}:80"
    environment:
      PMA_HOST: \${DB_CONTAINER_NAME}
      MYSQL_ROOT_PASSWORD: \${DB_ROOT_PASSWORD}
      PMA_USER: \${PHP_ADMIN_USERNAME}
      PMA_PASSWORD: \${PHP_ADMIN_PASSWORD}
    depends_on:
      - mysql
    networks:
      - $NETWORK_NAME

volumes:
  mysql_data:

networks:
  $NETWORK_NAME:
    external: true
EOF



cat > apache/conf/httpd.conf <<EOF
# Chargement des modules nécessaires
LoadModule ssl_module modules/mod_ssl.so
LoadModule security2_module modules/mod_security2.so
LoadModule evasive20_module modules/mod_evasive20.so
LoadModule ratelimit_module modules/mod_ratelimit.so
LoadModule rewrite_module modules/mod_rewrite.so

# Configuration de base
ServerName $DOMAIN_NAME
Listen $WEB_PORT
ServerAdmin $WEB_ADMIN_ADDRESS
ServerAlias localhost

# Configuration de ModSecurity
<IfModule security2_module>
    SecRuleEngine On
    Include conf/modsecurity.d/modsecurity_crs_10_setup.conf
    Include conf/modsecurity.d/base_rules/*.conf
</IfModule>

# Configuration de ModEvasive
<IfModule mod_evasive20.c>
    DOSHashTableSize    3097
    DOSPageCount        2
    DOSPageInterval     1
    DOSSiteCount        50
    DOSSiteInterval     1
    DOSBlockingPeriod   10
</IfModule>

# Configuration de ModRateLimit
<IfModule mod_ratelimit.c>
    <Location />
        SetEnvIf Request_URI "^/.*$" ratelimit:10
        SetEnvIf Request_URI "^/.*$" ratelimit:10
    </Location>
</IfModule>

# Configuration de HTTPS
<VirtualHost *:443>
    ServerName $DOMAIN_NAME
    DocumentRoot "/usr/local/apache2/htdocs"
    ServerName $DOMAIN_NAME
    Listen 443
    ServerAdmin $WEB_ADMIN_ADDRESS
    ServerAlias localhost

    SSLEngine on
    SSLCertificateFile /usr/local/apache2/conf/certs/certificate_web_server.crt
    SSLCertificateKeyFile /usr/local/apache2/conf/certs/key_web_server.key

    Header set Strict-Transport-Security \"max-age=31536000; includeSubDomains\"

    # Masquage des fichiers dans l'URL
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ index.php?url=$1 [QSA,L]
</VirtualHost>

# Configuration des sites virtuels
Include conf/extra/httpd-vhosts.conf
EOF

    htpasswd -cb apache/html/.htpasswd $WEB_ADMIN_USER $WEB_ADMIN_PASSWORD

    touch apache/conf/httpd-vhosts.conf
    error_handler $? "La création du fichier apache/conf/httpd-vhosts.conf a échouée."

#Création et configuration de n sites
    for site_name in siteA siteB
    do
        logs_info "Création du site " $site_name "..."
        
        sudo mkdir apache/html/$site_name
        error_handler $? "La création du dossier apache/html/$site_name a échouée."
        
        sudo chown -R $USER:$USER apache/html/$site_name
        error_handler $? "L'attribution des droits sur le dossier apache/html/$site_name a échouée."
        
        sudo touch apache/html/$site_name/index.html
        error_handler $? "La création du fichier apache/html/$site_name/index.html a échouée."
        
        echo "
<html>
    <head>
        <title>Bienvenue sur le " $site_name " !</title>
    </head>
    <body>
        <h1> N'allez pas sur l'autre site, ce site est malveillant !</h1>
    </body>
</html>" > apache/html/$site_name/index.html
        error_handler $? "L'écriture dans le fichier apache/html/$site_name/index.html a échouée."

        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out apache/conf/certs/"$site_name".certificate_web_server.crt -keyout apache/conf/certs/"$site_name".key_web_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$site_name.$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
        error_handler $? "La génération de demande de signature de certifcat du site $site_name a échouée"

        openssl x509 -in apache/conf/certs/"$site_name".certificate_web_server.crt -text -noout
        error_handler $? "La vérification du certificat a échouée."
        
        sudo chmod 600 apache/conf/certs/"$site_name".key_web_server.key
        sudo chown root:root apache/conf/certs/"$site_name".certificate_web_server.crt
        sudo chmod 440 apache/conf/certs/"$site_name".certificate_web_server.crt

        #Création des Virtual Host
        echo "
# $site_name
# Masquage des fichiers dans l'URL
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php?url=$1 [QSA,L]

<VirtualHost *:79>
    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(.*) https://%SERVER_NAME/$1 [R=301,L]
</VirtualHost>
<VirtualHost *:443>
    ServerAdmin $WEB_ADMIN_ADDRESS
    ServerName $site_name.$DOMAIN_NAME
    DocumentRoot \"/usr/local/apache2/htdocs/$site_name\"

    SSLEngine on
    SSLCertificateFile /usr/local/apache2/conf/certs/"$site_name".certificate_web_server.crt
    SSLCertificateKeyFile /usr/local/apache2/conf/certs/"$site_name".key_web_server.key

    Header set Strict-Transport-Security \"max-age=31536000; includeSubDomains\"

    <Directory /usr/local/apache2/htdocs/$site_name>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
  </Directory>
</VirtualHost>" >> apache/conf/httpd-vhosts.conf
        error_handler $? "L'écriture du fichier apache/conf/httpd-vhosts.conf a échouée."

        echo "127.0.0.1 $site_name.$DOMAIN_NAME" >> /etc/hosts
        error_handler $? "L'écriture du fichier /etc/hosts a échouée."

        mkdir apache/html/$site_name/confidential
        error_handler $? "La création du dossier apache/html/$site_name/confidential a échouée."

        touch apache/html/$site_name/confidential/confidential.php
        error_handler $? "La création du fichier /apache/html/$site_name/confidential/confidential.php a échouée."
        
        echo "
<html>
    <head>
        <title>Page protégée du site $site_name</title>
    </head>
    <body>
        <h1> TOP SECRET </h1>
<?php
    \$user = \""$DB_USERNAME"\";
    \$password = \""DB_PASSWORD"\";
    \$database = \""$DB_NAME"\";
    \$table = \"todo_list\";
    try
    {   \$db = new PDO("",$,\$password);
        echo \"<h2>TODO</h2> <ol>\";
        foreach(\$db->query(\"SELECT content FROM \$table\") as \$row)
         { echo \"<li>\" .\$row['content'] . \"</li>\";
         }
        echo \"</ol>\";
    } 
    catch (PDOException \$e)
    {   print \"ERROR ! : \" . \$e->getMessage() . \"<br/>\";
        die();
    }
?>
    </body>
</html>" > apache/html/$site_name/confidential/confidential.php
        error_handler $? "L'écriture dans le fichier /apache/html/$site_name/confidential/confidential.php a échouée."
        
        touch apache/html/$site_name/confidential/.htaccess
        error_handler $? "La création du fichier apache/html/$site_name/confidential/.htaccess a échouée."

        echo "AuthType Basic
        AuthName \"Accès protégé\"
        AuthUserFile /usr/local/apache2/htdocs/.htpasswd
        require valid-user
        Options -Indexes" > apache/html/$site_name/confidential/.htaccess
        error_handler $? "L'écriture du fichier /apache/html/$site_name/confidential/.htaccess a échouée."

        logs_success "$site_name créé."
    done


# Configurer MySQL

logs_info "Configuration du service mysql en cours..."
docker-compose up -d $DB_CONTAINER_NAME
sleep 50

# docker exec -i $DB_CONTAINER_NAME mysql -uroot -p$DB_ROOT_PASSWORD -e "CREATE USER '$DB_ADMIN_USERNAME'@'localhost' IDENTIFIED BY '$DB_ADMIN_PASSWORD';"
# error_handler $? "La création de l'utilisateur administrateur $DB_ADMIN_USERNAME a échouée."
 
# docker exec -i $DB_CONTAINER_NAME mysql -uroot -p$DB_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_ADMIN_USERNAME'@'localhost' WITH GRANT OPTION;"

# docker exec -i $DB_CONTAINER_NAME mysql -uroot -p$DB_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# docker exec -i $DB_CONTAINER_NAME mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "CREATE DATABASE $DB_NAME;"
# error_handler $? "La création de la base de données $DB_NAME a échouée."

# docker exec -i $DB_CONTAINER_NAME mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "USE $DB_NAME; CREATE TABLE todolist (item_id INT AUTO_INCREMENT, content VARCHAR(255), PRIMARY KEY (item_id));"
# error_handler $? "Création de la table todolist a échouée."

# docker exec -i $DB_CONTAINER_NAME mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "USE $DB_NAME; INSERT INTO todolist (task) VALUES ('Task 1'), ('Task 2'), ('Task 3');"
# error_handler $? "Insertion des données dans la table todolist a échouée."

# logs_success "Configuration du service mysql terminée."
# # Démarrer les autres services

# docker-compose up -d


logs_end "Installation et configuration des services apache, mysql, php et phpmyadmin sous docker terminée."
exit 0