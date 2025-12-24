#!/bin/bash

# ============================================================================
# 🗑️  Paymenter Uninstallation Script
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
echo "    🗑️  Paymenter Uninstaller - InfinityForge Edition ⚡"
echo "                     👨‍💻 Crafted by JOY 👨‍💻"
echo "============================================================================"
echo ""

# Warning message
echo "⚠️  WARNING: This script will completely remove Paymenter from your system!"
echo "⚠️  This action is IRREVERSIBLE and will delete all data!"
echo ""
read -p "❓ Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Uninstallation cancelled."
    exit 0
fi

echo ""
echo "🔴 Starting uninstallation process..."
echo ""

# Stop and disable services
echo "🛑 Stopping Paymenter services..."
systemctl stop paymenter.service 2>/dev/null
systemctl disable paymenter.service 2>/dev/null
systemctl stop php8.2-fpm 2>/dev/null
systemctl stop nginx 2>/dev/null
echo "✅ Services stopped!"

# Remove systemd service file
echo ""
echo "🗑️  Removing systemd service..."
rm -f /etc/systemd/system/paymenter.service
systemctl daemon-reload
echo "✅ Systemd service removed!"

# Remove cron job
echo ""
echo "⏰ Removing cron job..."
crontab -l | grep -v "paymenter" | crontab - 2>/dev/null
echo "✅ Cron job removed!"

# Remove Nginx configuration
echo ""
echo "🌐 Removing Nginx configuration..."
rm -f /etc/nginx/sites-available/paymenter.conf
rm -f /etc/nginx/sites-enabled/paymenter.conf
systemctl restart nginx 2>/dev/null
echo "✅ Nginx configuration removed!"

# Ask about SSL certificates
echo ""
read -p "🔒 Do you want to remove SSL certificates? (Y/N): " ssl_remove
if [ "$ssl_remove" = "Y" ] || [ "$ssl_remove" = "y" ]; then
    echo "🗑️  Removing SSL certificates..."
    read -p "Enter the domain name used during installation: " domain
    certbot delete --cert-name $domain 2>/dev/null
    echo "✅ SSL certificates removed!"
fi

# Remove application files
echo ""
echo "📁 Removing Paymenter application files..."
rm -rf /var/www/paymenter
echo "✅ Application files removed!"

# Ask about database
echo ""
read -p "💾 Do you want to remove the Paymenter database? (Y/N): " db_remove
if [ "$db_remove" = "Y" ] || [ "$db_remove" = "y" ]; then
    echo "🗑️  Removing database..."
    mysql -e "DROP DATABASE IF EXISTS paymenter;" 2>/dev/null
    mysql -e "DROP USER IF EXISTS 'paymenter'@'127.0.0.1';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    echo "✅ Database and user removed!"
else
    echo "⏭️  Database preserved."
fi

# Ask about dependencies
echo ""
read -p "📦 Do you want to remove installed dependencies (PHP, MariaDB, Nginx, etc.)? (Y/N): " dep_remove
if [ "$dep_remove" = "Y" ] || [ "$dep_remove" = "y" ]; then
    echo "🗑️  Removing dependencies..."
    echo "⚠️  Note: This will remove PHP, MariaDB, Nginx, and other packages."
    read -p "❓ Are you absolutely sure? (yes/no): " dep_confirm
    
    if [ "$dep_confirm" = "yes" ]; then
        apt -y remove --purge php8.2* mariadb-server nginx redis-server composer
        apt -y autoremove
        apt -y autoclean
        echo "✅ Dependencies removed!"
    else
        echo "⏭️  Dependencies preserved."
    fi
else
    echo "⏭️  Dependencies preserved."
fi

# Remove Composer (optional)
echo ""
read -p "🎼 Do you want to remove Composer? (Y/N): " composer_remove
if [ "$composer_remove" = "Y" ] || [ "$composer_remove" = "y" ]; then
    rm -f /usr/local/bin/composer
    echo "✅ Composer removed!"
fi

# Clean up remaining files
echo ""
echo "🧹 Cleaning up remaining files..."
rm -rf /root/.composer 2>/dev/null
rm -f /tmp/paymenter* 2>/dev/null
echo "✅ Cleanup complete!"

echo ""
echo "============================================================================"
echo "  ✅ Paymenter Uninstallation Complete! ✅"
echo "============================================================================"
echo ""
echo "  ⚡ InfinityForge Edition - Crafted by JOY 👨‍💻"
echo ""
echo "  📊 Uninstallation Summary:"
echo "     • Paymenter application removed"
echo "     • Services stopped and disabled"
echo "     • Nginx configuration removed"
echo "     • Cron jobs removed"

if [ "$ssl_remove" = "Y" ] || [ "$ssl_remove" = "y" ]; then
    echo "     • SSL certificates removed"
fi

if [ "$db_remove" = "Y" ] || [ "$db_remove" = "y" ]; then
    echo "     • Database and user removed"
fi

if [ "$dep_confirm" = "yes" ]; then
    echo "     • System dependencies removed"
fi

echo ""
echo "  💡 Your system has been cleaned!"
echo ""
echo "  🔄 To reinstall Paymenter, run the installation script again."
echo ""
echo "============================================================================"
echo "  🙏 Thank you for using InfinityForge Edition!"
echo "  💬 For support, contact JOY"
echo "============================================================================"
