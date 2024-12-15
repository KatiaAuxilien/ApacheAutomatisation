#!/bin/bash

# Fonction pour afficher des messages de log avec couleurs
log_message() {
    local TYPE=$1
    local MESSAGE=$2
    local COLOR=""
    case $TYPE in
        INFO) COLOR="\033[0;32m" ;;
        WARN) COLOR="\033[0;33m" ;;
        ERROR) COLOR="\033[0;31m" ;;
        *) COLOR="\033[0m" ;;
    esac
    echo -e "${COLOR}[$(date +'%Y-%m-%d %H:%M:%S')] [$TYPE] $MESSAGE\033[0m" | tee -a uninstall.log
}

sudo apt remove --purge apache2-utils -y


# Arrêter et supprimer les conteneurs Docker
log_message INFO "Stopping and removing Docker containers..."
docker-compose down

# Supprimer les volumes Docker
log_message INFO "Removing Docker volumes..."
docker volume rm $(docker volume ls -q)

# Supprimer les réseaux Docker
log_message INFO "Removing Docker networks..."
docker network rm $(docker network ls -q)

# Supprimer les fichiers de configuration et les logs
log_message INFO "Removing configuration files and logs..."
rm -rf apache2/certificate apache2/mods-available /www phpmyadmin/ apache2

log_message INFO "Uninstallation completed successfully."
