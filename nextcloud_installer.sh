#!/bin/bash

# Nextcloud Auto Installer Script
# Compatible with Ubuntu/Debian systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  NEXTCLOUD AUTO INSTALLER${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

# Update system
update_system() {
    print_status "Updating system packages..."
    apt update && apt upgrade -y
    apt install -y wget curl unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
}

# Web Server Selection
select_webserver() {
    echo
    print_status "Pilih Web Server:"
    echo "1) Apache2"
    echo "2) Nginx"
    
    while true; do
        read -p "Masukkan pilihan (1-2): " webserver_choice
        case $webserver_choice in
            1)
                WEBSERVER="apache2"
                print_status "Apache2 dipilih"
                break
                ;;
            2)
                WEBSERVER="nginx"
                print_status "Nginx dipilih"
                break
                ;;
            *)
                print_warning "Pilihan tidak valid. Silakan pilih 1 atau 2."
                ;;
        esac
    done
}

# Database Selection
select_database() {
    echo
    print_status "Pilih Database:"
    echo "1) MySQL"
    echo "2) MariaDB"
    echo "3) SQLite"
    
    while true; do
        read -p "Masukkan pilihan (1-3): " db_choice
        case $db_choice in
            1)
                DATABASE="mysql"
                print_status "MySQL dipilih"
                break
                ;;
            2)
                DATABASE="mariadb"
                print_status "MariaDB dipilih"
                break
                ;;
            3)
                DATABASE="sqlite"
                print_status "SQLite dipilih"
                break
                ;;
            *)
                print_warning "Pilihan tidak valid. Silakan pilih 1-3."
                ;;
        esac
    done
}

# PHP Version Selection
select_php_version() {
    echo
    print_status "Pilih versi PHP:"
    echo "1) PHP 7.4"
    echo "2) PHP 8.0"
    echo "3) PHP 8.1"
    echo "4) PHP 8.2"
    echo "5) PHP 8.3"
    echo "6) PHP 8.4 (Latest)"
    
    while true; do
        read -p "Masukkan pilihan (1-6): " php_choice
        case $php_choice in
            1)
                PHP_VERSION="7.4"
                break
                ;;
            2)
                PHP_VERSION="8.0"
                break
                ;;
            3)
                PHP_VERSION="8.1"
                break
                ;;
            4)
                PHP_VERSION="8.2"
                break
                ;;
            5)
                PHP_VERSION="8.3"
                break
                ;;
            6)
                PHP_VERSION="8.4"
                break
                ;;
            *)
                print_warning "Pilihan tidak valid. Silakan pilih 1-6."
                ;;
        esac
    done
    print_status "PHP $PHP_VERSION dipilih"
}

# Domain Configuration
configure_domain() {
    echo
    print_status "Konfigurasi Domain:"
    read -p "Masukkan domain untuk Nextcloud (contoh: nextcloud.example.com): " DOMAIN
    
    while [[ -z "$DOMAIN" ]]; do
        print_warning "Domain tidak boleh kosong!"
        read -p "Masukkan domain untuk Nextcloud: " DOMAIN
    done
    
    print_status "Domain yang akan digunakan: $DOMAIN"
    
    echo
    read -p "Apakah Anda ingin mengaktifkan SSL/HTTPS dengan Let's Encrypt? (y/n): " ssl_choice
    case $ssl_choice in
        [Yy]* )
            ENABLE_SSL=true
            read -p "Masukkan email untuk Let's Encrypt: " LETSENCRYPT_EMAIL
            ;;
        * )
            ENABLE_SSL=false
            ;;
    esac
}

# Database Configuration
configure_database() {
    if [[ $DATABASE != "sqlite" ]]; then
        echo
        print_status "Konfigurasi Database:"
        read -p "Nama database untuk Nextcloud: " DB_NAME
        read -p "Username database: " DB_USER
        read -s -p "Password database: " DB_PASS
        echo
        read -s -p "Root password database: " DB_ROOT_PASS
        echo
    fi
}

# Install PHP
install_php() {
    print_status "Installing PHP $PHP_VERSION..."
    
    # Add PHP repository
    add-apt-repository ppa:ondrej/php -y
    apt update
    
    # Install PHP and required extensions
    apt install -y \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-apcu \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common
    
    # Configure PHP
    sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/${PHP_VERSION}/fpm/php.ini
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 200M/" /etc/php/${PHP_VERSION}/fpm/php.ini
    sed -i "s/post_max_size = .*/post_max_size = 200M/" /etc/php/${PHP_VERSION}/fpm/php.ini
    sed -i "s/max_execution_time = .*/max_execution_time = 360/" /etc/php/${PHP_VERSION}/fpm/php.ini
    sed -i "s/max_input_time = .*/max_input_time = 360/" /etc/php/${PHP_VERSION}/fpm/php.ini
}

