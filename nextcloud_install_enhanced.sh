#!/bin/bash

# Skrip instalasi Nextcloud dengan pilihan database, web server, dan domain

# Pastikan skrip dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
  echo "Harap jalankan skrip ini sebagai root."
  exit 1
fi

# Meminta input domain dari pengguna
read -p "Masukkan nama domain (misalnya: yourdomain.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
  echo "Domain tidak boleh kosong."
  exit 1
fi

# Pilih web server
echo "Pilih web server yang akan digunakan:"
echo "1) Apache2 (Recommended)"
echo "2) Nginx"
read -p "Masukkan pilihan Anda [1-2]: " WEBSERVER_CHOICE

if [[ "$WEBSERVER_CHOICE" == "1" ]]; then
  WEBSERVER="Apache2"
  WEBSERVER_INSTALL_CMD="apache2"
elif [[ "$WEBSERVER_CHOICE" == "2" ]]; then
  WEBSERVER="Nginx"
  WEBSERVER_INSTALL_CMD="nginx"
else
  echo "Pilihan tidak valid. Menggunakan Apache2 secara default."
  WEBSERVER="Apache2"
  WEBSERVER_INSTALL_CMD="apache2"
fi

# Pilih database
echo "Pilih database yang akan digunakan untuk Nextcloud:"
echo "1) MySQL (Recomeded data high)"
echo "2) MariaDB(Recomended data high)"
echo "3) SQLite (Untuk data percobaan atau masih recomeded)"
read -p "Masukkan pilihan Anda [1-3]: " DB_CHOICE

if [[ "$DB_CHOICE" == "3" ]]; then
  DB_ENGINE="SQLite"
else
  # Meminta informasi MySQL/MariaDB
  read -p "Masukkan nama database untuk Nextcloud: " DB_NAME
  read -p "Masukkan username database: " DB_USER
  read -sp "Masukkan password untuk user database: " DB_PASS
  echo
  if [[ "$DB_CHOICE" == "1" ]]; then
    DB_ENGINE="MySQL"
    DB_INSTALL_CMD="mysql-server mysql-client"
  elif [[ "$DB_CHOICE" == "2" ]]; then
    DB_ENGINE="MariaDB"
    DB_INSTALL_CMD="mariadb-server mariadb-client"
  else
    echo "Pilihan tidak valid. Skrip dihentikan."
    exit 1
  fi
fi

# Update sistem
echo "Mengupdate sistem..."
apt update
apt install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt update

# Pilih versi PHP
echo "Pilih versi PHP yang ingin digunakan:"
echo "Untuk Nexcloud PHP8.x - Latest PHP."
echo "1) PHP 7.4"
echo "2) PHP 8.0"
echo "3) PHP 8.1"
echo "4) PHP 8.2 (latest)"
read -p "Masukkan pilihan Anda [1-4]: " PHP_CHOICE

case $PHP_CHOICE in
  1) PHP_VERSION="7.4" ;;
  2) PHP_VERSION="8.0" ;;
  3) PHP_VERSION="8.1" ;;
  4) PHP_VERSION="8.2" ;;
  *) 
    echo "Pilihan tidak valid. Menggunakan PHP 8.1 secara default."
    PHP_VERSION="8.1"
    ;;
esac

# Instal web server, PHP dan dependensi
echo "Menginstal $WEBSERVER, PHP $PHP_VERSION dan dependensi..."
if [[ "$WEBSERVER" == "Nginx" ]]; then
  apt install -y $WEBSERVER_INSTALL_CMD $DB_INSTALL_CMD php$PHP_VERSION-fpm php$PHP_VERSION-sqlite3 php$PHP_VERSION-mysql php$PHP_VERSION-xml php$PHP_VERSION-mbstring php$PHP_VERSION-zip php$PHP_VERSION-curl php$PHP_VERSION-intl php$PHP_VERSION-gd php$PHP_VERSION-bcmath unzip wget curl certbot python3-certbot-nginx
else
  apt install -y $WEBSERVER_INSTALL_CMD $DB_INSTALL_CMD php$PHP_VERSION php$PHP_VERSION-sqlite3 php$PHP_VERSION-mysql php$PHP_VERSION-xml php$PHP_VERSION-mbstring php$PHP_VERSION-zip php$PHP_VERSION-curl php$PHP_VERSION-intl php$PHP_VERSION-gd php$PHP_VERSION-bcmath unzip wget curl certbot python3-certbot-apache
fi

