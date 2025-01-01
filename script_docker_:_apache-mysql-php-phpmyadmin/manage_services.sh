#!/bin/bash
source ./../.common.sh

# Fonction pour démarrer les services
start_services()
{
  logs_info "Démarrage des services..."
  docker start servicescomplexe-db-container
  error_handler $? "Le démarrage du service servicescomplexe-db-container a échouée."

  docker start servicescomplexe-phpmyadmin-container
  error_handler $? "Le démarrage du service servicescomplexe-phpmyadmin-container a échouée."

  docker start servicescomplexe-web-container
  error_handler $? "Le démarrage du service servicescomplexe-web-container a échouée."

  logs_success "Services démarrés."
}

# Fonction pour arrêter les start_services
stop_services()
{
  logs_info "Arrêt des services..."
  docker stop servicescomplexe-db-container
  error_handler $? "L'arrêt du service servicescomplexe-db-container a échouée."

  docker stop servicescomplexe-phpmyadmin-container
  error_handler $? "L'arrêt du service servicescomplexe-phpmyadmin-container a échouée."

  docker stop servicescomplexe-web-container
  error_handler $? "L'arrêt du service servicescomplexe-web-container a échouée."

  logs_success "Services arrêtés."
}

# Fonction pour redémarrer les services.
restart_services()
{
  logs_info "Redémarrage des services..."
  docker stop servicescomplexe-db-container
  error_handler $? "Le redémarrage du service servicescomplexe-db-container a échouée."

  docker stop servicescomplexe-phpmyadmin-container
  error_handler $? "Le redémarrage du service servicescomplexe-phpmyadmin-container a échouée."

  docker stop servicescomplexe-web-container
  error_handler $? "Le redémarrage du service servicescomplexe-web-container a échouée."

  logs_success "Services redémarrés."
}

# Fonction pour afficher les adresses ip des conteneurs
show_ip()
{
    # Récupérer les adresses IP des conteneurs
    WEB_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' servicescomplexe-web-container)
    DB_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' servicescomplexe-db-container)
    PHPMYADMIN_CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' servicescomplexe-phpmyadmin-container)

    # Afficher les adresses IP des conteneurs
    echo "Adresses IP des conteneurs du réseau docker servicescomplexe-network :"
    echo "servicescomplexe-web-container :"
    echo "   $WEB_CONTAINER_IP:79 servicescomplexe.fr"
    echo "servicescomplexe-phpmyadmin-container : "
    echo "   $PHPMYADMIN_CONTAINER_IP:81 phpmyadmin.servicescomplexe.fr"
    echo "servicescomplexe-db-container :"
    echo "   $DB_CONTAINER_IP:3307"
}

# Fonction pour afficher l'aide.
show_help() 
{
  echo "Usage: $0 {start|stop|restart|help}"
  echo "  start     Démarrer les services."
  echo "  stop      Arrêter les services."
  echo "  restart   Redémarrer les services."
  echo "  ip        Afficher les adresses ip des services dans le réseau servicescomplexe-network."
  echo "  help      Afficher l'aide."
}

# Vérifier le nombre d'arguments
if [ "$#" -ne 1 ]; then
    echo "Erreur: Nombre d'arguments incorrect."
    show_help
    exit 1
fi

# Vérifier l'argument passé
case $1 in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    ip)
        show_ip
        ;;
    help)
        show_help
        ;;
    *)
        echo "Erreur: Commande inconnue ''"
        show_help
        exit 1
        ;;
esac
