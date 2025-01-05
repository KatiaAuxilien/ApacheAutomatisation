#!/bin/bash

mkdir /logs

if [ "$EUID" -ne 0 ]
then
    echo -e "${RED}Services complexes > Ce script doit être exécuté avec des privilèges root.${RESET}"
    exit 1
fi

#TODO : Vérifier le format valide des variables

logs_info "Services complexes > Vérification des variables .env..."

    # Charger les variables depuis le fichier .env
    if [ ! -f ../.env ]; then
        echo "Services complexes > Erreur : fichier .env non trouvé."
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
            echo "Services complexes > Erreur : La variable $port_var doit être un nombre entre 1 et 65535."
            exit 1
        fi
        if [ "${port_values[$port_value]}" ]; then
            echo "Services complexes > Erreur : La valeur du port $port_value est utilisée par plusieurs variables."
            exit 1
        fi
        port_values[$port_value]=1
    done


    # Vérifier que les autres variables ont au moins 4 caractères
    for var in "${required_vars_start[@]}"; do
        value="${!var}"
        if [[ ! "$var" =~ _PORT$ ]] && [ ${#value} -lt 4 ]; then
            echo "Services complexes > Erreur : La variable $var doit avoir au moins 4 caractères."
            exit 1
        fi
    done

logs_success "Services complexes > Les variables .env ont été vérifiées."