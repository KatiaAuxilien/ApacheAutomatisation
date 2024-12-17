
FROM debian:buster-slim

RUN apt-get update &&    apt-get install -y apache2 libapache2-mod-php php php-mysql &&    apt-get clean &&    rm -rf /var/lib/apt/lists/*

COPY www /var/www/html

EXPOSE 80

CMD ["apachectl","-D", "FOREGROUND"]

