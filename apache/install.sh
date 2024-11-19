#!/bin/bash

admin_address="katiaauxilien@mail.fr"

error_handler() {
	if [$1 != 0 ]
	then
		echo "Erreur : " $2 ""
		exit $1
	fi
}

logs(){
	date_formated=$(date +"%m-%d-%Y %H:%M:%S")
	echo "[" $date_formated "] "$1""
}


#Installation du service

logs "Installation du service apache en cours ..."

sudo apt update -y
error_handler $(sudo apt install -y apache2) "L'installation du service a échoué."

error_handler $(sudo ufw allow 'Apache') "L'autorisation du service apache auprès du pare-feu a échoué."

logs "Installation du service apache terminée."

#Lancement du service

logs "Lancement du service apache en cours..."

error_handler $(sudo systemctl start apache2) "Le lancement du service apache a échoué."
	
logs "Service apache lancé."

#Configuration du service (HTTPS, ModSecurity, ModEvasive, mod_ratelimit, .htaccess & masquage dans l'url des noms de dossier.)

logs "Configuration du service apache en cours..."

	error_handler $(sudo chmod -R 755 /var/www) "Attribution des privilèges 755 au dossier /var/www a échoué."

	error_handler $(sudo apt-get install openssl) "L'installation d'openssl a échoué."
	error_handler $(a2enmod ssl) "L'activation du module Mod_ssl a échoué."
	error_handler $(a2enmod rewrite) "L'activation du module Mod_rewrite a échoué."

	error_handler $(echo "
ServerRoot \"/etc/apache2\"

ServerName 127.0.0.1

#Mutex file:${APACHE_LOCK_DIR} default

DefaultRuntimeDir ${APACHE_RUN_DIR}

PidFile ${APACHE_PID_FILE}

Timeout 300

KeepAlive On

MaxKeepAliveRequests 100

KeepAliveTimeout 5

User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}

HostnameLookups Off

ErrorLog ${APACHE_LOG_DIR}/error.log

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

LogFormat \"%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"\" vhost_combined
LogFormat \"%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"\" combined
LogFormat \"%h %l %u %t \"%r\" %>s %O\" common
LogFormat \"%{Referer}i -> %U\" referer
LogFormat \"%{User-agent}i\" agent

