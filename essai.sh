#!/bin/bash

# Fonction pour vérifier si PHPMyAdmin est installé
check_phpmyadmin_installed() {
    if dpkg -l | grep -q phpmyadmin; then
        php_installed=true
    else
        php_installed=false
    fi
}

# Initialisation de la variable php_installed
php_installed=false

# Vérification de l'installation de PHPMyAdmin
check_phpmyadmin_installed

# Affichage du résultat
if [ "$php_installed" = true ]; then
    echo "PHPMyAdmin est installé."
else
    echo "PHPMyAdmin n'est pas installé."
    # Vous pouvez ajouter ici la logique pour installer PHPMyAdmin si nécessaire
    sudo apt update
    sudo apt install -y phpmyadmin
    if [ $? -eq 0 ]; then
        echo "PHPMyAdmin a été installé avec succès."
    else
        echo "L'installation de PHPMyAdmin a échoué."
    fi
fi
