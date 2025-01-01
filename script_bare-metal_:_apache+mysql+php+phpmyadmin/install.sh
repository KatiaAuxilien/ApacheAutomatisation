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
logs_info "Apache > Installation du service en cours ..."

sudo apt update -y
error_handler $? "La mise à jour des paquets a échouée."

sudo apt install -y apache2 apache2-utils
error_handler $? "L'installation du service a échouée."

sudo ufw allow 'Apache'
error_handler $? "L'autorisation du service apache auprès du pare-feu a échouée."

logs_success "Apache > Installation du service terminée."

logs_info "Apache > Lancement du service en cours..."

sudo systemctl start apache2
error_handler $? "Le lancement du service apache a échouée."
	
logs_success "Apache > Service lancé."

#===================================================================#
# Configuration de Apache                                           #
#===================================================================#
logs_info "Apache > Configuration du service en cours ..."

echo "ServerRoot \"/etc/apache2\"

ServerName $DOMAIN_NAME

ServerAdmin $WEB_ADMIN_ADDRESS

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
    Options -Indexes
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
error_handler $? "L'écriture du fichier de configuration /etc/apache2/apache2.conf a échouée."


CERT_NAME="servicescomplexe"

echo "<VirtualHost *:80>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]
</VirtualHost>

<VirtualHost *:443>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{SERVER_PORT} 443
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$CERT_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$CERT_NAME"_server.key

  <Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<VirtualHost *:$WEB_PORT>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $DOMAIN_NAME

  DocumentRoot /var/www/html

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$CERT_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$CERT_NAME"_server.key

  <Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf
error_handler $? "L'écriture du fichier de configuration du site par défaut a échouée."

echo "# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen $WEB_PORT

<IfModule ssl_module>
  Listen 443
</IfModule>

<IfModule mod_gnutls.c>
  Listen 443
</IfModule>" > /etc/apache2/ports.conf 
error_handler $? "L'écriture du fichier de configuration des ports a échouée."


logs_info "Apache > Installation du module php en cours."
	sudo apt-get install -y libapache2-mod-php
	error_handler $? "L'activation du module php a échouée."
logs_success "Apache > Installation du module php terminée."

logs_success "Apache > Configuration du service terminée."

#===================================================================#
# Sécurisation de Apache                                            #
#===================================================================#
logs_info "Apache > Sécurisation du service en cours..."

logs_info "Apache > Sécurisation : Activation des modules headers et rewrite en cours."

	sudo a2enmod headers
	error_handler $? "L'activation du module Mod_headers a échouée."

	sudo a2enmod rewrite
	error_handler $? "L'activation du module Mod_rewrite a échouée."

logs_success "Apache > Sécurisation : Modules headers et rewrite activé."

logs_info "Apache > Sécurisation : Installation d'openssl et ssl-cert en cours."

	sudo apt-get install -y openssl ssl-cert
	error_handler $? "L'installation d'openssl a échouée."

logs_success "Apache > Sécurisation : Installation d'openssl et ssl-cert terminée."

logs_info "Apache > Sécurisation > HTTPS : Activation du module ssl en cours."

	sudo a2enmod ssl
	error_handler $? "L'activation du module Mod_ssl a échouée."

	a2ensite default-ssl
	error_handler $? "L'activation du module default_ssl a échouée."

logs_success "Apache > Sécurisation > HTTPS : Activation du module ssl terminée."

logs_info "Apache > Sécurisation > HTTPS : Génération du certificat et de la clé en cours."

	mkdir -p /etc/apache2/certificate/
	error_handler $? "La création du dossier /etc/apache2/certificate/ a échouée."

	sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out /etc/apache2/certificate/"$CERT_NAME"_server.crt -keyout /etc/apache2/certificate/"$CERT_NAME"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
	error_handler $? "La génération de demande de signature de certificat a échouée"

	openssl x509 -in /etc/apache2/certificate/"$CERT_NAME"_server.crt -text -noout
	error_handler $? "La vérification du certificat a échouée."

	sudo chmod 600 /etc/apache2/certificate/"$CERT_NAME"_server.key
	sudo chown root:root /etc/apache2/certificate/"$CERT_NAME"_server.crt
	sudo chmod 440 /etc/apache2/certificate/"$CERT_NAME"_server.crt

