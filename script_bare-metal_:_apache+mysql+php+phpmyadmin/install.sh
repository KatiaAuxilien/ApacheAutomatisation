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


#TODO : Messages de logs
#TODO : Vérification du lancement en droits admin
#TODO : Vérification des variables fournies dans le .env

#TODO : Installation de Apache
#TODO : Configuration de Apache

#TODO : Installation PHP
#TODO : Configuration de PHP

#TODO : Installation mysql
#TODO : Configuration de mysql

#TODO : Installation PhpMyAdmin
#TODO : Configuration de PhpMyAdmin

#TODO : Faire fonctionner les 4 services ensemble.

#TODO : Création de deux sites (siteA, siteB)
#TODO : Créer une page confidentielle (.htaccess et .htpasswd)

#TODO : Créer une base de données d'intro

#TODO : Sécurisation du serveur web et des sites par HTTPS
#TODO : Sécurisation - Installation et configuration de ModSecurity
#TODO : Sécurisation - Installation et configuration de ModEvasive
#TODO : Sécurisation - Installation et configuration de ModRatelimit