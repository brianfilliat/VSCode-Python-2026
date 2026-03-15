#!/bin/bash
# LEMP Stack Setup Script for Ubuntu 20.04

# 1. Update and install Nginx, MySQL, PHP
sudo apt update
sudo apt install -y nginx mysql-server php php-fpm php-mysql

# 2. Ensure PHP-FPM and PHP-MySQL are installed (already included above)
# sudo apt install -y php-fpm php-mysql  # (redundant if above line used)

# 3. Create index.php in Nginx root
echo "<?php echo 'Welcome to LEMP Stack'; ?>" | sudo tee /var/www/html/index.php



# 4. Auto-detect PHP-FPM socket and configure Nginx to use PHP Processor
PHP_FPM_SOCK=$(find /var/run/php/ -name "php*-fpm.sock" | head -n 1)
if [ -z "$PHP_FPM_SOCK" ]; then
    echo "PHP-FPM socket not found. Exiting."
    exit 1
fi
PHP_FPM_VERSION=$(basename "$PHP_FPM_SOCK" | cut -d'-' -f2)
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_FPM_SOCK};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF


# 5. Restart Nginx and PHP-FPM (auto-detect PHP version)
PHP_FPM_SERVICE="php${PHP_FPM_VERSION}-fpm"
sudo systemctl restart "$PHP_FPM_SERVICE"
sudo systemctl restart nginx

# 6. (Optional) Enable services to start on boot
sudo systemctl enable nginx
sudo systemctl enable mysql
sudo systemctl enable "$PHP_FPM_SERVICE"

# 7. Stop Nginx for test case (if required by test)
if [ "$1" = "stop-nginx" ]; then
    sudo systemctl stop nginx
fi
