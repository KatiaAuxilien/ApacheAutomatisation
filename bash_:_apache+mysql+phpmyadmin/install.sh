#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

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

if [ "$EUID" -ne 0 ]
then
	echo -e "${RED}Ce script doit être exécuté avec des privilèges root.${RESET}"
	exit 1
fi

echo -n "Entrez le nom de domaine de votre site suivi de son extension de domaine : "
read domain_name
echo -n "Confirmez le nom de domaine : "
read confirm_domain_name
if [ "$domain_name" != "$confirm_domain_name" ]; then
	echo "${RED}Les noms de domaine ne correspondent pas.${RESET}"
	exit 1
fi
logs_success "Nom de domaine enregistré."

echo -n "Entrez l'adresse mail de votre administrateur : "
read admin_address
echo -n "Confirmez l'adresse mail : "
read confirm_address
if [ "$admin_address" != "$confirm_address" ]; then
	echo "${RED}Les adresses ne correspondent pas.${RESET}"
	exit 1
fi

logs_success "Adresse mail enregistrée."

echo "Entrez un mot de passe pour protéger la clé privée : "
read -s key_password
echo "Confirmez le mot de passe : "
read -s confirm_password
if [ "$key_password" != "$confirm_password" ]; then
	echo "${RED}Les mots de passe ne correspondent pas.${RESET}"
	exit 1
fi
logs_success "Mot de passe enregistré."
#TODO : Fonction pour gérer les entrées.

#Installation du service

logs_info "Installation du service apache en cours ..."

sudo apt update -y
error_handler $? "La mise à jour des paquets a échouée."

sudo apt install -y apache2
error_handler $? "L'installation du service a échouée."

sudo ufw allow 'Apache'
error_handler $? "L'autorisation du service apache auprès du pare-feu a échouée."

logs_success "Installation du service apache terminée."

#Lancement du service

logs_info "Lancement du service apache en cours..."

sudo systemctl start apache2
error_handler $? "Le lancement du service apache a échouée."
	
logs_success "Service apache lancé."

#Configuration du service (HTTPS, ModSecurity, ModEvasive, mod_ratelimit, .htaccess & masquage dans l'url des noms de dossier.)

logs_info "Configuration du service apache en cours..."
	
	sudo chmod -R 755 /var/www
	error_handler $? "Attribution des privilèges 755 au dossier /var/www a échouée."

	sudo apt-get install -y openssl
	error_handler $? "L'installation d'openssl a échouée."

	sudo a2enmod ssl
	error_handler $? "L'activation du module Mod_ssl a échouée."

	a2ensite default-ssl
	error_handler $? "L'activation du module default_ssl a échouée."

	sudo a2enmod rewrite
	error_handler $? "L'activation du module Mod_rewrite a échouée."

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

