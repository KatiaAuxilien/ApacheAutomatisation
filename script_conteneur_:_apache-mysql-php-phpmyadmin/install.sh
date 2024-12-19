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

source ./.common.sh

#===================================================================#
# Prépartion de l'arborescence                                      #
#===================================================================#

mkdir apache apache/html bdd bdd/mysql_data
chmod -R 755 apache
chmod -R 755 apache/html
chmod -R 755 bdd

chown -R 1001:1001 bdd/mysql_data

#TODO : Messages de logs
#TODO : Vérification du lancement en droits admin
#TODO : Vérification des variables fournies dans le .env
#TODO : Vérification de l'installation de docker


#===================================================================#
# Préparation pour docker                                           #
#===================================================================#

# Création du réseau docker
sudo docker network create $NETWORK_NAME --driver bridge
error_handler $? " La création du réseau docker $NETWORK_NAME a échouée."


      # MYSQL_PORT_NUMBER: $DB_PORT
    # ports:
      # - \"$DB_PORT:$DB_PORT\"

      # APACHE_PORT: $WEB_PORT
    # ports:
      # - \"$PHPMYADMIN_PORT:$PHPMYADMIN_PORT\"

      # MYSQL_USER: $DB_ADMIN_USERNAME
      # MYSQL_PASSWORD: $DB_ADMIN_PASSWORD
      # PMA_USER: $PHPMYADMIN_ADMIN_USERNAME
      # PMA_PASSWORD: $PHPMYADMIN_ADMIN_PASSWORD
      # PMA_ARBITRARY: 1
      # PMA_PORT: $DB_PORT

    # ports:
      # - \"$WEB_PORT:$WEB_PORT\"


touch docker-compose.yml
chmod -R 755 docker-compose.yml

# Installation PhpMyAdmin
# Installation mysql
#TODO : Changer les ports par défaut
echo "services:
  $DB_CONTAINER_NAME:
    image: bitnami/mysql:latest
    container_name: $DB_CONTAINER_NAME
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_ADMIN_USERNAME
      MYSQL_PASSWORD: $DB_ADMIN_PASSWORD
    ports:
      - "3306:3306"
    volumes:
      - ./bdd/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./bdd/mysql_data/:/bitnami/mysql/data/
    networks:
      - $NETWORK_NAME

  $PHPMYADMIN_CONTAINER_NAME:
    image: phpmyadmin/phpmyadmin
    container_name: $PHPMYADMIN_CONTAINER_NAME
    restart: always
    environment:
      PMA_HOST: $DB_CONTAINER_NAME
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
    networks:
      - $NETWORK_NAME

volumes:
  mysql_data:

networks:
  $NETWORK_NAME:
    external: true" > docker-compose.yml
error_handler $? "L'écriture du fichier docker-compose.yml a échouée."


#TODO : Configuration de mysql


#TODO : Configurer mysql pour le TLS.


#TODO : Configuration de Apache

touch apache/apache2.conf
#error_handler $? "  a échouée."

chmod -R 755 apache/apache2.conf

echo "ServerRoot \"/etc/apache2\"

ServerName $DOMAIN_NAME

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
    Options Indexes FollowSymLinks
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
error_handler $? "L'écriture du fichier de configuration apache/apache2.conf a échouée."

touch apache/html/index.html
chmod -R 755 apache/html/index.html

echo "<!DOCTYPE html>
<html>
  <head>
    <title>Page Title</title>
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
    <p> ✨ <a href=\"http://siteA.$DOMAIN_NAME/\">Visiter siteA.$DOMAIN_NAME</a> </p>
    <p> ✨ <a href=\"http://siteB.$DOMAIN_NAME/\">Visiter siteB.$DOMAIN_NAME</a> </p>
  </body>
</html> " > apache/html/index.html


