FROM ubuntu:latest

RUN apt-get update -y && \
    apt-get install -y apache2 openssl libapache2-mod-security2 libapache2-mod-evasive ufw

# Copy the installation script
COPY install_apache.sh /usr/local/bin/install_apache.sh

COPY hosts /etc/hosts

# Make the script executable
RUN chmod +x /usr/local/bin/install_apache.sh

# Run the installation script
RUN /usr/local/bin/install_apache.sh

# Expose the necessary port
EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]