IncludeOptional conf-enabled/*.conf

IncludeOptional sites-enabled/*.conf" > /etc/apache2/apache2.conf ) "L'écriture du fichier de configuration apache a échoué."

	error_handler $(echo "
<VirtualHost *:80>
	Rewrite Engine On
	RewriteCond %{HTTPS} !=on
	RewriteRule ^/?(.*) https://%SERVER_NAME/$1 [R=301,L]
<VirtualHost>
<VirtualHost *:79>
	ServerAdmin "$admin_address"
	ServerName 127.0.0.1
	DocumentRoot /var/www/html
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
	SSLEngine on
	SSLCertificateFile /etc/apache2/certificate/apache-certificate.crt
	SSLCertificateKeyFile /etc/apache2/certificate/apache.key
</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf) "L'écriture du fichier de configuration du site par défaut a échoué."
	
	error_handler $(echo "
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen 79

<IfModule ssl_module>
	Listen 443
</IfModule>

<IfModule mod_gnutls.c>
	Listen 443
</IfModule>" > /etc/apache2/ports.conf ) "L'écriture du fichier de configuration des ports a échoué."

	error_handler $(mkdir /etc/apache2/certificate) "La création du dossier /etc/apache2/certificate a échoué."
	cd /etc/apache2/certificate
	
	#error_handler $(openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out apache-certificate.crt -keyout apache.key) "Génération du certificat ssl a échoué."
	
	error_handler $(openssl genpkey -algorithm RSA -out private_key.pem -aes256) "La génération de la clé privée a échouée."

	error_handler $(openssl req -new -key private_key.pem -out cert_request.csr -subj "/C=FR/ST=Occitanie/L=Montpellier/O=IUT/OU=Herault/CN=auxilienk.com/emailAddress="$admin_address) "La génération de demande de signature de certifcat"

	error_handler $(openssl x509 -req -days 365 -in cert_request.csr -signkey private_key.pem -out certificate.crt) "La génération le certificat auto-signé"

	error_handler $(openssl x509 -in certificate.crt -text -noout) "La vérification du certificat a échouée."

	cd
	
#Sécurisation : .htaccess & masquage dans l'url des noms de dossier.
	
	logs "Sécurisation du .htaccess ..."

		error_handler $(mkdir /usr/home/$USER/www/) "La création du dossier /usr/home/"$USER"/www/ a échoué."
		error_handler $(touch /usr/home/$USER/www/.htpasswd) "La création du fichier /usr/home/"$USER"/www/.htpasswd a échoué."

		echo -n "Pleaser enter an encrypted password: "
		read password

		error_handler $(echo "admin:"$password"" > /usr/home/$USER/www/.htpasswd) "L'écriture dans le fichier /usr/home/"$USER"/www/.htpasswd a échoué."

#Création et configuration de n sites
	for site_name in siteA siteB
	do
		
		logs "Création du site " $site_name "..."

		error_handler $(sudo mkdir /var/www/$site_name) "La création du dossier /var/www/"$site_name" a échoué."
		error_handler $(sudo chown -R $USER:$USER /var/www/$site_name) "L'attribution des droits sur le dossier /var/www/"$site_name" a échoué."

		error_handler $(sudo touch /var/www/$site_name/index.html) "La création du fichier /var/www/"$site_name"/index.html a échoué."
		error_handler $(echo "
<html>
	<head>
		<title>Bienvenue sur le " $site_name " !</title>
	</head>
	<body>
		<h1> N'allez pas sur l'autre site, ce site est malveillant !</h1>
	</body>
</html>" > /var/www/$site_name/index.html) "L'écriture dans le fichier /var/www/"$site_name"/index.html a échoué."

		#Création des Virtual Host
		error_handler $(touch /etc/apache2/site-available/$site_name.conf) "La création du fichier /etc/apache2/site-available/"$site_name".conf a échoué."
		error_handler $(echo "
<VirtualHost *:80>
	Rewrite Engine On
	RewriteCond %{HTTPS} !=on
	RewriteRule ^/?(.*) https://%SERVER_NAME/$1 [R=301,L]
<VirtualHost>
<VirtualHost *:79>
	ServerAdmin "$admin_address"
	ServerName "$site_name"
	ServerAlias www."$site_name".fr
	DocumentRoot /var/www/"$site_name"
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
	SSLEngine on
	SSLCertificateFile /etc/apache2/certificate/apache-certificate.crt
	SSLCertificateKeyFile /etc/apache2/certificate/apache.key
</VirtualHost>
		" > /etc/apache2/site-available/$site_name.conf) "L'écriture du fichier /etc/apache2/site-available/"$site_name".conf a échoué."

		error_handler $(sudo a2ensite $site_name) "L'activation du fichier de configuration du site "$site_name" a échoué."

		error_handler $(sudo systemctl restart apache2) "Le redémarrage du service apache a échoué."

		error_handler $(echo "127.0.0.1 " $site_name "" >> /etc/hosts) "L'écriture du fichier /etc/hosts a échoué."

		error_handler $(touch /var/www/$site_name/confidential/confidential.html) "La création du fichier /var/www/"$site_name"/confidential/confidential.html a échoué."

		error_handler $(echo "
<html>
	<head>
		<title>Page protégée du site "$site_name"</title>
	</head>
	<body>
		<h1> SECRET IMPORTANT </h1>
	</body>
</html>" > /var/www/$site_name/confidential/confidential.html) "L'écriture dans le fichier /var/www/"$site_name"/confidential/confidential.html a échoué."
		
		error_handler $(touch /var/www/$site_name/confidential/.htaccess) "La création du fichier /var/www/"$site_name"/confidential/.htaccess a échoué."
error_handler $(echo "AuthType Basic
AuthName \"Accès protégé\"
AuthUserFile /usr/home/$USER/www/.htpasswd
require valid-user
Options -Indexes" > /var/www/$site_name/confidential/.htaccess) "L'écriture du fichier /var/www/"$site_name"/confidential/.htaccess a échoué."


		logs ""$site_name " créé."
	done

	logs "Sécurisation du .htaccess terminée."

	sudo systemctl restart apache2
	
	#ModSecurity
	
	logs "Installation et configuration de ModSecurity en cours..."
		
		error_handler $(sudo apt install -y libapache2-mod-security2) "L'installation de libapache2-mod-security2 a échoué."
		
		#TODO trouver un moyen de vérifier la bonne installation de modsecurity avec un retour de variable.
		# "security2_module (shared)"
		apachectl -M | grep --color security
		
		error_handler $(sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf) "Copie du fichier /etc/modsecurity/modsecurity.conf-recommended a échoué."
		
		error_handler $(echo "
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
# -- Rule engine initialization ----------------------------------------------

# Enable ModSecurity, attaching it to every transaction. Use detection
# only to start with, because that minimises the chances of post-installation
# disruption.
#
SecRuleEngine DetectionOnly


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
#SecRule REQUEST_HEADERS:Content-Type "^application/[a-z0-9.-]+[+]json" \
#     "id:'200006',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON"

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
SecRule REQBODY_ERROR \"!@eq 0 \" \
\"id:'200002', phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2 \"

# By default be strict with what we accept in the multipart/form-data
# request body. If the rule below proves to be too strict for your
# environment consider changing it to detection-only. You are encouraged
# _not_ to remove it altogether.
#
SecRule MULTIPART_STRICT_ERROR \"!@eq 0 \" \
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
SecStatusEngine Off


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
SecStatusEngine Off
" > /etc/modsecurity/modsecurity.conf) "L'écriture du fichier  /etc/modsecurity/modsecurity.conf a échoué."
		error_handler $(sudo systemctl restart apache2) "Le rédémarrage du service apache2 a échoué."
		
	
	logs "Installation et configuration de ModSecurity terminée."
	
	#ModEvasive
	
	logs "Installation et configuration de ModEvasive en cours..."
		error_handler $(sudo apt install -y libapache2-mod-evasive) "L'installation du service libapache2-mod-evasive a échoué."
		error_handler $(touch /etc/apache2/mods-available/evasive.conf) "La création /etc/apache2/mods-available/evasive.conf a échoué."
		error_handler $(echo "
		<IfModule mod_evasive20.c>
		    DOSHashTableSize    3097
		    DOSPageCount        2
		    DOSSiteCount        50
		    DOSPageInterval     1
		    DOSSiteInterval     1
		    DOSBlockingPeriod   10
		    DOSEmailNotify      "$admin_address"
		    DOSLogDir           \"/var/log/mod_evasive\"
		</IfModule>
		" > /etc/apache2/mods-available/evasive.conf) "L'écriture du fichier /etc/apache2/mods-available/evasive.conf a échoué."
		error_handler $(sudo a2enmod evasive) "L'activation du ModEvasive a échoué."
		error_handler $(sudo systemctl restart apache2) "Le redémarrage du service apache a échoué."
	
	logs "Installation et configuration de ModEvasive terminée."
