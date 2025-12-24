#!/bin/bash

# ============================================================================
# 🚀 Paymenter Automated Installation Script
# ⚡ InfinityForge Edition
# 👨‍💻 Made by JOY
# ============================================================================

echo "============================================================================"
echo "  ___        __ _       _ _           ___                    "
echo " |_ _|_ __  / _(_)_ __ (_) |_ _   _  |_ _|__  _ __ __ _  ___ "
echo "  | || '_ \| |_| | '_ \| | __| | | |  | |/ _ \| '__/ _\` |/ _ \\"
echo " | || | | |  _| | | | | | |_| |_| |  | | (_) | | | (_| |  __/"
echo " |___|_| |_|_| |_|_| |_|_|\__|\__, | |_|\___/|_|  \__, |\___|"
echo "                              |___/               |___/      "
echo ""
echo "    ⚡ Paymenter Installation Script - InfinityForge Edition ⚡"
echo "                     👨‍💻 Crafted by JOY 👨‍💻"
echo "============================================================================"
echo ""

# Function to install SSL using Certbot
install_ssl() {
    echo "🔒 Installing Certbot and configuring SSL for $1..."
    apt -y install certbot python3-certbot-nginx
    certbot --nginx -d $1
    echo "✅ SSL configured successfully!"
}

# Prompt for database password
echo "🔐 Database Configuration"
read -p "Enter the database password for Paymenter: " DB_PASSWORD

# Setup database
echo ""
echo "💾 Setting up database..."
mysql -e "SELECT 1 FROM mysql.db WHERE Db='paymenter'" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    read -p "⚠️  The database 'paymenter' already exists. Do you want to delete and recreate it? (Y/N): " recreate_db_choice
    if [ "$recreate_db_choice" = "Y" ] || [ "$recreate_db_choice" = "y" ]; then
        mysql -e "DROP DATABASE IF EXISTS paymenter;"
        mysql -e "CREATE DATABASE paymenter;"
        echo "✅ Database recreated successfully!"
    else
        echo "⏭️  Skipping database creation."
    fi
else
    mysql -e "CREATE DATABASE paymenter;"
    echo "✅ Database created successfully!"
fi

mysql -e "CREATE USER IF NOT EXISTS 'paymenter'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON paymenter.* TO 'paymenter'@'127.0.0.1' WITH GRANT OPTION;"
echo "✅ Database user configured!"

# Install dependencies
echo ""
echo "📦 Installing system dependencies..."
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="mariadb-10.11"
apt update
apt -y install php8.2 php8.2-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
echo "✅ Dependencies installed successfully!"

# Install Composer
echo ""
echo "🎼 Installing Composer..."
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
echo "✅ Composer installed!"

# Download Paymenter
echo ""
echo "⬇️  Downloading Paymenter..."
mkdir -p /var/www/paymenter
cd /var/www/paymenter
curl -Lo paymenter.tar.gz https://github.com/paymenter/paymenter/releases/latest/download/paymenter.tar.gz
tar -xzvf paymenter.tar.gz
chmod -R 755 storage/* bootstrap/cache/
echo "✅ Paymenter downloaded and extracted!"

# Configure Nginx
echo ""
echo "🌐 Configuring Nginx..."
read -p "Enter your domain name or IP address: " domain
cat <<EOF > /etc/nginx/sites-available/paymenter.conf
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    root /var/www/paymenter/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/
systemctl restart nginx
echo "✅ Nginx configured!"

# Ask user if they want SSL
echo ""
read -p "🔒 Do you want to install SSL for your domain? (Y/N): " ssl_choice
if [ "$ssl_choice" = "Y" ] || [ "$ssl_choice" = "y" ]; then
    install_ssl $domain
fi

# Configure Paymenter
echo ""
echo "⚙️  Configuring Paymenter application..."
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan storage:link
echo "DB_DATABASE=paymenter" >> .env
echo "DB_USERNAME=paymenter" >> .env
echo "DB_PASSWORD=$DB_PASSWORD" >> .env
echo "✅ Application configured!"

# Run migrations
echo ""
echo "🗄️  Running database migrations..."
php artisan migrate --force --seed
echo "✅ Database migrations completed!"

# Set permissions
echo ""
echo "🔑 Setting file permissions..."
chown -R www-data:www-data /var/www/paymenter/*
echo "✅ Permissions set!"

# Configure cronjob
echo ""
echo "⏰ Setting up cron job..."
echo "* * * * * php /var/www/paymenter/artisan schedule:run >> /dev/null 2>&1" | crontab -
echo "✅ Cron job configured!"

# Create queue worker
echo ""
echo "🔄 Creating queue worker service..."
cat <<EOF > /etc/systemd/system/paymenter.service
[Unit]
Description=Paymenter Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/paymenter/artisan queue:work
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now paymenter.service
echo "✅ Queue worker service started!"

# Create First User
echo ""
echo "============================================================================"
echo "👤 Creating first admin user..."
echo "============================================================================"
cd /var/www/paymenter
php artisan p:user:create

echo ""
echo "============================================================================"
echo "  🎉 Paymenter Installation Complete! 🎉"
echo "============================================================================"
echo ""
echo "  ⚡ InfinityForge Edition - Crafted by JOY 👨‍💻"
echo ""
echo "  🌐 Access your installation at: http://$domain"
echo ""
echo "  ✨ Features installed:"
echo "     • PHP 8.2 with required extensions"
echo "     • MariaDB 10.11 database server"
echo "     • Nginx web server"
echo "     • Redis cache server"
echo "     • SSL/HTTPS support (if configured)"
echo "     • Automated queue worker"
echo "     • Scheduled task runner"
echo ""
echo "  💡 Next steps:"
echo "     1. Access your Paymenter panel at http://$domain"
echo "     2. Complete the initial setup"
echo "     3. Configure your payment gateways"
echo "     4. Start accepting payments! 💰"
echo ""
echo "============================================================================"
echo "  🙏 Thank you for using InfinityForge Edition!"
echo "  💬 For support, contact JOY"
echo "============================================================================"
