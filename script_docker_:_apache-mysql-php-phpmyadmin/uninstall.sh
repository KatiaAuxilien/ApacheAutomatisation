#!/bin/bash
#===================================================================#
#                            Sommaire                               #
#===================================================================#
# 1. Vérifications de l'environnement et des variables              #
# 2. Suppression des données mysql                                  #
# 3. Suppression et arrêts Docker                                   #
#===================================================================#

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
# 1. Vérifications de l'environnement et des variables              #
#===================================================================#

source ./.common.sh

logs_info "Services complexes > Désinstallation en cours ..."

#===================================================================#
# 2. Suppression des données mysql                                  #
#===================================================================#

logs_info "Services complexes > Docker > Suppression des données de la base de données en cours ..."

	DB_PURGE_SQL_QUERIES=$(cat <<EOF
DROP TABLE IF EXISTS todo_list;
EOF
)

	docker exec -i $DB_CONTAINER_NAME mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "$DB_PURGE_SQL_QUERIES" $DB_NAME
	error_handler $? "Services complexes > Docker > Le lancement de la suppression de $DB_CONTAINER_NAME a échoué."

	# Suppression des fichiers de configuration de mysql
	sudo rm -rf mysql
	error_handler $? "Services complexes > Docker > Suppression du dossier mysql a échouée."

logs_success "Services complexes > Docker > Suppression des données de la base de données terminée."

#===================================================================#
# 3. Suppression et arrêts Docker                                   #
#===================================================================#

	sudo rm -rf manage_services.sh
	error_handler $? "Services complexes > Docker > Suppression du fichier manage_services.sh a échouée."

# Arrêt de tout les services
logs_info "Services complexes > Docker > Arrêts des conteneurs en cours ..."

	docker stop $PHPMYADMIN_CONTAINER_NAME
	error_handler $? "Services complexes > Docker > Arrêt du conteneur $PHPMYADMIN_CONTAINER_NAME a échoué."

	docker stop $DB_CONTAINER_NAME
	error_handler $? "Services complexes > Docker > Arrêt du conteneur $DB_CONTAINER_NAME a échoué."

	docker stop $WEB_CONTAINER_NAME
	error_handler $? "Services complexes > Docker > Arrêt du conteneur $WEB_CONTAINER_NAME a échoué."

logs_success "Services complexes > Docker > Arrêts des conteneurs terminé."

logs_info "Services complexes > Docker > Suppression des conteneurs en cours ..."
	# Suppression du conteneur PhpMyAdmin
	docker rm -f $PHPMYADMIN_CONTAINER_NAME
	error_handler $? "Services complexes > Docker > Suppression du conteneur $PHPMYADMIN_CONTAINER_NAME a échouée."

	# Suppression du conteneur mysql
	docker rm -f $DB_CONTAINER_NAME
	error_handler $? "Services complexes > Docker > Suppression du conteneur $DB_CONTAINER_NAME a échouée."

	# Suppression du conteneur Apache et PHP
	docker rm -f $WEB_CONTAINER_NAME
	error_handler $? "Services complexes > Docker > Suppression du conteneur $WEB_CONTAINER_NAME a échouée."

logs_success "Services complexes > Docker > Suppression des conteneurs terminée."

logs_info "Services complexes > Docker > Réinitialisation en cours ..."
	# Suppression du network docker
	docker network rm $NETWORK_NAME
	error_handler $? "Services complexes > Docker > Suppression du réseau $NETWORK_NAME a échouée."

	# Suppression des images des services
	sudo docker rmi web-php-apache
	error_handler $? "Services complexes > Docker > Suppression des images a échouée."

logs_success "Services complexes > Docker > Réinitialisation terminée."

# Suppression des lignes faisant le lien adresse ip nom de domaine dans etc/hosts
logs_info "Services complexes > hosts > Réinitialisation en cours ..."

	sed -i "/$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "Services complexes > hosts > Suppression de la ligne $DOMAIN_NAME dans etc/hosts a échouée."

	sed -i "/siteA.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "Services complexes > hosts > Suppression de la ligne siteA.$DOMAIN_NAME dans /etc/hosts a échouée."
	
	sed -i "/siteB.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "Services complexes > hosts > Suppression de la ligne siteB.$DOMAIN_NAME dans /etc/hosts a échouée."

	sed -i "/phpmyadmin.$DOMAIN_NAME/d" /etc/hosts
	error_handler $? "Services complexes > hosts > Suppression de la ligne phpmyadmin.$DOMAIN_NAME dans etc/hosts a échouée."

logs_success "Services complexes > hosts > Réinitialisation terminée."
#===================================================================#

logs_end "Services complexes > Docker > Désinstallation terminée."
exit 0