#TODO : Création de deux sites (siteA, siteB)

    for site_name in siteA siteB
    do
        logs_info "Création du site " $site_name "..."
        
        mkdir apache/html/$site_name
        #error_handler $? "La création du dossier apache/html/$site_name a échouée."
        chmod -R 755 apache/html/$site_name
        error_handler $? "L'attribution des droits sur le dossier html/$site_name a échouée."
        
        sudo touch apache/html/$site_name/index.html
        # error_handler $? "La création du fichier apache/html/$site_name/index.html a échouée."


        echo "<!DOCTYPE html>
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
        <h1> N'allez pas sur l'autre site, ce site est malveillant !</h1>
    </body>
</html>" > apache/html/$site_name/index.html
        error_handler $? "L'écriture dans le fichier apache/html/$site_name/index.html a échouée."

# Création de la page confidentielle

        mkdir apache/html/$site_name/confidential
        # error_handler $? "La création du dossier apache/html/$site_name/confidential a échouée."
        chmod -R 755 apache/html/$site_name/confidential

        touch apache/html/$site_name/confidential/confidential.php
        # error_handler $? "La création du fichier apache/html/$site_name/confidential/confidential.php a échouée."
        chmod -R 755 apache/html/$site_name/confidential/confidential.php

        echo "<!DOCTYPE html>
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


    \$session = new mysqli(\"$DB_CONTAINER_NAME\",\$user,\$password, \$database);

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
</html>" > apache/html/$site_name/confidential/confidential.php
        error_handler $? "L'écriture dans le fichier apache/html/$site_name/confidential/confidential.php a échouée."

        logs_success "$site_name.$DOMAIN_NAME créé."
    done

#TODO : Créer une page confidentielle (.htaccess et .htpasswd)

#TODO : Créer une base de données d'intro

touch bdd/init.sql

echo "USE $DB_NAME;
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
('Faire fonctionner les services php, phpmyadmin, mysql et apache.',2);" > bdd/init.sql

chmod 644 bdd/init.sql


#TODO : Configuration de PhpMyAdmin


#TODO : Configuration de PHP


#TODO : Faire fonctionner les 4 services ensemble.
sudo docker-compose up -d
error_handler $? "Le lancement des services phpmyadmin et mysql a échoué."

#TODO : Installation de Apache
#TODO : Installation PHP

touch apache/Dockerfile

echo "FROM php:apache
RUN apt-get update

RUN docker-php-ext-install mysqli

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

COPY html/ /var/www/html/
COPY apache2.conf /apache2/apache2.conf

EXPOSE 80
CMD [\"apache2-foreground\"]" > apache/Dockerfile
error_handler $? "L'écriture dans le fichier apache/Dockerfile a échouée."

docker build -t web-php-apache ./apache/.
error_handler $? "La construction de l'image web-php-apache a échouée."

docker run -d --name $WEB_CONTAINER_NAME --network $NETWORK_NAME -p 80:80 web-php-apache
error_handler $? "Le lancement de $WEB_CONTAINER_NAME a échoué."

#TODO : Configuration de mysql



# docker exec -it $DB_CONTAINER_NAME mysql -e "USE \$DB_NAME; 
# CREATE TABLE IF NOT EXISTS todo_list(
#     id INT AUTO_INCREMENT PRIMARY KEY,
#     content VARCHAR(255) NOT NULL,
#     statut INT DEFAULT 0
# );
# INSERT INTO todo_list (content, statut) VALUES
# ('Sécuriser le site A.',0),
# ('Sécuriser le site B.',0),
# ('Créer une page secrète.',1),
# ('Faire fonctionner les services php, phpmyadmin, mysql et apache.',2);
# "

#TODO : Sécurisation du serveur web et des sites par HTTPS
#TODO : Sécurisation - Installation et configuration de ModSecurity
#TODO : Sécurisation - Installation et configuration de ModEvasive
#TODO : Sécurisation - Installation et configuration de ModRatelimit


#===================================================================#
# Affichage des adresses IP des conteneurs                          #
#===================================================================#

# Récupérer les adresses IP des conteneurs
WEB_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $WEB_CONTAINER_NAME)
DB_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DB_CONTAINER_NAME)
PHPMYADMIN_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PHPMYADMIN_CONTAINER_NAME)

