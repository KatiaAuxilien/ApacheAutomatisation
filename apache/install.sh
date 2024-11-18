#!/bin/bash

#TODO : Ajouter la gestion des erreurs en fonction du retour de commande.

#Installation du service
date_formated=$(date + %m_%d_%y-%H.%M.%S)
echo "[" $date_formated "] Installation du service apache en cours ..."

sudo apt update
sudo apt install apache2
sudo ufw allow 'Apache'

date_formated=$(date + %m_%d_%y-%H.%M.%S)
echo "[" $date_formated "] Installation du service apache terminée."


#Lancement du service
date_formated=$(date + %m_%d_%y-%H.%M.%S)
echo "[" $date_formated "] Lancement du service apache en cours..."

sudo systemctl start apache2

date_formated=$(date + %m_%d_%y-%H.%M.%S)
echo "[" $date_formated "] Service apache lancé."


#Configuration du service (HTTPS, ModSecurity, ModEvasive, mod_ratelimit, .htaccess & masquage dans l'url des noms de dossier.)
date_formated=$(date + %m_%d_%y-%H.%M.%S)
echo "[" $date_formated "] Configuration du service apache en cours..."

	sudo chmod -R 755 /var/www

	sudo apt-get install openssl
	a2enmod ssl
	a2enmod rewrite

	echo "
	AllowOverride All
	
	<Directory /var/www/html>
	AllowOverride All
	
	</Directory>
	
	" > /etc/apache2/apache2.conf 
	#TODO Fichier de configuration 
	
	echo "79" > /etc/apache2/ports.conf 

	mkdir /etc/apache2/certificate
	cd /etc/apache2/certificate
	
	openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out apache-certificate.crt -keyout apache.key
	#TODO : Ajouter en argument de génération de certificat les informations.
	
	cd
	
#Sécurisation : .htaccess & masquage dans l'url des noms de dossier.
	date_formated=$(date + %m_%d_%y-%H.%M.%S)
	echo "[" $date_formated "] Sécurisation du .htaccess ..."

	mkdir /usr/home/$USER/www/
	touch /usr/home/$USER/www/.htpasswd

	echo -n "Pleaser enter an encrypted password: "
	read password

	echo "admin:"$password"" > /usr/home/$USER/www/.htpasswd

#Création et configuration de n sites
	admin_address = katiaauxilien@mail.fr

	for site_name in siteA siteB
	do
		date_formated=$(date + %m_%d_%y-%H.%M.%S)
		echo "[" $date_formated "] Création du site " $site_name "..."

		sudo mkdir /var/www/$site_name
		sudo chown -R $USER:$USER /var/www/$site_name

		sudo touch /var/www/$site_name/index.html
		echo "
		<html>
			<head>
				<title>Bienvenue sur le " $site_name " !</title>
			</head>
			<body>
				<h1> N'allez pas sur l'autre site, ce site est malveillant !</h1>
			</body>
		</html>" > /var/www/$site_name/index.html

		#Création des Virtual Host
		touch /etc/apache2/site-available/$site_name.conf
		echo "
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
		" > /etc/apache2/site-available/$site_name.conf

		sudo a2ensite $site_name

		sudo systemctl restart apache2

		echo "127.0.0.1 " $site_name "" >> /etc/hosts

		touch /var/www/$site_name/confidential/confidential.html

		echo "
		<html>
			<head>
				<title>Page protégée du site "$site_name"</title>
			</head>
			<body>
				<h1> SECRET IMPORTANT </h1>
			</body>
		</html>" > /var/www/$site_name/confidential/confidential.html
		
		touch /var/www/$site_name/confidential/.htaccess
		echo "AuthType Basic
		AuthName \"Accès protégé\"
		AuthUserFile /usr/home/$USER/www/.htpasswd
		require valid-user
		Options -Indexes" > /var/www/$site_name/confidential/.htaccess


		date_formated=$(date + %m_%d_%y-%H.%M.%S)
		echo "[" $date_formated "] " $site_name " créé."
	done

	sudo systemctl restart apache2
	
	#ModSecurity
	date_formated=$(date + %m_%d_%y-%H.%M.%S)
	echo "[" $date_formated "] Installation et configuration de ModSecurity en cours..."
		
		sudo apt install libapache2-mod-security2
		
		#TODO trouver un moyen de vérifier la bonne installation de modsecurity avec un retour de variable.
		# "security2_module (shared)"
		apachectl -M | grep --color security
		
		sudo cp /etc/modsecurity/modsecurity.conf-recommended/ /etc/modsecurity/modsecurity.conf
		
		echo "" > /etc/modsecurity/modsecurity.conf
		#TODO Récupérer le fichier de config de modsecurity
		# SecRuleEngine On
		
		sudo systemctl restart apache2
		
	date_formated=$(date + %m_%d_%y-%H.%M.%S)
	echo "[" $date_formated "] Installation et configuration de ModSecurity terminée."
	
	#ModEvasive
	date_formated=$(date + %m_%d_%y-%H.%M.%S)
	echo "[" $date_formated "] Installation et configuration de ModEvasive en cours..."
		sudo apt install libapache2-mod-evasive
		touch /etc/apache2/mods-available/evasive.conf
		echo "
		<IfModule mod_evasive20.c>
			DOSHashTableSize	3097
			DOSPageCount		2
			DOSPageInterval		1
			DOSSiteCount		50
			DOSSiteInterval		1
			DOSBlockingPeriod	10
		</IfModule>
		" > /etc/apache2/mods-available/evasive.conf
		sudo a2enmod evasive
		sudo systemctl restart apache2
	date_formated=$(date + %m_%d_%y-%H.%M.%S)
	echo "[" $date_formated "] Installation et configuration de ModEvasive terminée."
	
