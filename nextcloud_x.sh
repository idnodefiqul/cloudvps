#!/bin/bash

# ===============================================================================
# 🚀 Professional Nextcloud Installer v2.0
# ===============================================================================
# Automated Nextcloud installation with database options and SSL configuration
# Supports: MySQL, MariaDB, SQLite | PHP 7.4-8.2 | Auto SSL with Let's Encrypt
# ===============================================================================

# Color definitions for professional output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Unicode symbols
CHECK="✓"
CROSS="✗"
ARROW="➤"
STAR="★"
GEAR="⚙"
CLOUD="☁"
LOCK="🔒"

# Banner function
show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "══════════════════════════════════════════════════════════════════════════"
    echo "                    ${CLOUD} NEXTCLOUD PROFESSIONAL INSTALLER ${CLOUD}"
    echo "                                  Version 2.0"
    echo "══════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}Features:${NC}"
    echo -e "  ${ARROW} Automated installation with zero configuration"
    echo -e "  ${ARROW} Multiple database support (MySQL/MariaDB/SQLite)"
    echo -e "  ${ARROW} PHP version selection (7.4 - 8.2)"
    echo -e "  ${ARROW} Auto SSL certificate with Let's Encrypt"
    echo -e "  ${ARROW} Production-ready Apache configuration"
    echo ""
}

# Progress indicator
show_progress() {
    local message=$1
    echo -e "${BLUE}${BOLD}[${GEAR}] ${message}...${NC}"
}

# Success message
show_success() {
    local message=$1
    echo -e "${GREEN}${BOLD}[${CHECK}] ${message}${NC}"
}

# Error message
show_error() {
    local message=$1
    echo -e "${RED}${BOLD}[${CROSS}] ${message}${NC}"
}

# Warning message
show_warning() {
    local message=$1
    echo -e "${YELLOW}${BOLD}[!] ${message}${NC}"
}