# Konfigurasi web server
if [[ "$WEBSERVER" == "Apache2" ]]; then
  # Aktifkan modul Apache
  echo "Mengaktifkan modul Apache..."
  a2enmod rewrite headers env dir mime setenvif ssl
  systemctl restart apache2
else
  # Konfigurasi Nginx
  echo "Mengonfigurasi Nginx..."
  systemctl start nginx
  systemctl enable nginx
  systemctl start php$PHP_VERSION-fpm
  systemctl enable php$PHP_VERSION-fpm
fi

# Konfigurasi database jika SQLite tidak dipilih
if [[ "$DB_ENGINE" != "SQLite" ]]; then
  echo "Membuat database dan user $DB_ENGINE..."
  if [[ "$DB_ENGINE" == "MySQL" || "$DB_ENGINE" == "MariaDB" ]]; then
    mysql -e "CREATE DATABASE $DB_NAME;"
    mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
  fi
fi

# Download dan instal Nextcloud
echo "Mengunduh dan menginstal Nextcloud..."
cd /tmp
curl -sLo nextcloud.zip https://download.nextcloud.com/server/releases/latest.zip
unzip nextcloud.zip -d /tmp/
cp -R /tmp/nextcloud/* /var/www/html/
rm -rf /tmp/nextcloud nextcloud.zip

# Ubah kepemilikan dan izin direktori
echo "Mengatur izin direktori Nextcloud..."
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Konfigurasi Virtual Host berdasarkan web server
if [[ "$WEBSERVER" == "Apache2" ]]; then
  # Konfigurasi Apache Virtual Host
  echo "Mengonfigurasi Apache Virtual Host..."
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

  a2ensite nextcloud.conf
  systemctl reload apache2
else
  # Konfigurasi Nginx Virtual Host
  echo "Mengonfigurasi Nginx Virtual Host..."
  cat <<EOF > /etc/nginx/sites-available/nextcloud
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL configuration will be handled by Certbot
    
    # Add headers to serve security related headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;

    # Path to the root of your installation
    root /var/www/html;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # The following 2 rules are only needed for the user_webfinger app.
    location = /.well-known/host-meta {
        return 301 \$scheme://\$host\$request_uri/public.php?\$args;
    }

    location = /.well-known/host-meta.json {
        return 301 \$scheme://\$host\$request_uri/public.php?\$args;
    }

    # The following rule is only needed for the Social app.
    location = /.well-known/webfinger {
        return 301 \$scheme://\$host\$request_uri/public.php?\$args;
    }

    # The following rule is only needed for the Nodeinfo app.
    location = /.well-known/nodeinfo {
        return 301 \$scheme://\$host\$request_uri/public.php?\$args;
    }

    location / {
        # CORS preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        rewrite ^ /index.php;
    }

    location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
    }
    location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:\$|\/) {
        fastcgi_split_path_info ^(.+?\.php)(\/.*)$;
        set \$path_info \$fastcgi_path_info;
        try_files \$fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$path_info;
        fastcgi_param HTTPS on;
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ ^\/(?:updater|oc[ms]-provider)(?:\$|\/) {
        try_files \$uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js, css and map files
    location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
        try_files \$uri /index.php\$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;
        access_log off;
    }

    location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap)$ {
        try_files \$uri /index.php\$request_uri;
        access_log off;
    }

    error_log /var/log/nginx/nextcloud_error.log;
    access_log /var/log/nginx/nextcloud_access.log;
}
EOF

  # Aktifkan konfigurasi Nginx
  ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
  # Hapus konfigurasi default jika ada
  rm -f /etc/nginx/sites-enabled/default
  # Test konfigurasi Nginx
  nginx -t
  systemctl reload nginx
fi

# Simpan log data instalasi
cat <<EOF > ~/.logsdata.txt
Data base instalasi.
Web Server : $WEBSERVER
Domain Name : $DOMAIN
Database Name : $DB_NAME
Database User : $DB_USER
Database Password : $DB_PASS
PHP Version : $PHP_VERSION
EOF
chmod 600 ~/.logsdata.txt

# Instalasi SSL dengan Certbot
echo "Menginstal SSL dengan Certbot..."
if [[ "$WEBSERVER" == "Apache2" ]]; then
  certbot --apache -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
else
  certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
fi

# Finalisasi
echo "Instalasi Nextcloud selesai."
echo "Web Server: $WEBSERVER"
echo "Database: $DB_ENGINE"
echo "PHP Version: $PHP_VERSION"
echo "Nextcloud Anda dapat diakses di http://$DOMAIN atau https://$DOMAIN"