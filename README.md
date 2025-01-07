<h1 align="center">Welcome to PAMPLUSS 🍋 (Php Apache Mysql Phpmyadmin Linux Ubuntu Secure Setup) 👋</h1>
<p>
  <img alt="Version" src="https://img.shields.io/badge/version-1-blue.svg?cacheSeconds=2592000" />
  <a href="TODO" target="_blank">
    <img alt="Documentation" src="https://img.shields.io/badge/documentation-yes-brightgreen.svg" />
  </a>
  <a href="TODO" target="_blank">
    <img alt="License: TODO" src="https://img.shields.io/badge/License-TODO-yellow.svg" />
  </a>
</p>

> Two different scripts to install (on host or on docker containers) and configure apache + php + phpmyadmin + mysql with advanced security.

### 🏠 [Homepage](https://github.com/KatiaAuxilien/ApacheAutomatisation)

### ✨ [Demo](https://katiaauxilien.github.io/projets/) 

## Functionalities

## Bare-metal

TODO

### Docker

TODO

## Prerequisite
- bash
- 
- Docker
- Docker-compose
- sudo privileges
- tar
- wget

- openssl (The install.sh script install it)
- apache2-utils (The install.sh script install it)

## Usage

### Installation

Step 1 : Create a .env file in ApacheAutomatisation.
```sh
touch PAMPLUSS/.env
```

Step 2 : Define environment variables. (Example :)
```sh
# .env
DOMAIN_NAME=servicescomplexe.fr
NETWORK_NAME=servicescomplexe-network

WEB_CONTAINER_NAME=servicescomplexe-web-container
WEB_ADMIN_ADDRESS=admin-web@servicescomplexe.fr
WEB_PORT=79
WEB_ADMIN_USER=admin
WEB_ADMIN_PASSWORD=changeme
SSL_KEY_PASSWORD=changeme
WEB_HTACCESS_PASSWORD=changeme

PHPMYADMIN_CONTAINER_NAME=servicescomplexe-phpmyadmin-container
PHPMYADMIN_HTACCESS_PASSWORD=changeme
PHPMYADMIN_ADMIN_ADDRESS=admin-php@servicescomplexe.fr
PHPMYADMIN_ADMIN_USERNAME=admin
PHPMYADMIN_ADMIN_PASSWORD=changeme
PHPMYADMIN_PORT=81

DB_CONTAINER_NAME=servicescomplexe-db-container
DB_PORT=3307
DB_ROOT_PASSWORD=changeme
DB_ADMIN_USERNAME=admin
DB_ADMIN_PASSWORD=changeme
DB_ADMIN_ADDRESS=admin-db@servicescomplexe.fr
DB_NAME=servicescomplexedatabase
DB_VOLUME_NAME=servicescomplexe-volume
```

Step 3 : Launch install.sh (in script-baremetal or script-c).
```sh
sudo ./install.sh
```

You can check logs in /var/log/ApacheAutomatisation.log

### Uninstallation

(Dependencies with .env)

Step 1 : Launch uninstall.sh (in script-baremetal or script-c).
```sh
sudo ./uninstall.sh
```

### Options

- You can add `--verbose` to print all informations during installation or uninstallation.


## TODO (Pistes de progression)

- Install ModRateLimit.
- Improve phpmyadmin installlation to not have user interface.
- Assign error code to each error situations.

## Sources

- Virtualization class  during my computer science studies.
- Installation and configuration of complex services class during my computer science studies.

https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-ubuntu-20-04-fr
https://www.howtogeek.com/devops/how-to-host-multiple-websites-with-one-apache-server/
https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-arch-linux
https://wiki.archlinux.org/title/Apache_HTTP_Server
https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-virtual-hosts-on-arch-linux
https://httpd.apache.org/docs/current/howto/htaccess.html
https://httpd.apache.org/docs/current/mod/core.html#allowoverride
https://blog.hubspot.fr/website/htaccess
https://www.codeur.com/tuto/creation-de-site-internet/proteger-site-avec-mot-de-passe/
https://httpd.apache.org/docs/current/mod/core.html#allowoverride
https://htaccessbook.com/disable-directory-indexes/
https://www.it-connect.fr/configurer-le-ssl-avec-apache-2/
https://www.ssltrust.com/help/setup-guides/arch-linux-ssl-install-guide
https://techexpert.tips/fr/apache-fr/activer-https-sur-apache/
https://ubuntu.com/server/docs/how-to-install-and-configure-phpmyadmin
https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-on-ubuntu-20-04
https://ubuntu.com/server/docs/how-to-install-and-configure-php
https://www.digitalocean.com/community/tutorials/how-to-install-php-8-1-and-set-up-a-local-development-environment-on-ubuntu-22-04
https://ubuntu.com/server/docs/install-and-configure-a-mysql-server
https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04
https://ubuntu.com/tutorials/install-and-configure-apache#1-overview
https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-ubuntu-20-04

https://fr.linux-terminal.com/?p=3240
https://en.wikipedia.org/wiki/ModSecurity
https://owasp.org/www-project-modsecurity/

https://bobcares.com/blog/configure-mod_evasive/
https://www.linuxtricks.fr/wiki/apache-limiter-la-bande-passante-avec-ratelimit-ou-mod_bw

## Author

👤 **Katia Auxilien**

* Website: [My portfolio](https://katiaauxilien.github.io/projets.html)
* Github: [@KatiaAuxilien](https://github.com/KatiaAuxilien)
<!-- * LinkedIn: [@TODO](https://linkedin.com/in/TODO) -->

<!--## 🤝 Contributing-->

<!--Contributions, issues and feature requests are welcome!<br />Feel free to check [issues page](https://github.com/KatiaAuxilien/ApacheAutomatisation/issues). -->

## Show your support

Give a ⭐️ if this project helped you!

## 📝 License

<!-- Copyright © 2024 [Katia Auxilien](https://github.com/KatiaAuxilien).<br /> -->
<!-- This project is [TODO](TODO) licensed. -->

***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_
