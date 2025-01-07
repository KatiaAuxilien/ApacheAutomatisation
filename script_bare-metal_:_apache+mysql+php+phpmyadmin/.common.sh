#!/bin/bash

# .·:'''''''''''''''''''''''''''''''''''''''''''''''''''''''':·.
# : :  ____                       _                          : :
# : : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___            : :
# : : | |_) / _` | '_ ` _ \| '_ \| | | | / __/ __|           : :
# : : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \           : :
# : : |_|   \__,_|_| |_| |_| .__/|_|\__,_|___/___/        _  : :
# : : | |__   __ _ _ __ ___|_|    _ __ ___   ___| |_ __ _| | : :
# : : | '_ \ / _` | '__/ _ \_____| '_ ` _ \ / _ \ __/ _` | | : :
# : : | |_) | (_| | | |  __/_____| | | | | |  __/ || (_| | | : :
# : : |_.__/ \__,_|_|  \___|     |_| |_| |_|\___|\__\__,_|_| : :
# '·:........................................................:·'

#===================================================================#

welcome ".·:'''''''''''''''''''''''''''''''''''''''''''''''''''''''':·."
welcome ": :  ____                       _                          : :"
welcome ": : |  _ \ __ _ _ __ ___  _ __ | |_   _ ___ ___            : :"
welcome ": : | |_) / _\` | '_ \` _ \| '_ \| | | | / __/ __|           : :"
welcome ": : |  __/ (_| | | | | | | |_) | | |_| \__ \__ \           : :"
welcome ": : |_|   \__,_|_| |_| |_| .__/|_|\__,_|___/___/        _  : :"
welcome ": : | |__   __ _ _ __ ___|_|    _ __ ___   ___| |_ __ _| | : :"
welcome ": : | '_ \ / _\` | '__/ _ \_____| '_ \` _ \ / _ \ __/ _\` | | : :"
welcome ": : | |_) | (_| | | |  __/_____| | | | | |  __/ || (_| | | : :"
welcome ": : |_.__/ \__,_|_|  \___|     |_| |_| |_|\___|\__\__,_|_| : :"
welcome "'·:........................................................:·'"

#===================================================================#

# Vérifier le format valide des variables

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
    port_vars=("WEB_PORT" "DB_PORT")
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


    # Vérifier que les autres variables ont au moins 4 caractères
    for var in "${required_vars_start[@]}"; do
        value="${!var}"
        if [[ ! "$var" =~ _PORT$ ]] && [ ${#value} -lt 4 ]; then
            logs_error "Erreur : La variable $var doit avoir au moins 4 caractères."
            exit 1
        fi
    done

logs_success "Les variables .env ont été vérifiées."

#===================================================================#

# Fonction pour vérifier si un service est installé
check_mysql_installed() {
    if command -v mysql &> /dev/null; then
        return 1
    else
        return 0
    fi
}

check_apache_installed() {
    if command -v apache2 &> /dev/null; then
        return 1
    else
        return 0
    fi
}

check_php_installed() {
    if command -v php &> /dev/null; then
        return 1
    else
        return 0
    fi
}

check_phpmyadmin_installed() {
    if dpkg -l | grep -q phpmyadmin; then
        return 1
    else
        return 0
    fi
}

#===================================================================#