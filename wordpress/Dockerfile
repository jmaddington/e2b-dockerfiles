# Use the Ubuntu 24.04 base image
FROM ubuntu:24.04

# Set environment variables for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && \
    apt-get install -y openssl shellinabox sudo python3 npm git vim nano curl mariadb-server php libapache2-mod-php php-mysql unzip && \
    apt-get install -y apache2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Create a sandboxuser and set the password
RUN useradd -m -s /bin/bash sandboxuser

# Add sandboxuser to sudoers without requiring a password
RUN usermod -aG sudo sandboxuser && \
    echo 'sandboxuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sandboxuser

# Download and set up WordPress
RUN curl -sS https://wordpress.org/latest.tar.gz -o wordpress.tar.gz && \
    tar -xzf wordpress.tar.gz && \
    rm wordpress.tar.gz && \
    mv wordpress /var/www/html/ && \
    chown -R www-data:www-data /var/www/html/wordpress

# Copy .env file to the image for runtime use
COPY .env /tmp/.env
COPY .env /home/sandboxuser/.env

# Download and set up phpMyAdmin manually
RUN curl -sS https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-english.tar.gz -o phpmyadmin.tar.gz && \
    tar xzf phpmyadmin.tar.gz && \
    rm phpmyadmin.tar.gz && \
    mv phpMyAdmin-5.1.3-english /var/www/html/phpmyadmin && \
    chown -R www-data:www-data /var/www/html/phpmyadmin

# Configure Apache
COPY apache-site.conf /etc/apache2/sites-available/000-default.conf

# Enable necessary Apache modules
RUN a2enmod rewrite

# Set the working directory
WORKDIR /var/www/html/wordpress

# Expose necessary ports
EXPOSE 4200 80

COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

CMD ["/usr/local/bin/start-services.sh"]
