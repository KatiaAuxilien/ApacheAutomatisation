#!/bin/bash

#======================================================================#
source ./../.common.sh
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
# Suppression et arrêts Docker                                      #
#===================================================================#

sudo rm -rf manage_services.sh

# Arrêt de tout les services
docker stop $PHPMYADMIN_CONTAINER_NAME
docker stop $DB_CONTAINER_NAME
docker stop $WEB_CONTAINER_NAME

# Suppression du conteneur PhpMyAdmin
docker rm -f $PHPMYADMIN_CONTAINER_NAME

# Suppression du conteneur mysql
docker rm -f $DB_CONTAINER_NAME

# Suppression du conteneur Apache et PHP
docker rm -f $WEB_CONTAINER_NAME

#TODO : Suppression du network docker
docker network rm $NETWORK_NAME

#TODO : Suppression des images des services
sudo docker rmi web-php-apache

#TODO : Suppression des fichiers de configuration HTTPS
#TODO : Suppression des fichiers de configuration de ModSecurity
#TODO : Suppression des fichiers de configuration  de ModEvasive
#TODO : Suppression des fichiers de configuration de ModRatelimit
#TODO : Suppression des fichiers de configuration des deux sites (siteA, siteB)
#TODO : Suppression des fichiers de configuration de la page confidentielle (.htaccess et .htpasswd)

# Suppression des fichiers de configuration de Apache
sudo rm -rf html
sudo rm -rf apache
sudo rm -rf Dockerfile

# Suppression des fichiers de configuration de mysql
sudo rm -rf mysql_data

#TODO : Suppression des fichiers de configuration de PhpMyAdmin

# Suppression des fichiers de configuration de PHP
sudo rm -rf docker-compose.yml

#TODO : Suppression de la base de données d'intro

sudo rm -rf init.sql