logs_success "Apache > Sécurisation > HTTPS : Génération du certificat et de la clé terminée."

# Sécurisation - Installation et configuration de ModSecurity

logs_info "Apache > Sécurisation > ModSecurity : Préparation de la configuration en cours."

	sudo apt-get install -y libapache2-mod-security2 libapache2-mod-evasive
	error_handler $? "..."

    echo "# -- Rule engine initialization ----------------------------------------------

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
SecRule REQUEST_HEADERS:Content-Type \"^(?:application(?:/soap\+|/)|text/)xml\" \\
     \"id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML\"

# Enable JSON request body parser.
# Initiate JSON Processor in case of JSON content-type; change accordingly
# if your application does not use 'application/json'
#
SecRule REQUEST_HEADERS:Content-Type \"^application/json\" \\
     \"id:'200001',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON\"

# Sample rule to enable JSON request body parser for more subtypes.
# Uncomment or adapt this rule if you want to engage the JSON
# Processor for \"+json\" subtypes
#
#SecRule REQUEST_HEADERS:Content-Type \"^application/[a-z0-9.-]+[+]json\" \\
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
SecRule REQBODY_ERROR \"!@eq 0\" \\
\"id:'200002', phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2\"

# By default be strict with what we accept in the multipart/form-data
# request body. If the rule below proves to be too strict for your
# environment consider changing it to detection-only. You are encouraged
# _not_ to remove it altogether.
#
SecRule MULTIPART_STRICT_ERROR \"!@eq 0\" \\
\"id:'200003',phase:2,t:none,log,deny,status:400, \\
msg:'Multipart request body failed strict validation: \\
PE %{REQBODY_PROCESSOR_ERROR}, \\
BQ %{MULTIPART_BOUNDARY_QUOTED}, \\
BW %{MULTIPART_BOUNDARY_WHITESPACE}, \\
DB %{MULTIPART_DATA_BEFORE}, \\
DA %{MULTIPART_DATA_AFTER}, \\
HF %{MULTIPART_HEADER_FOLDING}, \\
LF %{MULTIPART_LF_LINE}, \\
SM %{MULTIPART_MISSING_SEMICOLON}, \\
IQ %{MULTIPART_INVALID_QUOTING}, \\
IP %{MULTIPART_INVALID_PART}, \\
IH %{MULTIPART_INVALID_HEADER_FOLDING}, \\
FL %{MULTIPART_FILE_LIMIT_EXCEEDED}'\"

# Did we see anything that might be a boundary?
#
SecRule MULTIPART_UNMATCHED_BOUNDARY \"!@eq 0\" \\
\"id:'200004',phase:2,t:none,log,deny,msg:'Multipart parser detected a possible unmatched boundary.'\"

# PCRE Tuning
# We want to avoid a potential RegEx DoS condition
#
SecPcreMatchLimit 100000
SecPcreMatchLimitRecursion 100000

# Some internal errors will set flags in TX and we will need to look for these.
# All of these are prefixed with \"MSC_\".  The following flags currently exist:
#
# MSC_PCRE_LIMITS_EXCEEDED: PCRE match limits were exceeded.
#
SecRule TX:/^MSC_/ \"!@streq 0\" \\
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
SecAuditLogRelevantStatus \"^(?:5|4(?!04))\"

# Log everything we know about a transaction.
SecAuditLogParts ABCEFHJKZ

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
error_handler $? "La configuration de /etc/modsecurity/modsecurity.conf a échouée."

