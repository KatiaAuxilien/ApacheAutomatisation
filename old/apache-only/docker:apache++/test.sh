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
	