#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

#Logs

error_handler()
{
	if [ $1 -ne 0 ]
	then
		echo -e "${RED}Erreur : $2 ${RESET}"
		exit $1
	fi
}

logs()
{
	local color="$1"
	shift
	date_formated=$(date +"%d-%m-%Y %H:%M:%S")
	echo -e "${color}[$date_formated] $1 ${RESET}" | tee -a /var/log/apache_install.log
}

logs_info()
{
	logs "$YELLOW" "$*"
}

logs_success()
{
	logs "$GREEN" "$*"
}

logs_end()
{
	logs "$BLUE" "$*"
}


# Fonction pour vérifier si une variable est définie
check_variable() {
  local var_name=$1
  if [ -z "${!var_name+x}" ]; then
    echo "La variable $var_name n'est pas définie."
    exit 2
  fi
}


required_vars_start=(
  "PROD"
  "DOMAIN_NAME"
  "WEB_ADMIN_ADDRESS"
  "PHP_ADMIN_ADDRESS"
  "DB_ADMIN_ADDRESS"
  "KEY_PASSWORD"
  "ENC_PASSWORD"
  "DB_ROOT_PASSWORD"
)

required_vars_script=(
  "WEB_SERVICE_URL"
  "DB_HOST"
  "DB_SERVICE_URL"
  "DB_TYPE"
  "DB_PORT"
  "DB_USERNAME"
  "DB_PASSWORD"
  "DB_NAME"
)


required_vars_prod=(
  "PROD_WEB_SERVICE_URL"
  "PROD_DB_HOST"
  "PROD_DB_SERVICE_URL"
  "PROD_DB_PORT"
  "PROD_DB_USERNAME"
  "PROD_DB_PASSWORD"
  "PROD_DB_NAME"
)

required_vars_dev=(
  "DEV_WEB_SERVICE_URL"
  "DEV_DB_HOST"
  "DEV_DB_SERVICE_URL"
  "DEV_DB_PORT"
  "DEV_DB_USERNAME"
  "DEV_DB_PASSWORD"
  "DEV_DB_NAME"
)

#TODO : Utiliser les variables de .env
#TODO : Gérer l'adresse mail des admin pour chaque services.

# Vérifier chaque variable nécessaire
# for var in "${required_vars_start[@]}"; do
#   check_variable "$var"
# done

# if [$PROD -eq "TRUE"]
# then
# 	for var in "${required_vars_prod[@]}"; do
# 	  check_variable "$var"
# 	done
# 	WEB_SERVICE_URL = "$PROD_WEB_SERVICE_URL"
# 	DB_HOST = "$PROD_DB_HOST"
# 	DB_SERVICE_URL = "$PROD_DB_SERVICE_URL"
# 	DB_PORT = "$PROD_DB_PORT"
# 	DB_USERNAME = "$PROD_DB_USERNAME"
# 	DB_PASSWORD = "$PROD_DB_PASSWORD"
# 	DB_NAME = "$PROD_DB_NAME"
# else
# 	for var in "${required_vars_dev[@]}"; do
# 	  check_variable "$var"
# 	done
# 	WEB_SERVICE_URL = "$DEV_WEB_SERVICE_URL"
# 	DB_HOST = "$DEV_DB_HOST"
# 	DB_SERVICE_URL = "$DEV_DB_SERVICE_URL"
# 	DB_PORT = "$DEV_DB_PORT"
# 	DB_USERNAME = "$DEV_DB_USERNAME"
# 	DB_PASSWORD = "$DEV_DB_PASSWORD"
# 	DB_NAME = "$DEV_DB_NAME"
# fi

# for var in "${required_vars_script[@]}"; do
#   check_variable "$var"
# done

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer avant de continuer.${RESET}"
    exit 1
fi


if [ "$EUID" -ne 0 ]
then
	echo -e "${RED}Ce script doit être exécuté avec des privilèges root.${RESET}"
	exit 1
fi


# echo -n "Entrez le nom du container docker : "
# read container_name
# echo -n "Confirmez le nom du container docker  : "
# read confirm_container_name
# if [ "$container_name" != "$confirm_container_name" ]; then
# 	echo -e "${RED}Les noms de container docker ne correspondent pas.${RESET}"
# 	exit 1
# fi


#Création des fichiers de configuration

	echo "
ServerRoot \"/etc/apache2\"

ServerName 127.0.0.1

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

IncludeOptional sites-enabled/*.conf" > /src/apache2/apache2.conf

	error_handler $? "L'écriture du fichier de configuration apache a échouée."

	echo "
<VirtualHost *:79>
	RewriteEngine On
	RewriteCond %{HTTPS} !=on
	RewriteRule ^/?(.*) https://%SERVER_NAME/$1 [R=301,L]
</VirtualHost>
<VirtualHost *:443>
	ServerAdmin $admin_address
	ServerName $domain_name
	ServerAlias localhost
	DocumentRoot /var/www/html
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
	SSLEngine on
	SSLCertificateFile /etc/apache2/certificate/"$domain_name"_server.crt
	SSLCertificateKeyFile /etc/apache2/certificate/"$domain_name"_server.key
</VirtualHost>" > /src/apache2/sites-enabled/000-default.conf
	
	error_handler $? "L'écriture du fichier de configuration du site par défaut a échouée."
	
	echo "
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen 79

<IfModule ssl_module>
	Listen 443
</IfModule>

<IfModule mod_gnutls.c>
	Listen 443
</IfModule>" > /src/apache2/ports.conf 
	error_handler $? "L'écriture du fichier de configuration des ports a échouée."



	sudo apt-get install -y openssl
	error_handler $? "L'installation d'openssl a échouée."

	mkdir /etc/apache2/certificate
	error_handler $? "La création du dossier /etc/apache2/certificate a échouée."
	cd /etc/apache2/certificate
	
	sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out /etc/apache2/certificate/"$domain_name"_server.crt -keyout /etc/apache2/certificate/"$domain_name"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$domain_name/emailAddress=$admin_address" -passin pass:"$key_password"
	error_handler $? "La génération de demande de signature de certifcat a échouée"

	openssl x509 -in "$domain_name"_server.crt -text -noout
	error_handler $? "La vérification du certificat a échouée."
	
	cd

	sudo chmod 600 /etc/apache2/certificate/"$domain_name"_server.key
	sudo chown root:root /etc/apache2/certificate/"$domain_name"_server.crt
	sudo chmod 440 /etc/apache2/certificate/"$domain_name"_server.crt








docker-compose --env-file .env up --build -d
error_handler $? "Le build du conteneur a échoué."


error_handler $? "Le lancement du conteneur a échoué."


log_success "Conteneur Docker lancé avec succès."

log_success "Votre serveur Apache est opérationnel."
