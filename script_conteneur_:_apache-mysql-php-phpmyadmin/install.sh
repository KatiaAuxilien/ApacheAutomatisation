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

mkdir mysql_data apache2 www

#TODO : Messages de logs
#TODO : Vérification du lancement en droits admin
#TODO : Vérification des variables fournies dans le .env
#TODO : Vérification de l'installation de docker


#===================================================================#
# Préparation pour docker                                           #
#===================================================================#

# Création du réseau docker
sudo docker network create $NETWORK_NAME
error_handler $? " La création du réseau docker $NETWORK_NAME a échouée."

#TODO : Installation de Apache
#TODO : Installation PHP
#TODO : Installation mysql
#TODO : Installation PhpMyAdmin

touch docker-compose.yml

# ports:
#   - \"$DB_PORT:3306\"
#   depends_on:
# - $DB_CONTAINER_NAME
#      - ./apache2:/etc/apache2/
  # $WEB_CONTAINER_NAME:
  #   build: Dockerfile
  #   container_name: $WEB_CONTAINER_NAME
  #   ports:
  #     - \"$WEB_PORT:80\"
  #   networks:
  #     - $NETWORK_NAME

echo "
services:
  $DB_CONTAINER_NAME:
    image: mysql:5.7
    container_name: $DB_CONTAINER_NAME
    environment:
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_ADMIN_USERNAME
      MYSQL_PASSWORD: $DB_ADMIN_PASSWORD
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - $NETWORK_NAME

  $PHPMYADMIN_CONTAINER_NAME:
    image: phpmyadmin/phpmyadmin
    container_name: $PHPMYADMIN_CONTAINER_NAME
    environment:
      PMA_HOST: $DB_CONTAINER_NAME
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      PMA_USER: $PHPMYADMIN_ADMIN_USERNAME
      PMA_PASSWORD: $PHPMYADMIN_ADMIN_PASSWORD
    ports:
      - \"$PHPMYADMIN_PORT:80\"
    networks:
      - $NETWORK_NAME

  $WEB_CONTAINER_NAME:
    build: .
    container_name: $WEB_CONTAINER_NAME
    ports:
      - \"$WEB_PORT:80\"
    networks:
      - $NETWORK_NAME

volumes:
  mysql_data:

networks:
  $NETWORK_NAME:
    external: true" > docker-compose.yml
error_handler $? "L'écriture du fichier docker-compose.yml a échouée."

#TODO : Configuration de Apache
touch Dockerfile

echo "
FROM debian:buster-slim

RUN apt-get update &&\
    apt-get install -y apache2 libapache2-mod-php php php-mysql &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

COPY www /var/www/html

EXPOSE 80

CMD [\"apachectl\",\"-D\", \"FOREGROUND\"]
" > Dockerfile

#TODO : Configuration de PHP
#TODO : Configuration de mysql
#TODO : Configuration de PhpMyAdmin

#TODO : Faire fonctionner les 4 services ensemble.
sudo docker-compose up -d

#TODO : Création de deux sites (siteA, siteB)
#TODO : Créer une page confidentielle (.htaccess et .htpasswd)

#TODO : Créer une base de données d'intro

#TODO : Sécurisation du serveur web et des sites par HTTPS
#TODO : Sécurisation - Installation et configuration de ModSecurity
#TODO : Sécurisation - Installation et configuration de ModEvasive
#TODO : Sécurisation - Installation et configuration de ModRatelimit


#===================================================================#
# Affichage des adresses IP des conteneurs                          #
#===================================================================#

# Afficher les adresses IP des conteneurs
# logs_info "Adresses IP des conteneurs :"
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $WEB_CONTAINER_NAME
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DB_CONTAINER_NAME
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PHPMYADMIN_CONTAINER_NAME

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
