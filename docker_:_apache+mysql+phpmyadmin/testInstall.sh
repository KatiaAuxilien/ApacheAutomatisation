#!/bin/bash

# Charger les variables depuis le fichier .env
if [ ! -f .env ]; then
    echo "Erreur : fichier .env non trouvé."
    exit 1
fi
source .env

# Créer un réseau Docker
docker network create $NETWORK_NAME

# Dossier de configuration et certificats
mkdir -p certs conf/sites

# Génération de certificats auto-signés
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout certs/apache-selfsigned.key \
    -out certs/apache-selfsigned.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=Example/OU=IT Department/CN=$DOMAIN_NAME"

	
	sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out certs/"$DOMAIN_NAME"_server.crt -keyout certs/"$DOMAIN_NAME"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
	error_handler $? "La génération de demande de signature de certifcat a échouée"

	openssl x509 -in "$DOMAIN_NAME"_server.crt -text -noout
	error_handler $? "La vérification du certificat a échouée."
	


# Configuration de Apache avec ModSecurity et ModEvasive
cat > conf/httpd.conf <<EOL
LoadModule security2_module modules/mod_security2.so
LoadModule evasive20_module modules/mod_evasive20.so
IncludeOptional conf/extra/httpd-ssl.conf

<IfModule security2_module>
    SecRuleEngine On
</IfModule>

<IfModule evasive20_module>
    DOSHashTableSize 2048
    DOSPageCount 20
    DOSSiteCount 50
    DOSBlockingPeriod 10
    DOSLogDir "/var/log/mod_evasive"
</IfModule>

<VirtualHost *:443>
    DocumentRoot "/var/www/html"
    ServerName $DOMAIN_NAME

    SSLEngine on
    SSLCertificateFile "/etc/apache2/certs/"$DOMAIN_NAME"_server.crt"
    SSLCertificateKeyFile "/etc/apache2/certs/"$DOMAIN_NAME"_server.key"

    <Directory "/var/www/html">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

# Docker-compose.yml
cat > docker-compose.yml <<EOL
version: '3.8'
services:
  apache:
    image: httpd:latest
    container_name: \${WEB_CONTAINER_NAME}
    volumes:
      - ./conf/httpd.conf:/usr/local/apache2/conf/httpd.conf
      - ./certs:/etc/apache2/certs
      - ./sites:/var/www/html
    ports:
      - "\${WEB_PORT}:443"
    depends_on:
      - php
    networks:
      - $NETWORK_NAME

  php:
    image: php:7.4-apache
    container_name: \${PHP_CONTAINER_NAME}
    volumes:
      - ./sites:/var/www/html
    networks:
      - $NETWORK_NAME

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: \${PHPMYADMIN_CONTAINER_NAME}
    environment:
      PMA_HOST: \${DB_CONTAINER_NAME}
      MYSQL_ROOT_PASSWORD: \${DB_ROOT_PASSWORD}
    ports:
      - "\${PHP_PORT}:80"
    depends_on:
      - mysql
    networks:
      - $NETWORK_NAME

  mysql:
    image: mysql:5.7
    container_name: \${DB_CONTAINER_NAME}
    environment:
      MYSQL_ROOT_PASSWORD: \${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: \${DB_NAME}
      MYSQL_USER: \${DB_ADMIN_USERNAME}
      MYSQL_PASSWORD: \${DB_ADMIN_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "\${DB_PORT}:3306"
    networks:
      - $NETWORK_NAME

volumes:
  db_data:

networks:
  $NETWORK_NAME:
    external: true
EOL

# Créer les sites web
mkdir -p sites/siteA sites/siteB
cat > sites/siteA/index.php <<EOL
<?php
phpinfo();
?>
EOL

cat > sites/siteB/index.php <<EOL
<?php
\$servername = "mysql";
\$username = "\${DB_ADMIN_USER}";
\$password = "\${DB_ADMIN_PASSWORD}";
\$dbname = "\${DB_NAME}";

\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);
if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

\$sql = "CREATE TABLE IF NOT EXISTS todolist (id INT AUTO_INCREMENT PRIMARY KEY, task VARCHAR(255) NOT NULL)";
if (\$conn->query(\$sql) === TRUE) {
    echo "Table created successfully";
} else {
    echo "Error creating table: " . \$conn->error;
}

\$conn->close();
?>
EOL

# Configurer .htaccess pour protéger /confidential
mkdir -p sites/siteA/confidential sites/siteB/confidential
cat > sites/siteA/confidential/.htaccess <<EOL
AuthType Basic
AuthName "Restricted Content"
AuthUserFile /var/www/html/siteA/confidential/.htpasswd
Require valid-user
EOL

cat > sites/siteB/confidential/.htaccess <<EOL
AuthType Basic
AuthName "Restricted Content"
AuthUserFile /var/www/html/siteB/confidential/.htpasswd
Require valid-user
EOL

# Créer utilisateurs .htpasswd
htpasswd -c -b sites/siteA/confidential/.htpasswd admin \${HTACCESS_PASSWORD}
htpasswd -c -b sites/siteB/confidential/.htpasswd admin \${HTACCESS_PASSWORD}

# Lancer les services
sudo docker-compose up -d