# Information box
show_info_box() {
    local title=$1
    local content=$2
    echo -e "${WHITE}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${WHITE}${BOLD}│ ${STAR} ${title}${NC}$(printf "%*s" $((74 - ${#title})) "")${WHITE}${BOLD}│${NC}"
    echo -e "${WHITE}${BOLD}├────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}${BOLD}│${NC} ${content}$(printf "%*s" $((74 - ${#content})) "")${WHITE}${BOLD}│${NC}"
    echo -e "${WHITE}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

# Input function with validation
get_input() {
    local prompt=$1
    local var_name=$2
    local is_password=$3
    
    while true; do
        echo -e "${CYAN}${BOLD}${ARROW} ${prompt}:${NC}"
        if [[ "$is_password" == "true" ]]; then
            read -sp "   " input
            echo
        else
            read -p "   " input
        fi
        
        if [[ -n "$input" ]]; then
            eval "$var_name='$input'"
            break
        else
            show_error "Input tidak boleh kosong. Silakan coba lagi."
        fi
    done
}

# Menu selection function
show_menu() {
    local title=$1
    shift
    local options=("$@")
    
    echo -e "${PURPLE}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}${BOLD}│ ${title}${NC}$(printf "%*s" $((74 - ${#title})) "")${PURPLE}${BOLD}│${NC}"
    echo -e "${PURPLE}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}"
    
    for i in "${!options[@]}"; do
        echo -e "  ${YELLOW}${BOLD}$((i+1)))${NC} ${options[$i]}"
    done
    echo ""
}

# Check root privileges
check_root() {
    if [ "$(id -u)" != "0" ]; then
        show_error "Installer ini harus dijalankan sebagai root user"
        show_warning "Silakan jalankan: sudo $0"
        exit 1
    fi
    show_success "Root privileges verified"
}

# System requirements check
check_requirements() {
    show_progress "Checking system requirements"
    
    # Check Ubuntu/Debian
    if ! command -v apt &> /dev/null; then
        show_error "System ini membutuhkan Ubuntu/Debian dengan APT package manager"
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        show_error "Koneksi internet diperlukan untuk instalasi"
        exit 1
    fi
    
    show_success "System requirements check passed"
}

# Main installation function
main() {
    show_banner
    check_root
    check_requirements
    
    echo -e "${GREEN}${BOLD}Selamat datang di Professional Nextcloud Installer!${NC}"
    echo ""
    
    # Domain input
    show_info_box "DOMAIN CONFIGURATION" "Enter your domain name for Nextcloud installation"
    get_input "Masukkan nama domain (contoh: nextcloud.yourdomain.com)" DOMAIN
    
    # Database selection
    echo ""
    show_menu "DATABASE SELECTION" \
        "MySQL (Recommended for production & high traffic)" \
        "MariaDB (Recommended for production & high traffic)" \
        "SQLite (Recommended for testing or low traffic)"
    
    while true; do
        get_input "Pilih database [1-3]" DB_CHOICE
        case $DB_CHOICE in
            1|2|3) break ;;
            *) show_error "Pilihan tidak valid. Masukkan angka 1, 2, atau 3." ;;
        esac
    done
    
    # Database configuration
    if [[ "$DB_CHOICE" == "3" ]]; then
        DB_ENGINE="SQLite"
        show_success "SQLite dipilih untuk database"
    else
        echo ""
        show_info_box "DATABASE CREDENTIALS" "Configure your database connection"
        get_input "Nama database untuk Nextcloud" DB_NAME
        get_input "Username database" DB_USER
        get_input "Password database" DB_PASS true
        
        if [[ "$DB_CHOICE" == "1" ]]; then
            DB_ENGINE="MySQL"
            DB_INSTALL_CMD="mysql-server mysql-client"
        else
            DB_ENGINE="MariaDB"
            DB_INSTALL_CMD="mariadb-server mariadb-client"
        fi
        show_success "$DB_ENGINE dipilih untuk database"
    fi
    
    # PHP version selection
    echo ""
    show_menu "PHP VERSION SELECTION" \
        "PHP 7.4 (Legacy support)" \
        "PHP 8.0 (Stable)" \
        "PHP 8.1 (Recommended)" \
        "PHP 8.2 (Latest stable)"
    
    while true; do
        get_input "Pilih versi PHP [1-4]" PHP_CHOICE
        case $PHP_CHOICE in
            1) PHP_VERSION="7.4"; break ;;
            2) PHP_VERSION="8.0"; break ;;
            3) PHP_VERSION="8.1"; break ;;
            4) PHP_VERSION="8.2"; break ;;
            *)
                show_warning "Pilihan tidak valid. Menggunakan PHP 8.1 (default)"
                PHP_VERSION="8.1"
                break
                ;;
        esac
    done
    
    show_success "PHP $PHP_VERSION dipilih"
    
    # Installation confirmation
    echo ""
    echo -e "${WHITE}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${WHITE}${BOLD}│ ${STAR} INSTALLATION SUMMARY${NC}$(printf "%*s" 56 "")${WHITE}${BOLD}│${NC}"
    echo -e "${WHITE}${BOLD}├────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}${BOLD}│${NC} Domain        : ${CYAN}$DOMAIN${NC}$(printf "%*s" $((63 - ${#DOMAIN})) "")${WHITE}${BOLD}│${NC}"
    echo -e "${WHITE}${BOLD}│${NC} Database      : ${CYAN}$DB_ENGINE${NC}$(printf "%*s" $((63 - ${#DB_ENGINE})) "")${WHITE}${BOLD}│${NC}"
    echo -e "${WHITE}${BOLD}│${NC} PHP Version   : ${CYAN}$PHP_VERSION${NC}$(printf "%*s" $((63 - ${#PHP_VERSION})) "")${WHITE}${BOLD}│${NC}"
    echo -e "${WHITE}${BOLD}│${NC} SSL Certificate: ${CYAN}Let's Encrypt (Auto)${NC}$(printf "%*s" 43 "")${WHITE}${BOLD}│${NC}"
    echo -e "${WHITE}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    
    read -p "$(echo -e ${YELLOW}${BOLD}Lanjutkan instalasi? [Y/n]: ${NC})" CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        show_warning "Instalasi dibatalkan oleh user"
        exit 0
    fi
    
    # Start installation process
    echo ""
    echo -e "${GREEN}${BOLD}🚀 Starting Professional Nextcloud Installation...${NC}"
    echo ""
    
    # Update system
    show_progress "Updating system packages"
    apt update &>/dev/null
    apt install -y software-properties-common &>/dev/null
    add-apt-repository ppa:ondrej/php -y &>/dev/null
    apt update &>/dev/null
    show_success "System packages updated"
    
    # Install packages
    show_progress "Installing PHP $PHP_VERSION and dependencies"
    apt install -y apache2 $DB_INSTALL_CMD php$PHP_VERSION php$PHP_VERSION-sqlite3 php$PHP_VERSION-mysql php$PHP_VERSION-xml php$PHP_VERSION-mbstring php$PHP_VERSION-zip php$PHP_VERSION-curl php$PHP_VERSION-intl php$PHP_VERSION-gd php$PHP_VERSION-bcmath unzip wget curl certbot python3-certbot-apache &>/dev/null
    show_success "PHP and dependencies installed"
    
    # Configure Apache
    show_progress "Configuring Apache web server"
    a2enmod rewrite headers env dir mime setenvif ssl &>/dev/null
    systemctl restart apache2 &>/dev/null
    show_success "Apache configured and restarted"
    
    # Configure database
    if [[ "$DB_ENGINE" != "SQLite" ]]; then
        show_progress "Configuring $DB_ENGINE database"
        mysql -e "CREATE DATABASE $DB_NAME;" &>/dev/null
        mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" &>/dev/null
        mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" &>/dev/null
        mysql -e "FLUSH PRIVILEGES;" &>/dev/null
        show_success "$DB_ENGINE database configured"
    fi
    
    # Download and install Nextcloud
    show_progress "Downloading and installing Nextcloud"
    cd /tmp
    curl -sLo nextcloud.zip https://download.nextcloud.com/server/releases/latest.zip &>/dev/null
    unzip nextcloud.zip -d /tmp/ &>/dev/null
    cp -R /tmp/nextcloud/* /var/www/html/ &>/dev/null
    rm -rf /tmp/nextcloud nextcloud.zip &>/dev/null
    show_success "Nextcloud downloaded and extracted"
    
    # Set permissions
    show_progress "Setting file permissions"
    chown -R www-data:www-data /var/www/html/
    chmod -R 755 /var/www/html/
    show_success "File permissions configured"
    
    # Configure Apache Virtual Host
    show_progress "Configuring Apache Virtual Host"
    cat <<EOF > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
    ServerAdmin admin@$DOMAIN
    DocumentRoot /var/www/html
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    <Directory /var/www/html>
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
    
    # Save installation data
    cat <<EOF > ~/.nextcloud_install_data.txt
═══════════════════════════════════════════════════════════════════════════════
${CLOUD} NEXTCLOUD INSTALLATION DATA ${CLOUD}
═══════════════════════════════════════════════════════════════════════════════
Installation Date    : $(date)
Domain Name         : $DOMAIN
Database Engine     : $DB_ENGINE
Database Name       : $DB_NAME
Database User       : $DB_USER
Database Password   : $DB_PASS
PHP Version         : $PHP_VERSION
SSL Certificate     : Let's Encrypt
═══════════════════════════════════════════════════════════════════════════════
${LOCK} KEEP THIS FILE SECURE - Contains sensitive information ${LOCK}
═══════════════════════════════════════════════════════════════════════════════
EOF
    chmod 600 ~/.nextcloud_install_data.txt
    
    a2ensite nextcloud.conf &>/dev/null
    systemctl reload apache2 &>/dev/null
    show_success "Apache Virtual Host configured"
    
    # Install SSL
    show_progress "Installing SSL certificate with Let's Encrypt"
    certbot --apache -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
    show_success "SSL certificate installed"
    
    # Installation complete
    echo ""
    echo -e "${GREEN}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${GREEN}${BOLD}│ ${STAR} INSTALLATION COMPLETED SUCCESSFULLY! ${STAR}${NC}$(printf "%*s" 37 "")${GREEN}${BOLD}│${NC}"
    echo -e "${GREEN}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}🌐 Access your Nextcloud installation:${NC}"
    echo -e "   ${ARROW} HTTP:  ${WHITE}http://$DOMAIN${NC}"
    echo -e "   ${ARROW} HTTPS: ${WHITE}https://$DOMAIN${NC} ${GREEN}(Recommended)${NC}"
    echo ""
    echo -e "${YELLOW}${BOLD}📋 Installation Details:${NC}"
    echo -e "   ${ARROW} Installation data saved to: ${WHITE}~/.nextcloud_install_data.txt${NC}"
    echo -e "   ${ARROW} Apache logs: ${WHITE}/var/log/apache2/nextcloud_*.log${NC}"
    echo -e "   ${ARROW} Nextcloud directory: ${WHITE}/var/www/html/${NC}"
    echo ""
    echo -e "${PURPLE}${BOLD}🔧 Next Steps:${NC}"
    echo -e "   1. Open your browser and navigate to https://$DOMAIN"
    echo -e "   2. Create your admin account"
    echo -e "   3. Configure your Nextcloud settings"
    echo -e "   4. Enjoy your personal cloud storage!"
    echo ""
    echo -e "${GREEN}${BOLD}Thank you for using Professional Nextcloud Installer! ${STAR}${NC}"
    echo ""
}

# Run main function
main
