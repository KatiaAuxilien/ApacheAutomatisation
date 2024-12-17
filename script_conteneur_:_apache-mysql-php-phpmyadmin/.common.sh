#!/bin/bash

mkdir /logs

if [ "$EUID" -ne 0 ]
then
    echo -e "${RED}Ce script doit être exécuté avec des privilèges root.${RESET}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer avant de continuer.${RESET}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer avant de continuer.${RESET}"
    exit 1
fi

#TODO : Vérifier le format valide des variables

logs_info "Vérification des variables .env..."

    # Charger les variables depuis le fichier .env
    if [ ! -f ../.env ]; then
        echo "Erreur : fichier .env non trouvé."
        exit 1
    fi
    
    source ../.env

    for var in "${required_vars_start[@]}"; do
      check_variable "$var"
    done

logs_success "Les variables .env ont été vérifiées."