# Mettre à jour le fichier /etc/hosts
echo "$WEB_CONTAINER_IP siteA.$DOMAIN_NAME" >> /etc/hosts
echo "$WEB_CONTAINER_IP siteB.$DOMAIN_NAME" >> /etc/hosts
echo "$PHPMYADMIN_CONTAINER_IP phpmyadmin.$DOMAIN_NAME" >> /etc/hosts

# Afficher les adresses IP des conteneurs
echo "Adresses IP des conteneurs du réseau docker $NETWORK_NAME :"
echo "$WEB_CONTAINER_NAME :"
echo "   $WEB_CONTAINER_IP siteA.$DOMAIN_NAME"
echo "   $WEB_CONTAINER_IP siteB.$DOMAIN_NAME"
echo "$PHPMYADMIN_CONTAINER_NAME : "
echo "   $PHPMYADMIN_CONTAINER_IP phpmyadmin.$DOMAIN_NAME"
echo "$DB_CONTAINER_NAME :"
echo "   $DB_CONTAINER_IP"
#======================================================================#

logs_end "Installation et configuration des services apache, mysql, php et phpmyadmin sous docker terminée."

#======================================================================#

echo "#!/bin/bash
source ./../.common.sh

# Fonction pour démarrer les services
start_services()
{
  logs_info \"Démarrage des services...\"
  docker start $DB_CONTAINER_NAME
  error_handler \$? \"Le démarrage du service $DB_CONTAINER_NAME a échouée.\"

  docker start $PHPMYADMIN_CONTAINER_NAME
  error_handler \$? \"Le démarrage du service $PHPMYADMIN_CONTAINER_NAME a échouée.\"

  docker start $WEB_CONTAINER_NAME
  error_handler \$? \"Le démarrage du service $WEB_CONTAINER_NAME a échouée.\"

  logs_info \"Services démarrés.\"
}

# Fonction pour arrêter les start_services
stop_services()
{
  logs_info \"Arrêt des services...\"
  docker stop $DB_CONTAINER_NAME
  error_handler \$? \"L'arrêt du service $DB_CONTAINER_NAME a échouée.\"

  docker stop $PHPMYADMIN_CONTAINER_NAME
  error_handler \$? \"L'arrêt du service $PHPMYADMIN_CONTAINER_NAME a échouée.\"

  docker stop $WEB_CONTAINER_NAME
  error_handler \$? \"L'arrêt du service $WEB_CONTAINER_NAME a échouée.\"

  logs_info \"Services arrêtés.\"
}

# Fonction pour redémarrer les services.
restart_services()
{
  logs_info \"Redémarrage des services...\"
  docker stop $DB_CONTAINER_NAME
  error_handler \$? \"Le redémarrage du service $DB_CONTAINER_NAME a échouée.\"

  docker stop $PHPMYADMIN_CONTAINER_NAME
  error_handler \$? \"Le redémarrage du service $PHPMYADMIN_CONTAINER_NAME a échouée.\"

  docker stop $WEB_CONTAINER_NAME
  error_handler \$? \"Le redémarrage du service $WEB_CONTAINER_NAME a échouée.\"

  logs_info \"Services redémarrés.\"
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
    echo \"   \$WEB_CONTAINER_IP siteA.\$DOMAIN_NAME\"
    echo \"   \$WEB_CONTAINER_IP siteB.\$DOMAIN_NAME\"
    echo \"$PHPMYADMIN_CONTAINER_NAME : \"
    echo \"   \$PHPMYADMIN_CONTAINER_IP phpmyadmin.\$DOMAIN_NAME\"
    echo \"$DB_CONTAINER_NAME :\"
    echo \"   \$DB_CONTAINER_IP\"
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
esac
" > manage_services.sh

chmod +x manage_services.sh

exit 0