IncludeOptional sites-enabled/*.conf" > /etc/apache2/apache2.conf

	error_handler $? "L'écriture du fichier de configuration apache a échouée."

	echo "
<IfModule mod_dir.c>
        DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
</IfModule>" > /etc/apache2/mods-enabled/dir.conf

	error_handler $? "L'écriture du fichier de configuration apache /etc/apache2/mods-enabled/dir.conf a échouée."

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
</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf

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
</IfModule>" > /etc/apache2/ports.conf 
	error_handler $? "L'écriture du fichier de configuration des ports a échouée."

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

#Sécurisation : .htaccess & masquage dans l'url des noms de dossier.
	
	logs_info "Sécurisation du .htaccess ..."
		
		touch /var/www/.htpasswd
		error_handler $? "La création du fichier /var/www/.htpasswd a échouée."

		echo -n "Entrez un mot de passe chiffré (.htpasswd) : "
		read password

		echo "admin:$password" > /var/www/.htpasswd
		error_handler $? "L'écriture dans le fichier /var/www/.htpasswd a échouée."

#Création et configuration de n sites
	for site_name in siteA siteB
	do
		logs_info "Création du site " $site_name "..."
		
		sudo mkdir /var/www/$site_name
		error_handler $? "La création du dossier /var/www/$site_name a échouée."
		
		sudo chown -R $USER:$USER /var/www/$site_name
		error_handler $? "L'attribution des droits sur le dossier /var/www/$site_name a échouée."
		
		sudo touch /var/www/$site_name/index.html
		error_handler $? "La création du fichier /var/www/$site_name/index.html a échouée."
		
		echo "
<html>
	<head>
		<title>Bienvenue sur le " $site_name " !</title>
	</head>
	<body>
		<h1> N'allez pas sur l'autre site, ce site est malveillant !</h1>
	</body>
</html>" > /var/www/$site_name/index.html
		error_handler $? "L'écriture dans le fichier /var/www/$site_name/index.html a échouée."
		cd /etc/apache2/certificate

		sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out /etc/apache2/certificate/"$site_name"".""$domain_name"_server.crt -keyout /etc/apache2/certificate/"$site_name"".""$domain_name"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$site_name.$domain_name/emailAddress=$admin_address" -passin pass:"$key_password"
		error_handler $? "La génération de demande de signature de certifcat du site $site_name a échouée"

		openssl x509 -in "$site_name"".""$domain_name"_server.crt -text -noout
		error_handler $? "La vérification du certificat a échouée."
		
		cd

		sudo chmod 600 /etc/apache2/certificate/"$site_name"".""$domain_name"_server.key
		sudo chown root:root /etc/apache2/certificate/"$site_name"".""$domain_name"_server.crt
		sudo chmod 440 /etc/apache2/certificate/"$site_name"".""$domain_name"_server.crt

		#Création des Virtual Host
		touch /etc/apache2/sites-available/$site_name.conf
		error_handler $? "La création du fichier /etc/apache2/sites-available/$site_name.conf a échouée."

		echo "
<VirtualHost *:79>
	RewriteEngine On
	RewriteCond %{HTTPS} !=on
	RewriteRule ^/?(.*) https://%SERVER_NAME/$1 [R=301,L]
</VirtualHost>
<VirtualHost *:443>
	ServerAdmin $admin_address
	ServerName $site_name.$domain_name
	DocumentRoot /var/www/$site_name

	SSLEngine on
	SSLCertificateFile /etc/apache2/certificate/"$site_name"".""$domain_name"_server.crt
	SSLCertificateKeyFile /etc/apache2/certificate/"$site_name"".""$domain_name"_server.key

	<Directory /var/www/$site_name>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" > /etc/apache2/sites-available/$site_name.conf
		error_handler $? "L'écriture du fichier /etc/apache2/sites-available/$site_name.conf a échouée."

		sudo a2ensite $site_name
		error_handler $? "L'activation du fichier de configuration du site $site_name a échouée."
		
		sudo systemctl reload apache2
		error_handler $? "Le redémarrage du service apache a échouée."

		echo "127.0.0.1 $site_name.$domain_name" >> /etc/hosts
		error_handler $? "L'écriture du fichier /etc/hosts a échouée."

		mkdir /var/www/$site_name/confidential
		error_handler $? "La création du dossier /var/www/$site_name/confidential a échouée."

		touch /var/www/$site_name/confidential/confidential.html
		error_handler $? "La création du fichier /var/www/$site_name/confidential/confidential.html a échouée."
		
		echo "
<html>
	<head>
		<title>Page protégée du site $site_name</title>
	</head>
	<body>
		<h1> SECRET IMPORTANT </h1>
	</body>
</html>" > /var/www/$site_name/confidential/confidential.html
		error_handler $? "L'écriture dans le fichier /var/www/$site_name/confidential/confidential.html a échouée."
		
		touch /var/www/$site_name/confidential/.htaccess
		error_handler $? "La création du fichier /var/www/$site_name/confidential/.htaccess a échouée."

		echo "AuthType Basic
		AuthName \"Accès protégé\"
		AuthUserFile /var/www/.htpasswd
		require valid-user
		Options -Indexes" > /var/www/$site_name/confidential/.htaccess
		error_handler $? "L'écriture du fichier /var/www/$site_name/confidential/.htaccess a échouée."

		logs_success "site_name créé."
	done

	logs_success "Sécurisation du .htaccess terminée."

	sudo systemctl restart apache2
	
	#ModSecurity
	
	logs_info "Installation et configuration de ModSecurity en cours..."
		
		sudo apt install -y libapache2-mod-security2 
		error_handler $? "L'installation de libapache2-mod-security2 a échouée."
		
		#TODO trouver un moyen de vérifier la bonne installation de modsecurity avec un retour de variable.
		# "security2_module (shared)"
		apachectl -M | grep --color security
		
		sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
		error_handler $? "Copie du fichier /etc/modsecurity/modsecurity.conf-recommended a échouée."
		
		echo "
# -- Rule engine initialization ----------------------------------------------

# Enable ModSecurity, attaching it to every transaction. Use detection
# only to start with, because that minimises the chances of post-installation
# disruption.
#
SecRuleEngine On

# -- Request body handling ---------------------------------------------------

# Allow ModSecurity to access request bodies. If you don't, ModSecurity
# won't be able to see any POST parameters, which opens a large security
# hole for attackers to exploit.
#
SecRequestBodyAccess On

# Enable XML request body parser.
# Initiate XML Processor in case of xml content-type
#
SecRule REQUEST_HEADERS:Content-Type \"^(?:application(?:/soap\+|/)|text/)xml\" \
     \"id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML\"

# Enable JSON request body parser.
# Initiate JSON Processor in case of JSON content-type; change accordingly
# if your application does not use 'application/json'
#
SecRule REQUEST_HEADERS:Content-Type \"^application/json\" \
     \"id:'200001',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON\"

# Sample rule to enable JSON request body parser for more subtypes.
# Uncomment or adapt this rule if you want to engage the JSON
# Processor for "+json" subtypes
#
#SecRule REQUEST_HEADERS:Content-Type \"^application/[a-z0-9.-]+[+]json\" \
#     \"id:'200006',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON\"

# Maximum request body size we will accept for buffering. If you support
# file uploads then the value given on the first line has to be as large
# as the largest file you are willing to accept. The second value refers
# to the size of data, with files excluded. You want to keep that value as
# low as practical.
#
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072

# Store up to 128 KB of request body data in memory. When the multipart
# parser reaches this limit, it will start using your hard disk for
# storage. That is slow, but unavoidable.
#
SecRequestBodyInMemoryLimit 131072

# What do do if the request body size is above our configured limit.
# Keep in mind that this setting will automatically be set to ProcessPartial
# when SecRuleEngine is set to DetectionOnly mode in order to minimize
# disruptions when initially deploying ModSecurity.
#
SecRequestBodyLimitAction Reject

# Maximum parsing depth allowed for JSON objects. You want to keep this
# value as low as practical.
#
SecRequestBodyJsonDepthLimit 512

# Verify that we've correctly processed the request body.
# As a rule of thumb, when failing to process a request body
# you should reject the request (when deployed in blocking mode)
# or log a high-severity alert (when deployed in detection-only mode).
#
SecRule REQBODY_ERROR \"!@eq 0\" \
\"id:'200002', phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2\"

# By default be strict with what we accept in the multipart/form-data
# request body. If the rule below proves to be too strict for your
# environment consider changing it to detection-only. You are encouraged
# _not_ to remove it altogether.
#
SecRule MULTIPART_STRICT_ERROR \"!@eq 0\" \
\"id:'200003',phase:2,t:none,log,deny,status:400, \
msg:'Multipart request body failed strict validation: \
PE %{REQBODY_PROCESSOR_ERROR}, \
BQ %{MULTIPART_BOUNDARY_QUOTED}, \
BW %{MULTIPART_BOUNDARY_WHITESPACE}, \
DB %{MULTIPART_DATA_BEFORE}, \
DA %{MULTIPART_DATA_AFTER}, \
HF %{MULTIPART_HEADER_FOLDING}, \
LF %{MULTIPART_LF_LINE}, \
SM %{MULTIPART_MISSING_SEMICOLON}, \
IQ %{MULTIPART_INVALID_QUOTING}, \
IP %{MULTIPART_INVALID_PART}, \
IH %{MULTIPART_INVALID_HEADER_FOLDING}, \
FL %{MULTIPART_FILE_LIMIT_EXCEEDED}'\"

# Did we see anything that might be a boundary?
#
SecRule MULTIPART_UNMATCHED_BOUNDARY \"!@eq 0\" \
\"id:'200004',phase:2,t:none,log,deny,msg:'Multipart parser detected a possible unmatched boundary.'\"

# PCRE Tuning
# We want to avoid a potential RegEx DoS condition
#
SecPcreMatchLimit 100000
SecPcreMatchLimitRecursion 100000

# Some internal errors will set flags in TX and we will need to look for these.
# All of these are prefixed with "MSC_".  The following flags currently exist:
#
# MSC_PCRE_LIMITS_EXCEEDED: PCRE match limits were exceeded.
#
SecRule TX:/^MSC_/ \"!@streq 0\" \
        \"id:'200005',phase:2,t:none,deny,msg:'ModSecurity internal error flagged: %{MATCHED_VAR_NAME}'\"

# -- Response body handling --------------------------------------------------

# Allow ModSecurity to access response bodies.
# You should have this directive enabled in order to identify errors
# and data leakage issues.
#
# Do keep in mind that enabling this directive does increases both
# memory consumption and response latency.
#
SecResponseBodyAccess On

# Which response MIME types do you want to inspect? You should adjust the
# configuration below to catch documents but avoid static files
# (e.g., images and archives).
#
SecResponseBodyMimeType text/plain text/html text/xml

# Buffer response bodies of up to 512 KB in length.
SecResponseBodyLimit 524288

# What happens when we encounter a response body larger than the configured
# limit? By default, we process what we have and let the rest through.
# That's somewhat less secure, but does not break any legitimate pages.
#
SecResponseBodyLimitAction ProcessPartial

# -- Filesystem configuration ------------------------------------------------

# The location where ModSecurity stores temporary files (for example, when
# it needs to handle a file upload that is larger than the configured limit).
#
# This default setting is chosen due to all systems have /tmp available however,
# this is less than ideal. It is recommended that you specify a location that's private.
#
SecTmpDir /tmp/

# The location where ModSecurity will keep its persistent data.  This default setting
# is chosen due to all systems have /tmp available however, it
# too should be updated to a place that other users can't access.
#
SecDataDir /tmp/

# -- File uploads handling configuration -------------------------------------

# The location where ModSecurity stores intercepted uploaded files. This
# location must be private to ModSecurity. You don't want other users on
# the server to access the files, do you?
#
#SecUploadDir /opt/modsecurity/var/upload/

# By default, only keep the files that were determined to be unusual
# in some way (by an external inspection script). For this to work you
# will also need at least one file inspection rule.
#
#SecUploadKeepFiles RelevantOnly

# Uploaded files are by default created with permissions that do not allow
# any other user to access them. You may need to relax that if you want to
# interface ModSecurity to an external program (e.g., an anti-virus).
#
#SecUploadFileMode 0600

# -- Debug log configuration -------------------------------------------------

# The default debug log configuration is to duplicate the error, warning
# and notice messages from the error log.
#
#SecDebugLog /opt/modsecurity/var/log/debug.log
#SecDebugLogLevel 3

# -- Audit log configuration -------------------------------------------------

# Log the transactions that are marked by a rule, as well as those that
# trigger a server error (determined by a 5xx or 4xx, excluding 404,
# level response status codes).
#
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus \"^(?:5|4(?!04)) \"

# Log everything we know about a transaction.
SecAuditLogParts ABDEFHIJZ

# Use a single file for logging. This is much easier to look at, but
# assumes that you will use the audit log only ocassionally.
#
SecAuditLogType Serial
SecAuditLog /var/log/apache2/modsec_audit.log

# Specify the path for concurrent audit logging.
#SecAuditLogStorageDir /opt/modsecurity/var/audit/

# -- Miscellaneous -----------------------------------------------------------

# Use the most commonly used application/x-www-form-urlencoded parameter
# separator. There's probably only one application somewhere that uses
# something else so don't expect to change this value.
#
SecArgumentSeparator &

# Settle on version 0 (zero) cookies, as that is what most applications
# use. Using an incorrect cookie version may open your installation to
# evasion attacks (against the rules that examine named cookies).
#
SecCookieFormat 0

# Specify your Unicode Code Point.
# This mapping is used by the t:urlDecodeUni transformation function
# to properly map encoded data to your language. Properly setting
# these directives helps to reduce false positives and negatives.
#
SecUnicodeMapFile unicode.mapping 20127

# Improve the quality of ModSecurity by sharing information about your
# current ModSecurity version and dependencies versions.
# The following information will be shared: ModSecurity version,
# Web Server version, APR version, PCRE version, Lua version, Libxml2
# version, Anonymous unique id for host.
# NB: As of April 2022, there is no longer any advantage to turning this
# setting On, as there is no active receiver for the information.
SecStatusEngine Off" > /etc/modsecurity/modsecurity.conf
	error_handler $? "L'écriture du fichier /etc/modsecurity/modsecurity.conf a échouée."
	
	sudo systemctl restart apache2
	error_handler $? "Le rédémarrage du service apache2 a échoué."
	
	logs_success "Installation et configuration de ModSecurity terminée."
	
	#ModEvasive
	
	logs_info "Installation et configuration de ModEvasive en cours..."
		sudo apt install -y libapache2-mod-evasive
		error_handler $? "L'installation du service libapache2-mod-evasive a échouée."
		
		touch /etc/apache2/mods-available/evasive.conf
		error_handler $? "La création /etc/apache2/mods-available/evasive.conf a échouée."

		echo "
		<IfModule mod_evasive20.c>
		    DOSHashTableSize    3097
		    DOSPageCount        2
		    DOSSiteCount        50
		    DOSPageInterval     1
		    DOSSiteInterval     1
		    DOSBlockingPeriod   10
		    DOSEmailNotify      $admin_address
		    DOSLogDir           \"/var/log/mod_evasive\"
		</IfModule>
		" > /etc/apache2/mods-available/evasive.conf
		error_handler $? "L'écriture du fichier /etc/apache2/mods-available/evasive.conf a échouée."
		
		sudo a2enmod evasive
		error_handler $? "L'activation du ModEvasive a échouée."
		
		sudo systemctl restart apache2
		error_handler $? "Le redémarrage du service apache a échouée."
	
	logs_success "Installation et configuration de ModEvasive terminée."
