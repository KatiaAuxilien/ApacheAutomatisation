#!/bin/bash

# .·:'''''''''''''''''''''''''''''''''''''''''''''':·.
# : :  ____                       _                : :
# : : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___  : :
# : : | |_) / _` | '_ ` _ \| '_ \| | | | / __/ __| : :
# : : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \ : :
# : : |_|  _\__,_|_| |_|_|_| .__/|_|\__,_|___/___/ : :
# : :   __| | ___   ___| | |_|__ _ __              : :
# : :  / _` |/ _ \ / __| |/ / _ \ '__|             : :
# : : | (_| | (_) | (__|   <  __/ |                : :
# : :  \__,_|\___/ \___|_|\_\___|_|                : :
# '·:..............................................:·'

#===================================================================#

# Vérification de la configuration de la machine hôte.
if ! command -v docker &> /dev/null; then
    logs_error "Docker n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    logs_error "Docker n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

#===================================================================#

# Vérifier le format valide des variables.

logs_info "Vérification des variables .env..."

    # Charger les variables depuis le fichier .env
    if [ ! -f ../.env ]; then
        logs_error "Erreur : fichier .env non trouvé."
        exit 1
    fi
    
    source ../.env

    for var in "${required_vars_start[@]}"; do
      check_variable "$var"
    done

    # Vérifier que les variables _PORT sont des chiffres entre 1 et 65535
    port_vars=("WEB_PORT" "PHPMYADMIN_PORT" "DB_PORT")
    declare -A port_values

    for port_var in "${port_vars[@]}"; do
        port_value="${!port_var}"
        if ! [[ "$port_value" =~ ^[0-9]+$ ]] || [ "$port_value" -lt 1 ] || [ "$port_value" -gt 65535 ]; then
            logs_error "Erreur : La variable $port_var doit être un nombre entre 1 et 65535."
            exit 1
        fi
        if [ "${port_values[$port_value]}" ]; then
            logs_error "Erreur : La valeur du port $port_value est utilisée par plusieurs variables."
            exit 1
        fi
        port_values[$port_value]=1
    done

    # Vérifier que les noms de conteneurs sont uniques.
    container_vars=("WEB_CONTAINER_NAME" "PHPMYADMIN_CONTAINER_NAME" "DB_CONTAINER_NAME")
    declare -A container_values

    for container_var in "${container_vars[@]}"; do
        container_value="${!container_var}"
        if [ "${container_values[$container_value]}" ]; then
            logs_error "Erreur : La valeur du conteneur $container_value est utilisée par plusieurs variables."
            exit 1
        fi
        container_values[$container_value]=1
    done

    # Vérifier que les autres variables ont au moins 4 caractères.
    for var in "${required_vars_start[@]}"; do
        value="${!var}"
        if [[ ! "$var" =~ _PORT$ ]] && [ ${#value} -lt 4 ]; then
            logs_error "Erreur : La variable $var doit avoir au moins 4 caractères."
            exit 1
        fi
    done

logs_success "Les variables .env ont été vérifiées."

#===================================================================#

# Vérifier si les services sont installés.

# Fonction pour vérifier si un conteneur avec une image spécifique existe
check_container_by_image() {
    local image_name="$1"
    local container_id=$(docker ps -aq --filter "ancestor=$image_name")

    if [ -n "$container_id" ]; then
        return 1
    else
        return 0
    fi
}

# Fonction pour vérifier si un conteneur avec un nom spécifique existe
check_container_by_name() {
    local container_name="$1"
    local container_id=$(docker ps -aq --filter "name=$container_name")

    if [ -n "$container_id" ]; then
        return 1
    else
        return 0
    fi
}

# Vérifier si les conteneurs spécifiques existent
check_container_by_image "bitnami/mysql"
mysql_installed=$?

check_container_by_image "phpmyadmin/phpmyadmin"
phpmyadmin_installed=$?

check_container_by_image "debian"
apache_installed=$?
php_installed=$apache_installed

# Vérifier si les noms des conteneurs ne sont pas déjà utilisés.

check_container_by_name "$DB_CONTAINER_NAME"
db_container_name_exists=$?

check_container_by_name "$PHPMYADMIN_CONTAINER_NAME"
phpmyadmin_container_name_exists=$?

check_container_by_name "$WEB_CONTAINER_NAME"
web_container_name_exists=$?


#===================================================================#