# Install Database
install_database() {
    if [[ $DATABASE == "mysql" ]]; then
        print_status "Installing MySQL..."
        apt install -y mysql-server
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_ROOT_PASS';"
        mysql -u root -p${DB_ROOT_PASS} -e "CREATE DATABASE $DB_NAME;"
        mysql -u root -p${DB_ROOT_PASS} -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
        mysql -u root -p${DB_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
        mysql -u root -p${DB_ROOT_PASS} -e "FLUSH PRIVILEGES;"
    elif [[ $DATABASE == "mariadb" ]]; then
        print_status "Installing MariaDB..."
        apt install -y mariadb-server
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';"
        mysql -u root -p${DB_ROOT_PASS} -e "CREATE DATABASE $DB_NAME;"
        mysql -u root -p${DB_ROOT_PASS} -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
        mysql -u root -p${DB_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
        mysql -u root -p${DB_ROOT_PASS} -e "FLUSH PRIVILEGES;"
    else
        print_status "SQLite will be used (no additional installation required)"
    fi
}

# Install Certbot for SSL
install_certbot() {
    if [[ $ENABLE_SSL == true ]]; then
        print_status "Installing Certbot for SSL certificates..."
        apt install -y certbot
        
        if [[ $WEBSERVER == "apache2" ]]; then
            apt install -y python3-certbot-apache
        else
            apt install -y python3-certbot-nginx
        fi
    fi
}
    if [[ $WEBSERVER == "apache2" ]]; then
        print_status "Installing Apache2..."
        apt install -y apache2 libapache2-mod-php${PHP_VERSION}
        
        # Enable required modules
        a2enmod rewrite headers env dir mime ssl
        a2enmod php${PHP_VERSION}
        
# Install Web Server
install_webserver() {
    if [[ $WEBSERVER == "apache2" ]]; then
        print_status "Installing Apache2..."
        apt install -y apache2 libapache2-mod-php${PHP_VERSION}
        
        # Enable required modules
        a2enmod rewrite headers env dir mime ssl
        a2enmod php${PHP_VERSION}
        
        # Create virtual host
        cat > /etc/apache2/sites-available/nextcloud.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud
    ServerName $DOMAIN
    
    <Directory /var/www/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOF
        
        a2ensite nextcloud.conf
        a2dissite 000-default.conf
        
    else
        print_status "Installing Nginx..."
        apt install -y nginx
        
        # Create nginx config
        cat > /etc/nginx/sites-available/nextcloud << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/nextcloud;
    index index.php index.html index.htm;
    
    client_max_body_size 200M;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    location = /.well-known/carddav {
        return 301 \$scheme://\$host:\$server_port/remote.php/dav;
    }
    
    location = /.well-known/caldav {
        return 301 \$scheme://\$host:\$server_port/remote.php/dav;
    }
}
EOF
        
        ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
    fi
}
}

# Download and Install Nextcloud
install_nextcloud() {
    print_status "Downloading Nextcloud..."
    cd /tmp
    wget https://download.nextcloud.com/server/releases/latest.zip
    unzip latest.zip
    
    print_status "Installing Nextcloud..."
    mv nextcloud /var/www/
    chown -R www-data:www-data /var/www/nextcloud
    chmod -R 755 /var/www/nextcloud
}

# Configure SSL with Let's Encrypt
configure_ssl() {
    if [[ $ENABLE_SSL == true ]]; then
        print_status "Configuring SSL with Let's Encrypt..."
        
        if [[ $WEBSERVER == "apache2" ]]; then
            certbot --apache -d $DOMAIN --email $LETSENCRYPT_EMAIL --agree-tos --non-interactive --redirect
        else
            certbot --nginx -d $DOMAIN --email $LETSENCRYPT_EMAIL --agree-tos --non-interactive --redirect
        fi
        
        # Setup auto-renewal
        crontab -l | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | crontab -
        
        print_status "SSL certificate configured successfully!"
    fi
}

# Start Services
start_services() {
    print_status "Starting services..."
    
    systemctl enable php${PHP_VERSION}-fpm
    systemctl start php${PHP_VERSION}-fpm
    
    if [[ $DATABASE == "mysql" ]]; then
        systemctl enable mysql
        systemctl start mysql
    elif [[ $DATABASE == "mariadb" ]]; then
        systemctl enable mariadb
        systemctl start mariadb
    fi
    
    if [[ $WEBSERVER == "apache2" ]]; then
        systemctl enable apache2
        systemctl restart apache2
    else
        systemctl enable nginx
        systemctl restart nginx
    fi
}

# Display Installation Summary
show_summary() {
    echo
    print_header
    print_status "INSTALASI SELESAI!"
    echo
    echo -e "${GREEN}Konfigurasi:${NC}"
    echo "- Web Server: $WEBSERVER"
    echo "- Database: $DATABASE"
    echo "- Domain: $DOMAIN"
    if [[ $ENABLE_SSL == true ]]; then
        echo "- SSL: Enabled (Let's Encrypt)"
    else
        echo "- SSL: Disabled"
    fi
    echo "- PHP Version: $PHP_VERSION"
    echo "- Nextcloud Path: /var/www/nextcloud"
    echo
    echo -e "${GREEN}Akses Nextcloud:${NC}"
    if [[ $ENABLE_SSL == true ]]; then
        echo "URL: https://$DOMAIN"
    else
        echo "URL: http://$DOMAIN"
    fi
    echo
    
    if [[ $DATABASE != "sqlite" ]]; then
        echo -e "${GREEN}Database Info:${NC}"
        echo "- Database Name: $DB_NAME"
        echo "- Database User: $DB_USER"
        echo "- Database Password: $DB_PASS"
        echo
    fi
    
    echo -e "${YELLOW}Langkah selanjutnya:${NC}"
    echo "1. Buka browser dan akses URL di atas"
    echo "2. Buat akun admin Nextcloud"
    if [[ $DATABASE != "sqlite" ]]; then
        echo "3. Gunakan informasi database di atas untuk konfigurasi"
    else
        echo "3. Pilih SQLite sebagai database"
    fi
    echo "4. Selesaikan setup melalui web interface"
    echo
}

# Main execution
main() {
    print_header
    check_root
    
    # Get user selections
    select_webserver
    select_database
    select_php_version
    configure_domain
    configure_database
    
    # Start installation
    print_status "Memulai instalasi..."
    update_system
    install_php
    install_database
    install_certbot
    install_webserver
    install_nextcloud
    start_services
    configure_ssl
    
    show_summary
}

# Run main function
main "$@"