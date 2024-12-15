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
    echo -e "${color}[$date_formated] $1 ${RESET}" | tee -a /var/log/apache_install.log
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
mkdir -p apache/conf apache/html apache/logs php/conf php/logs apache/certs


    sudo apt-get install -y openssl
    error_handler $? "L'installation d'openssl a échouée."

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out apache/certs/"$DOMAIN_NAME"_server.crt -keyout apache/certs/"$DOMAIN_NAME"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
    error_handler $? "La génération de demande de signature de certifcat a échouée"

    openssl x509 -in apache/certs/"$DOMAIN_NAME"_server.crt -text -noout
    error_handler $? "La vérification du certificat a échouée."
    
    cd

    sudo chmod 600 apache/certs/"$DOMAIN_NAME"_server.key
    sudo chown root:root apache/certs/"$DOMAIN_NAME"_server.crt
    sudo chmod 440 apache/certs/"$DOMAIN_NAME"_server.crt


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
      - "\${APACHE_PORT}:80"
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
      MYSQL_USER: \${DB_USER}
      MYSQL_PASSWORD: \${DB_PASSWORD}
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
      PMA_USER: \${PHPMYADMIN_ADMIN_USER}
      PMA_PASSWORD: \${PHPMYADMIN_ADMIN_PASSWORD}
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
LoadModule security2_module modules/mod_security2.so
LoadModule evasive20_module modules/mod_evasive20.so
IncludeOptional conf/extra/httpd-ssl.conf

ServerName $DOMAIN_NAME
Listen $WEB_PORT

<VirtualHost *:$WEB_PORT>
    ServerName siteA.$DOMAIN_NAME
    DocumentRoot "/usr/local/apache2/htdocs/siteA"
    <Directory "/usr/local/apache2/htdocs/siteA">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "/var/log/apache2/siteA_error.log"
    CustomLog "/var/log/apache2/siteA_access.log" common
</VirtualHost>

<VirtualHost *:$WEB_PORT>
    ServerName siteB.$DOMAIN_NAME
    DocumentRoot "/usr/local/apache2/htdocs/siteB"
    <Directory "/usr/local/apache2/htdocs/siteB">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "/var/log/apache2/siteB_error.log"
    CustomLog "/var/log/apache2/siteB_access.log" common
</VirtualHost>

<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerName siteA.$DOMAIN_NAME
        DocumentRoot "/usr/local/apache2/htdocs/siteA"
        SSLEngine on
        SSLCertificateFile /usr/local/apache2/conf/server.crt
        SSLCertificateKeyFile /usr/local/apache2/conf/server.key
        <Directory "/usr/local/apache2/htdocs/siteA">
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
        ErrorLog "/var/log/apache2/siteA_error.log"
        CustomLog "/var/log/apache2/siteA_access.log" common
    </VirtualHost>

    <VirtualHost *:443>
        ServerName siteB.$DOMAIN_NAME
        DocumentRoot "/usr/local/apache2/htdocs/siteB"
        SSLEngine on
        SSLCertificateFile /usr/local/apache2/conf/server.crt
        SSLCertificateKeyFile /usr/local/apache2/conf/server.key
        <Directory "/usr/local/apache2/htdocs/siteB">
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
        ErrorLog "/var/log/apache2/siteB_error.log"
        CustomLog "/var/log/apache2/siteB_access.log" common
    </VirtualHost>
</IfModule>
EOF

# Créer les fichiers index.html et confidential.php


mkdir -p apache/html/siteA apache/html/siteB
echo "<html><body><h1>Welcome to SiteA</h1></body></html>" > apache/html/siteA/index.html
echo "<html><body><h1>Welcome to SiteB</h1></body></html>" > apache/html/siteB/index.html

cat > apache/html/siteA/confidential.php <<EOF
<?php
\$db = new mysqli('mysql', '$DB_ADMIN_USERNAME', '$DB_ADMIN_PASSWORD', '$DB_NAME');
if (\$db->connect_error) {
    die("Connection failed: " . \$db->connect_error);
}
\$result = \$db->query("SELECT * FROM todolist");
while (\$row = \$result->fetch_assoc()) {
    echo "Task: " . \$row['task'] . "<br>";
}
\$db->close();
?>
EOF

cat > apache/html/siteB/confidential.php <<EOF
<?php
\$db = new mysqli('mysql', '$DB_ADMIN_USERNAME', '$DB_ADMIN_PASSWORD', '$DB_NAME');
if (\$db->connect_error) {
    die("Connection failed: " . \$db->connect_error);
}
\$result = \$db->query("SELECT * FROM todolist");
while (\$row = \$result->fetch_assoc()) {
    echo "Task: " . \$row['task'] . "<br>";
}
\$db->close();
?>
EOF

# Créer les fichiers .htaccess pour l'authentification
log_message INFO "Creating .htaccess files..."
htpasswd -cb apache/html/.htpasswd $WEB_ADMIN_USER $WEB_ADMIN_PASSWORD

cat > apache/html/siteA/.htaccess <<EOF
AuthType Basic
AuthName "Restricted Area"
AuthUserFile /usr/local/apache2/htdocs/.htpasswd
Require valid-user
EOF

cat > apache/html/siteB/.htaccess <<EOF
AuthType Basic
AuthName "Restricted Area"
AuthUserFile /usr/local/apache2/htdocs/.htpasswd
Require valid-user
EOF

# Configurer MySQL
log_message INFO "Configuring MySQL..."
docker-compose up -d mysql
sleep 10

#TODO : CREER LE COMPTE 
docker exec -i mysql mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "CREATE DATABASE $DB_NAME;"
docker exec -i mysql mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "USE $DB_NAME; CREATE TABLE todolist (id INT AUTO_INCREMENT PRIMARY KEY, task VARCHAR(255) NOT NULL);"
docker exec -i mysql mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "USE $DB_NAME; INSERT INTO todolist (task) VALUES ('Task 1'), ('Task 2'), ('Task 3');"

# Démarrer les autres services
log_message INFO "Starting other services..."
docker-compose up -d

log_message INFO "Setup completed successfully."
