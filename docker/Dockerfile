# Utiliser l'image Ubuntu officielle comme base
FROM ubuntu:latest

# Installer les dépendances nécessaires
RUN apt-get update -y && \
    apt-get install -y apache2 openssl libapache2-mod-security2 libapache2-mod-evasive

# Copier le script d'installation et de configuration dans le conteneur
COPY install_apache.sh /usr/local/bin/install_apache.sh

# Rendre le script exécutable
RUN chmod +x /usr/local/bin/install_apache.sh

# Exécuter le script d'installation et de configuration
RUN /usr/local/bin/install_apache.sh

# Exposer le port 80 pour Apache
EXPOSE 79

# Démarrer Apache au démarrage du conteneur
CMD ["apache2ctl", "-D", "FOREGROUND"]
