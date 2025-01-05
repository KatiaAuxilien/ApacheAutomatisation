#!/bin/bash

#======================================================================#
source ../.common.sh
#======================================================================#

required_vars_start=(
"DOMAIN_NAME"
"WEB_ADMIN_ADDRESS"
"WEB_PORT"
"WEB_ADMIN_USER"
"WEB_ADMIN_PASSWORD"
"SSL_KEY_PASSWORD"

"PHPMYADMIN_HTACCESS_PASSWORD"
"PHPMYADMIN_ADMIN_ADDRESS"
"PHPMYADMIN_ADMIN_USERNAME"
"PHPMYADMIN_ADMIN_PASSWORD"

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

# Vérification du lancement en droits admin
source ./.common.sh
#TODO : Vérification des variables fournies dans le .env

#===================================================================#
# Prépartion de l'arborescence                                      #
#===================================================================#

logs_info "Services complexes > Mise à jour des paquets en cours ..."
    sudo apt update -y
    error_handler $? "Services complexes > La mise à jour des paquets a échouée."
logs_success "Services complexes > Mise à jour des paquets terminée."

#===================================================================#
# Installation et configuration de mysql                            #
#===================================================================#
logs_info "Services complexes > MySQL > Installation et configuration avancée en cours ..."

    logs_info "Services complexes > MySQL > Installation en cours ..."
        sudo apt-get install -y mysql-server
        error_handler $? "Services complexes > MySQL > L'installation a échouée."
    logs_success "Services complexes > MySQL > Installation terminée."

    # Configuration sécurisée de mysql
    logs_info "Services complexes > MySQL > Configuration sécurisée en cours ..."
        sudo mysql_secure_installation <<EOF

Y
$DB_ADMIN_PASSWORD
$DB_ADMIN_PASSWORD
Y
Y
Y
Y
EOF
        error_handler $? "Services complexes > MySQL > Changement du port par défaut a échoué."
    logs_success "Services complexes > MySQL > Configuration sécurisée terminée."

    # Changer le port MySQL
    logs_info "Services complexes > MySQL > Configuration du port en cours ..."
        sudo sed -i "s/^port\s*=\s*3306/port = $DB_PORT/" /etc/mysql/mysql.conf.d/mysqld.cnf
        error_handler $? "Services complexes > MySQL > Changement du port par défaut a échoué."
    logs_success "Services complexes > MySQL > Configuration du port terminée."

    # Redémarrer MySQL pour appliquer les changements
    logs_info "Services complexes > MySQL > Redémarrage du service en cours ..."
        sudo systemctl restart mysql
        error_handler $? "Services complexes > MySQL > Le redémarrage du service a échoué."
    logs_success "Services complexes > MySQL > Redémarrage du service terminée."

    # Créer la base de données et l'utilisateur admin
    logs_info "Services complexes > MySQL > Initialisation de la base de données $DB_NAME et création des utilisateurs en cours ..."

        sudo mysql -u root -p$DB_ADMIN_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER '$DB_ADMIN_USERNAME'@'localhost' IDENTIFIED BY '$DB_ADMIN_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_ADMIN_USERNAME'@'localhost';
FLUSH PRIVILEGES;

USE $DB_NAME;
CREATE TABLE IF NOT EXISTS todo_list (
    id INT AUTO_INCREMENT PRIMARY KEY,
    content VARCHAR(255) NOT NULL,
    statut INT DEFAULT 0
);

INSERT INTO todo_list (content, statut) VALUES
('Sécuriser le site A.', 0),
('Sécuriser le site B.', 0),
('Créer une page secrète.', 1),
('Faire fonctionner les services php, phpmyadmin, mysql et apache.', 2);

CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost';
FLUSH PRIVILEGES;
EOF
        error_handler $? "Services complexes > MySQL > Le lancement de l'initialisation de $DB_NAME et création des utilisateurs a échoué."

    logs_success "Services complexes > MySQL > Initialisation de la base de données $DB_NAME et création des utilisateurs terminée."

logs_success "Services complexes > MySQL > Installation et configuration avancée terminée."
