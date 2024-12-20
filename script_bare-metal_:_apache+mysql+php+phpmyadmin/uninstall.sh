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
# Prépartion de l'arborescence                                      #
#===================================================================#


#TODO : Messages de logs
#TODO : Vérification du lancement en droits admin

#TODO : Arrêt de tout les services

#TODO : Suppression des fichiers de configuration de Apache
#TODO : Suppression des fichiers de configuration HTTPS
#TODO : Suppression des fichiers de configuration de ModSecurity
#TODO : Suppression des fichiers de configuration  de ModEvasive
#TODO : Suppression des fichiers de configuration de ModRatelimit
#TODO : Suppression de la configuration des deux sites (siteA, siteB)
#TODO : Suppression de la configuration de la page confidentielle (.htaccess et .htpasswd)
#TODO : Désinstallation de Apache

#TODO : Désinstallation PHP
#TODO : Suppression des fichiers de configuration de PHP

#TODO : Désinstallation mysql
#TODO : Suppression des fichiers de configuration de mysql

#TODO : Désinstallation PhpMyAdmin
#TODO : Suppression des fichiers de configuration de PhpMyAdmin


#TODO : Suppression de la base de données d'intro