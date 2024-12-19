#!/bin/bash
sudo su
set -e

echo "Starting services..." >>/home/startup.log

# Start MariaDB service
service mariadb start

# Determine the .env file location
if [ -f "/tmp/.env" ]; then
    ENV_FILE="/tmp/.env"
elif [ -f "/home/sandboxuser/.env" ]; then
    ENV_FILE="/home/sandboxuser/.env"
elif [ -f "/home/user/.env" ]; then
    ENV_FILE="/home/user/.env"
else
    echo "No .env file found. Exiting."
    exit 1
fi

# Source environment variables
. $ENV_FILE

# Set the sandboxuser password here
if [ -n "$SANDBOXUSER_PASSWORD" ]; then
    echo "sandboxuser:${SANDBOXUSER_PASSWORD}" | chpasswd
fi

# If a root password is provided, set it for MariaDB root user
if [ -n "$DB_ROOT_PASSWORD" ]; then
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
    mysql -u root -p"${DB_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
    MYSQL_AUTH="-p${DB_ROOT_PASSWORD}"
else
    MYSQL_AUTH=""
fi

# Create database and user
mysql -u root $MYSQL_AUTH -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mysql -u root $MYSQL_AUTH -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -u root $MYSQL_AUTH -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -u root $MYSQL_AUTH -e "FLUSH PRIVILEGES;"

# Create wp-config.php
cat > /var/www/html/wordpress/wp-config.php <<EOF
<?php
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
\$table_prefix = 'wp_';
define('WP_DEBUG', true);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF

# Ensure correct permissions before using wp-cli
chown -R www-data:www-data /var/www/html/wordpress

# Wait for database to be ready
for i in {1..10}; do
    if mysqladmin ping -u root $MYSQL_AUTH --silent; then
        break
    fi
    sleep 1
done

# Run WP CLI installation if not installed
cd /var/www/html/wordpress
if ! sudo -u www-data wp core is-installed --path=/var/www/html/wordpress; then
    sudo -u www-data wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"
fi

# Start Apache and Shellinabox
service apache2 start
shellinaboxd --no-beep --disable-ssl -t --user=sandboxuser
