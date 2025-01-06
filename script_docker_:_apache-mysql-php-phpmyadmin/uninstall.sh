#!/bin/bash

# .·:'''''''''''''''''''''''''''''''''''''''''''''':·.
# : :  ____                       _                : :
# : : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___  : :
# : : | |_) / _` | '_ ` _ \| '_ \| | | | / __/ __| : :
# : : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \ : :
# : : |_|  _\__,_|_| |_|_|_| .__/|_|\__,_|___/___/ : :
# : :   __| | ___   ___| | |_|__ _ __              : :
# : :  / _` |/ _ \ / __| |/ / _ \ '__|             : :
# : : | (_| | (_) | (__|   <  __/ |                : :
# : :  \__,_|\___/ \___|_|\_\___|_|                : :
# '·:..............................................:·'

#===================================================================#
#                            Sommaire                               #
#===================================================================#
# 1. Vérifications de l'environnement et des variables              #
# 2. Suppression des données mysql                                  #
# 3. Suppression et arrêts Docker                                   #
#===================================================================#

#===================================================================#
source ./../.common.sh
#===================================================================#

welcome ".·:'''''''''''''''''''''''''''''''''''''''''''''':·."
welcome ": :  ____                       _                : :"
welcome ": : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___  : :"
welcome ": : | |_) / _\` | '_ \` _ \| '_ \| | | | / __/ __| : :"
welcome ": : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \ : :"
welcome ": : |_|  _\__,_|_| |_|_|_| .__/|_|\__,_|___/___/ : :"
welcome ": :   __| | ___   ___| | |_|__ _ __              : :"
welcome ": :  / _\` |/ _ \ / __| |/ / _ \ '__|             : :"
welcome ": : | (_| | (_) | (__|   <  __/ |                : :"
welcome ": :  \__,_|\___/ \___|_|\_\___|_|                : :"
welcome "'·:..............................................:·'"

#===================================================================#

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

# Demander la confirmation de désinstallation
while true; do
    read -p "Êtes-vous sûr de vouloir lancer la désinstallation ? Tapez 'yes' pour confirmer : " confirmation
    if [[ "$confirmation" =~ ^[yY][eE][sS]$ ]]; then
        break
    else
        exit 0
    fi
done

#===================================================================#
# 1. Vérifications de l'environnement et des variables              #
#===================================================================#

source ./.common.sh

logs_info "Vérification des services installés ..."

error_count=0

	if [ $mysql_installed -eq 0 ]; then
	    logs_error "Aucun conteneur avec l'image bitnami/mysql:latest trouvé."
	    let error_count++
	fi

	if [ $phpmyadmin_installed -eq 0 ]; then
	    logs_error "Aucun conteneur avec l'image phpmyadmin/phpmyadmin trouvé."
	    let error_count++
	fi

	if [ $apache_installed -eq 0 ]; then
	    logs_error "Aucun conteneur avec l'image debian:latest trouvé."
	    let error_count++
	fi

	if [ $db_container_name_exists -eq 0 ]; then
	    logs_error "Aucun conteneur avec le nom $DB_CONTAINER_NAME trouvé."
	    let error_count++
	fi

	if [ $phpmyadmin_container_name_exists -eq 0 ]; then
	    logs_error "Aucun conteneur avec le nom $PHPMYADMIN_CONTAINER_NAME trouvé."
	    let error_count++
	fi

	if [ $web_container_name_exists -eq 0 ]; then
	    logs_error "Aucun conteneur avec le nom $WEB_CONTAINER_NAME trouvé."
	    let error_count++
	fi

if [ $error_count -ne 0 ]
  exit 1
fi

logs_success "Vérification réussie, les services sont installés."

logs_info "Désinstallation en cours ..."

#===================================================================#
# 2. Suppression des données mysql                                  #
#===================================================================#

logs_info "Docker > Suppression des données de la base de données en cours ..."

	DB_PURGE_SQL_QUERIES=$(cat <<EOF
DROP TABLE IF EXISTS todo_list;
EOF
)

	run_command docker exec -i $DB_CONTAINER_NAME mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "$DB_PURGE_SQL_QUERIES" $DB_NAME
	error_handler $? "Docker > Le lancement de la suppression de $DB_CONTAINER_NAME a échoué."

	# Suppression des fichiers de configuration de mysql
	run_command sudo rm -rf mysql
	error_handler $? "Docker > Suppression du dossier mysql a échouée."

logs_success "Docker > Suppression des données de la base de données terminée."

#===================================================================#
# 3. Suppression et arrêts Docker                                   #
#===================================================================#

	sudo rm -rf manage_services.sh
	error_handler $? "Docker > Suppression du fichier manage_services.sh a échouée."

# Arrêt de tout les services
logs_info "Docker > Arrêts des conteneurs en cours ..."

	run_command docker stop $PHPMYADMIN_CONTAINER_NAME
	error_handler $? "Docker > Arrêt du conteneur $PHPMYADMIN_CONTAINER_NAME a échoué."

	run_command docker stop $DB_CONTAINER_NAME
	error_handler $? "Docker > Arrêt du conteneur $DB_CONTAINER_NAME a échoué."

	run_command docker stop $WEB_CONTAINER_NAME
	error_handler $? "Docker > Arrêt du conteneur $WEB_CONTAINER_NAME a échoué."

logs_success "Docker > Arrêts des conteneurs terminé."

logs_info "Docker > Suppression des conteneurs en cours ..."
	# Suppression du conteneur PhpMyAdmin
	run_command docker rm -f $PHPMYADMIN_CONTAINER_NAME
	error_handler $? "Docker > Suppression du conteneur $PHPMYADMIN_CONTAINER_NAME a échouée."

	# Suppression du conteneur mysql
	run_command docker rm -f $DB_CONTAINER_NAME
	error_handler $? "Docker > Suppression du conteneur $DB_CONTAINER_NAME a échouée."

	# Suppression du conteneur Apache et PHP
	run_command docker rm -f $WEB_CONTAINER_NAME
	error_handler $? "Docker > Suppression du conteneur $WEB_CONTAINER_NAME a échouée."

logs_success "Docker > Suppression des conteneurs terminée."

logs_info "Docker > Réinitialisation en cours ..."
	# Suppression du network docker
	run_command docker network rm $NETWORK_NAME
	error_handler $? "Docker > Suppression du réseau $NETWORK_NAME a échouée."

	# Suppression des images des services
	run_command sudo docker rmi web-php-apache
	error_handler $? "Docker > Suppression des images a échouée."

logs_success "Docker > Réinitialisation terminée."

# Suppression des lignes faisant le lien adresse ip nom de domaine dans etc/hosts
logs_info "hosts > Réinitialisation en cours ..."

	run_command sed -i "/$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne $DOMAIN_NAME dans etc/hosts a échouée."

	run_command sed -i "/siteA.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne siteA.$DOMAIN_NAME dans /etc/hosts a échouée."
	
	run_command sed -i "/siteB.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne siteB.$DOMAIN_NAME dans /etc/hosts a échouée."

	run_command sed -i "/phpmyadmin.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "hosts > Suppression de la ligne phpmyadmin.$DOMAIN_NAME dans etc/hosts a échouée."

logs_success "hosts > Réinitialisation terminée."
#===================================================================#

logs_end "Docker > Désinstallation terminée."
exit 0