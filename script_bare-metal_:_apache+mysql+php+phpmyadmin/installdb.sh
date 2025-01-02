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

sudo apt update -y

#TODO : Messages de logs
#TODO : Vérification du lancement en droits admin
#TODO : Vérification des variables fournies dans le .env

#===================================================================#
# Installation de Apache                                            #
#===================================================================#

# sudo apt update -y
# error_handler $? "La mise à jour des paquets a échouée."

#===================================================================#
# Installation de PHP                                               #
#===================================================================#
#TODO : Installation PHP
#TODO : Configuration de PHP

# https://ubuntu.com/server/docs/how-to-install-and-configure-php

# sudo apt install -y php php-mysql
# error_handler $? "L'installation du service php et php-mysql a échouée."

#===================================================================#
# Installation et configuration de mysql                            #
#===================================================================#
#TODO : Installation mysql
#TODO : Configuration de mysql

# https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04

sudo apt install mysql-server -y
  error_handler $? "sudo apt install mysql-server -y a échoué."

sudo systemctl start mysql.service
  error_handler $? "sudo systemctl start mysql.service a échoué."


DB_INIT_SQL_QUERIES=$(cat <<EOF
  UPDATE mysql.user SET Password=PASSWORD('$DB_ADMIN_PASSWORD') WHERE User='root';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
EOF
)

sudo mysql --user=root -e "$DB_INIT_SQL_QUERIES"

  error_handler $? "mysql --user=root <<_EOF_ a échoué."

#TODO : Créer une base de données d'intro
sudo mysql -u'root' -p$DB_ADMIN_PASSWORD -e "CREATE DATABASE '$DB_NAME'";
  error_handler $? "sudo mysql -u'root' -p\$DB_ADMIN_PASSWORD -e \"CREATE DATABASE '$DB_NAME'\"; a échoué."


sudo mysql -u'root' -p$DB_ADMIN_PASSWORD -e "CREATE USER '$DB_ADMIN_USERNAME'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$DB_ADMIN_PASSWORD';"
  error_handler $? "sudo mysql -u'root' -p\$DB_ADMIN_PASSWORD -e \"CREATE USER '\$DB_ADMIN_USERNAME'@'localhost' IDENTIFIED WITH caching_sha2_password BY '\$DB_ADMIN_PASSWORD';\" a échoué."


sudo mysql -u'root' -p$DB_ADMIN_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_ADMIN_USERNAME'@'host' WITH GRANT OPTION;"
  error_handler $? "sudo mysql -u'root' -p\$DB_ADMIN_PASSWORD -e \"GRANT ALL PRIVILEGES ON $DB_NAME.* TO '\$DB_ADMIN_USERNAME'@'host' WITH GRANT OPTION;\" a échoué."


# Préconfigurer les réponses pour mysql_secure_installation
debconf-set-selections <<EOF
mysql-server mysql-server/root_password password your_root_password
mysql-server mysql-server/root_password_again password your_root_password
mysql-server mysql-server/remove_test_db boolean true
mysql-server mysql-server/disallow_root_login boolean true
mysql-server mysql-server/remove_anonymous_users boolean true
EOF

# Exécuter mysql_secure_installation sans interaction
sudo mysql_secure_installation <<EOF

Y
your_root_password
your_root_password
Y
Y
Y
Y
EOF

# Démarrer et activer MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Se connecter à MySQL et créer une base de données et un utilisateur
sudo mysql -u root -pyour_root_password <<EOF
CREATE DATABASE nom_de_la_base_de_donnees;
CREATE USER 'nom_utilisateur'@'localhost' IDENTIFIED BY 'mot_de_passe';
GRANT ALL PRIVILEGES ON nom_de_la_base_de_donnees.* TO 'nom_utilisateur'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF








# Créer une base de données d'intro
DB_INIT_SQL_QUERIES=$(cat <<EOF
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
('Faire fonctionner les services php, phpmyadmin, mysql et apache.',2);
EOF
)



logs_info "MySQL > Initialisation de la base de données $DB_NAME."
  
  sudo mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "$DB_INIT_SQL_QUERIES" $DB_NAME
  error_handler $? "Le lancement de l'initialisation de $DB_NAME a échoué."

logs_success "MySQL > Base de données $DB_NAME initialisée."

#===================================================================#
# Installation de PhpMyAdmin                                        #
#===================================================================#
#TODO : Installation PhpMyAdmin
#TODO : Configuration de PhpMyAdmin

# https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-on-ubuntu-20-04
# https://ubuntu.com/server/docs/how-to-install-and-configure-phpmyadmin

#TODO : Faire fonctionner les 4 services ensemble.




sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
