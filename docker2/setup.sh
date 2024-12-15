#!/bin/bash

# Fonction pour afficher des messages de log avec couleurs
log_message() {
    local TYPE=$1
    local MESSAGE=$2
    local COLOR=""
    case $TYPE in
        INFO) COLOR="\033[0;32m" ;;
        WARN) COLOR="\033[0;33m" ;;
        ERROR) COLOR="\033[0;31m" ;;
        *) COLOR="\033[0m" ;;
    esac
    echo -e "${COLOR}[$(date +'%Y-%m-%d %H:%M:%S')] [$TYPE] $MESSAGE\033[0m" | tee -a setup.log
}

# Charger les variables d'environnement
export $(grep -v '^#' .env | xargs)

# Créer les répertoires nécessaires
mkdir -p apache/conf apache/html apache/logs php/conf php/logs

# Configurer Apache
log_message INFO "Configuring Apache..."
cat > apache/conf/httpd.conf <<EOF
ServerName $DOMAINE_NAME
Listen 80

<VirtualHost *:80>
    ServerName siteA.$DOMAINE_NAME
    DocumentRoot "/usr/local/apache2/htdocs/siteA"
    <Directory "/usr/local/apache2/htdocs/siteA">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "/var/log/apache2/siteA_error.log"
    CustomLog "/var/log/apache2/siteA_access.log" common
</VirtualHost>

<VirtualHost *:80>
    ServerName siteB.$DOMAINE_NAME
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
        ServerName siteA.$DOMAINE_NAME
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
        ServerName siteB.$DOMAINE_NAME
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
log_message INFO "Creating HTML and PHP files..."
mkdir -p apache/html/siteA apache/html/siteB
echo "<html><body><h1>Welcome to SiteA</h1></body></html>" > apache/html/siteA/index.html
echo "<html><body><h1>Welcome to SiteB</h1></body></html>" > apache/html/siteB/index.html

cat > apache/html/siteA/confidential.php <<EOF
<?php
\$db = new mysqli('mysql', '$DB_USER', '$DB_PASSWORD', '$DB_NAME');
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
\$db = new mysqli('mysql', '$DB_USER', '$DB_PASSWORD', '$DB_NAME');
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
htpasswd -cb apache/html/.htpasswd $APACHE_ADMIN_USER $APACHE_ADMIN_PASSWORD

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

docker exec -i mysql mysql -u$DB_USER -p$DB_PASSWORD -e "CREATE DATABASE $DB_NAME;"
docker exec -i mysql mysql -u$DB_USER -p$DB_PASSWORD -e "USE $DB_NAME; CREATE TABLE todolist (id INT AUTO_INCREMENT PRIMARY KEY, task VARCHAR(255) NOT NULL);"
docker exec -i mysql mysql -u$DB_USER -p$DB_PASSWORD -e "USE $DB_NAME; INSERT INTO todolist (task) VALUES ('Task 1'), ('Task 2'), ('Task 3');"

# Démarrer les autres services
log_message INFO "Starting other services..."
docker-compose up -d

log_message INFO "Setup completed successfully."