echo "<IfModule security2_module>
  # Default Debian dir for modsecurity's persistent data
  SecDataDir /var/cache/modsecurity

  # Include all the *.conf files in /etc/modsecurity.
  # Keeping your local configuration in that directory
  # will allow for an easy upgrade of THIS file and
  # make your life easier
        IncludeOptional /etc/modsecurity/*.conf

  # Include OWASP ModSecurity CRS rules if installed
  IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf
  IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.0/rules/*.conf
</IfModule>" > /etc/apache2/mods-enabled/security2.conf
error_handler $? "La configuration de /etc/apache2/mods-enabled/security2.conf a échouée."

#  ModSecurity : Règles de base OWASP (CRS)

logs_info "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) : Préparation de la configuration en cours."

    wget https://github.com/coreruleset/coreruleset/archive/v3.3.0.tar.gz
    error_handler $? "wget https://github.com/coreruleset/coreruleset/archive/v3.3.0.tar.gz a échoué."

    tar xvf v3.3.0.tar.gz
    error_handler $? "tar xvf v3.3.0.tar.gz a échoué."

    rm -rf v3.3.0.tar.gz
    error_handler $? "rm -rf v3.3.0.tar.gz a échoué."

	sudo mkdir /etc/apache2/modsecurity-crs/
	error_handler $? "..."

    sudo mv coreruleset-3.3.0/ /etc/apache2/modsecurity-crs/
    error_handler $? "mv coreruleset-3.3.0/ /etc/apache2/modsecurity-crs/ a échoué."

    sudo mv /etc/apache2/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf.example /etc/apache2/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf
    error_handler $? "mv /etc/apache2/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf.example /etc/apache2/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf a échoué."

logs_success  "Apache > Sécurisation > ModSecurity > Règles OWASP (CRS) : Préparation de la configuration terminée."

logs_success "Apache > Sécurisation > ModSecurity : Préparation de la configuration terminée."
  
logs_info "Apache > Sécurisation > ModSecurity : Activation en cours."
  
  sudo a2enmod security2
  error_handler $? "..."

logs_success "Apache > Sécurisation > ModSecurity : Module activé."

#TODO : Sécurisation - Installation et configuration de ModEvasive
logs_info "Apache > Sécurisation > ModEvasive : Préparation de la configuration en cours."

	sudo apt-get install -y libapache2-mod-evasive
	error_handler $? "L'installation du mod evasive a échouée."

	echo "
	<IfModule mod_evasive20.c>
	    DOSHashTableSize    3097
	    DOSPageCount        2
	    DOSSiteCount        50
	    DOSPageInterval     1
	    DOSSiteInterval     1
	    DOSBlockingPeriod   10
	    DOSEmailNotify      $WEB_ADMIN_ADDRESS
	    DOSLogDir           \"/var/log/mod_evasive\"
	</IfModule>
	" > /etc/apache2/mods-enabled/evasive.conf
	error_handler $? "L'écriture du fichier /etc/apache2/mods-enabled/evasive.conf a échouée."

logs_success "Apache > Sécurisation > ModEvasive : Préparation de la configuration terminée."

logs_info "Apache > Sécurisation > ModEvasive : Activation en cours."

	sudo a2enmod evasive
	error_handler $? "..."

logs_success "Apache > Sécurisation > ModEvasive : Module activé."

#TODO BONUS : Sécurisation - Installation et configuration de ModRatelimit

logs_info "Apache > Redémarrage du service en cours..."

	sudo systemctl restart apache2
	error_handler $? "Le redémarrage du service apache a échoué."
		
logs_success "Apache > Service redémarré."

#===================================================================#
# Création des sites                                                #
#===================================================================#

# Création de la page principale

logs_info "..."

touch /var/www/html/index.html
chmod -R 755 /var/www/index.html

echo "<!DOCTYPE html>
<html>
  <head>
    <title>Accueil de $DOMAIN_NAME</title>
    <meta charset=\"utf-8\"/>
    <style>
body{
  background-color: #C6E7FF;
  font-family: Avantgarde, TeX Gyre Adventor, URW Gothic L, sans-serif;
}
      </style>
  </head>
  <body>
    <h1>Bienvenue sur $DOMAIN_NAME ! 👋</h1>
    <p> ✨ <a href=\"https://siteA.$DOMAIN_NAME:$WEB_PORT\">Visiter siteA.$DOMAIN_NAME</a> </p>
    <p> ✨ <a href=\"https://siteB.$DOMAIN_NAME:$WEB_PORT\">Visiter siteB.$DOMAIN_NAME</a> </p>
  </body>
</html> " > /var/www/index.html


# Configuration du .htaccess et .htpasswd
logs_info "..."

	sudo apt install apache2-utils -y
	error_handler $? "..."

	touch /var/www/.htpasswd
	error_handler $? "La création du fichier /var/www/.htpasswd a échouée."

	sudo htpasswd -b /var/www/.htpasswd admin $WEB_HTACCESS_PASSWORD
	error_handler $? "L'écriture dans le fichier /var/www/.htpasswd a échouée."

logs_success "..."


# Création de deux sites (siteA, siteB)

    for site_name in siteA siteB
    do
        logs_info "Création du site " $site_name "..."
        
        mkdir /var/www/$site_name
        error_handler $? "La création du dossier /var/www/$site_name a échouée."
        
        chmod -R 755 /var/www/$site_name
        error_handler $? "L'attribution des droits sur le dossier /var/www/$site_name a échouée."
        
        sudo touch /var/www/$site_name/index.html
        error_handler $? "La création du fichier /var/www/$site_name/index.html a échouée."

        echo "<!DOCTYPE html>
<html>
    <head>
        <title>$site_name</title>
        <meta charset=\"utf-8\"/>
    <style>
body{
  background-color: #C6E7FF;
  font-family: Avantgarde, TeX Gyre Adventor, URW Gothic L, sans-serif;
}
      </style>
    </head>
    <body>
      <h1>Bienvenue sur le " $site_name " ! 👋</h1>
        <h2> N'allez pas sur l'autre site, ce site est malveillant !</h2>
        <a href=\"https://$site_name.$DOMAIN_NAME:79/confidential/confidential.php\"><h2> Page confidentiel ici</h2></a>
    </body>
</html>" > /var/www/$site_name/index.html
        error_handler $? "L'écriture dans le fichier /var/www/$site_name/index.html a échouée."

        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -out /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt -keyout /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.key -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=$site_name.$DOMAIN_NAME/emailAddress=$WEB_ADMIN_ADDRESS" -passin pass:"$SSL_KEY_PASSWORD"
        error_handler $? "La génération de demande de signature de certifcat du site $site_name a échouée"

        openssl x509 -in /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt -text -noout
        error_handler $? "La vérification du certificat a échouée."
        
        sudo chmod 600 /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.key
        sudo chown root:root /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt
        sudo chmod 440 /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt

        #Création des Virtual Host
        touch /etc/apache2/sites-available/$site_name.conf
        error_handler $? "La création du fichier /etc/apache2/sites-available/$site_name.conf a échouée."

        echo "<VirtualHost *:80>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $site_name.$DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]
</VirtualHost>

<VirtualHost *:443>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $site_name.$DOMAIN_NAME

  RewriteEngine On
  RewriteCond %{SERVER_PORT} 443
  RewriteRule ^ https://%{HTTP_HOST}:$WEB_PORT%{REQUEST_URL} [R,L]

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.key

  <Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/$site_name-error.log
  CustomLog \${APACHE_LOG_DIR}/$site_name-access.log combined
</VirtualHost>

<VirtualHost *:$WEB_PORT>
  ServerAdmin $WEB_ADMIN_ADDRESS
  ServerName $site_name.$DOMAIN_NAME

  DocumentRoot /var/www/$site_name

  SSLEngine on
  SSLCertificateFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.crt
  SSLCertificateKeyFile /etc/apache2/certificate/"$site_name"".""$DOMAIN_NAME"_server.key

  <Directory /var/www/$site_name>
    Options -Indexes
    AllowOverride All
    Require all granted
  </Directory>
 
  ErrorLog \${APACHE_LOG_DIR}/$site_name-error.log
  CustomLog \${APACHE_LOG_DIR}/$site_name-access.log combined
</VirtualHost>" > /etc/apache2/sites-available/$site_name.conf
        error_handler $? "L'écriture du fichier /etc/apache2/sites-available/$site_name.conf a échouée."

# Création de la page confidentielle

        mkdir /var/www/$site_name/confidential
        error_handler $? "La création du dossier /var/www/$site_name/confidential a échouée."
        
        chmod -R 755 /var/www/$site_name/confidential

        touch /var/www/$site_name/confidential/confidential.php
        error_handler $? "La création du fichier /var/www/$site_name/confidential/confidential.php a échouée."
        
        chmod -R 755 /var/www/$site_name/confidential/confidential.php

        echo "<!DOCTYPE html>
<html>
    <head>
        <title>Page protégée du site $site_name</title>
        <meta charset=\"utf-8\"/>
    </head>
    <style>
body{
  background-color: #C6E7FF;
  font-family: Avantgarde, TeX Gyre Adventor, URW Gothic L, sans-serif;
}
table {
  width: 100%;
  border: 1px solid;
}
.todo{
  background-color: #B06161;
  text-align: center;

}
.inprogess{
  background-color: #FFCF9D;
  text-align: center;
}
.done{
  background-color: #D0E8C5;
  text-align: center;
}
      </style>
      <script>

      </script>
    <body>
        <h1> TOP SECRET </h1>
<?php
    \$user = \""$DB_ADMIN_USERNAME"\";
    \$password = \""$DB_ADMIN_PASSWORD"\";
    \$database = \""$DB_NAME"\";
    \$table = \"todo_list\";


    \$session = new mysqli(\"$DB_CONTAINER_NAME\",\$user,\$password, \$database, $DB_PORT);

    if (\$session->connect_error)
    {
      die(\"Connection failed: \" . \$session->connect_error);
    }
    
    \$sql = \"SELECT * FROM \$table\";
    \$result = \$session->query(\$sql);

    echo \"<h2>Liste de tâches à faire</h2>\";

    echo \"<table>
    <tr> 
      <th>Tâche</th>
      <th>Statut</th>
    </tr>\";

    if (\$result->num_rows > 0) 
    {
       while( \$row = \$result->fetch_assoc() )
       { \$statut = \"\";
         if( \$row[\"statut\"] == 0 )
         { \$statut = \"<td class="todo"> A faire </td>\";
         }
         if( \$row[\"statut\"] == 1 )
         { \$statut = \"<td class="inprogess"> En cours </td>\";
         }
         if( \$row[\"statut\"] == 2 )
         { \$statut = \"<td class="done"> Fait </td>\";
         }

         echo \"<tr><td>\" . \$row[\"content\"] . \"</td>\" . \$statut . \"</tr>\";
       }
    } 
    else 
    {
      echo \"0 results\";
    }

    echo \"</table>\";
    \$session->close();

?>
    </body>
</html>" > /var/www/$site_name/confidential/confidential.php
        error_handler $? "L'écriture dans le fichier /var/www/$site_name/confidential/confidential.php a échouée."

# Configuration de la page confidentielle (.htaccess et .htpasswd)

        touch /var/www/$site_name/confidential/.htaccess
        error_handler $? "La création du fichier /var/www/$site_name/confidential/.htaccess a échouée."

        echo "AuthType Basic
        AuthName \"Accès protégé\"
        AuthUserFile /var/www/.htpasswd
        require valid-user
        Options -Indexes" > /var/www/$site_name/confidential/.htaccess
        error_handler $? "L'écriture du fichier /var/www/$site_name/confidential/.htaccess a échouée."

        sudo a2ensite $site_name.conf

        logs_success "$site_name.$DOMAIN_NAME créé."
    done

#===================================================================#

logs_info "Apache > Redémarrage du service en cours..."

	sudo systemctl restart apache2
	error_handler $? "Le redémarrage du service apache a échoué."
		
logs_success "Apache > Service redémarré."

#===================================================================#
# Installation de PHP                                               #
#===================================================================#
#TODO : Installation PHP
#TODO : Configuration de PHP

# https://ubuntu.com/server/docs/how-to-install-and-configure-php

sudo apt install -y php
error_handler $? "L'installation du service php a échouée."
  php-mysql

#===================================================================#
# Installation et configuration de mysql                            #
#===================================================================#
#TODO : Installation mysql
#TODO : Configuration de mysql

# https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04

#TODO : Créer une base de données d'intro
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

logs_info "MySQL > Initialisation de la base de données $DB_CONTAINER_NAME."
  
  sudo mysql -u$DB_ADMIN_USERNAME -p$DB_ADMIN_PASSWORD -e "$DB_INIT_SQL_QUERIES" $DB_NAME
  error_handler $? "Le lancement de l'initialisation de $DB_CONTAINER_NAME a échoué."

logs_success "MySQL > Base de données $DB_CONTAINER_NAME initialisée."

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