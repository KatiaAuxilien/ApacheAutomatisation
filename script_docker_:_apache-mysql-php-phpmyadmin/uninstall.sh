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
"DB_VOLUME_NAME"
)

#===================================================================#
# Vérifications de l'environnement et des variables                 #
#===================================================================#

source ./.common.sh

#===================================================================#
# Suppression des données mysql                                     #
#===================================================================#

DB_PURGE_SQL_QUERIES=$(cat <<EOF
DROP TABLE IF EXISTS todo_list;
EOF
)

docker exec -i $DB_CONTAINER_NAME mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "$DB_PURGE_SQL_QUERIES" $DB_NAME
error_handler $? "Le lancement de l'initialisation de $DB_CONTAINER_NAME a échoué."

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

# Suppression des lignes faisant le lien adresse ip nom de domaine dans etc/hosts
sed -i "/$DOMAIN_NAME/d" /etc/hosts
sed -i "/phpmyadmin.$DOMAIN_NAME/d" /etc/hosts

# Suppression des fichiers de configuration de mysql
sudo rm -rf mysql

#TODO : Suppression des fichiers de configuration de PhpMyAdmin
