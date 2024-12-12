# Add 7.4 as your base PHP version
FROM php:7.4-apache

# Add Apache modules Docker
RUN a2enmod rewrite

# Install the MySQL PHP 7.4 library
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Set working directory
WORKDIR /var/www/html

# Copy PHP code to Docker
COPY ../src .