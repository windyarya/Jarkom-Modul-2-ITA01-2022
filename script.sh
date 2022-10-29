#!/bin/bash

# Ostania
Ostania() {
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE -s 10.40.0.0/16
    apt-get update
}

WISE() {
echo "
    nameserver 192.168.122.1
" > /etc/resolv.conf

apt-get update
apt-get install bind9 -y

# no 2,4,5,6
echo '
zone "wise.ita01.com" {
    type master;
    notify yes;
    also-notify {10.40.3.2;};
    allow-transfer {10.40.3.2;};
    file "/etc/bind/wise/wise.ita01.com";
};

zone "2.40.10.in-addr.arpa" {
    type master;
    file "/etc/bind/wise/2.40.10.in-addr.arpa";
};
' > /etc/bind/named.conf.local

mkdir /etc/bind/wise

echo "
\$TTL   604800
@       IN      SOA     wise.ita01.com. root.wise.ita01.com. (
                        2022102501      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
@               IN      NS      wise.ita01.com.
@               IN      A       10.40.3.3       ; IP WISE
www             IN      CNAME   wise.ita01.com.
; No 3 mulai di sini
eden            IN      A       10.40.3.3       ; IP Eden
www.eden        IN      CNAME   eden.wise.ita01.com.
; No 6 mulai di sini
ns1             IN      A       10.40.3.2       ; IP Berlint
operation       IN      NS      ns1
" > /etc/bind/wise/wise.ita01.com
service bind9 restart

# no 6
echo "
options {
    directory \"/var/cache/bind\";

    // If there is a firewall between you and nameservers you want
    // to talk to, you may need to fix the firewall to allow multiple
    // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

    // If your ISP provided one or more IP addresses for stable
    // nameservers, you probably want to use them as forwarders.
    // Uncomment the following block, and insert the addresses replacing
    // the all-0's placeholder.
        
    // forwarders {
    //      0.0.0.0;
    // };

    //=====================================================================
    // If BIND logs error messages about the root key being expired,
    // you will need to update your keys.  See https://www.isc.org/bind-keys
    //=====================================================================
    //dnssec-validation auto;
        
    allow-query{any;};
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
" > /etc/bind/named.conf.options

# no 4
echo "
\$TTL   604800
@       IN      SOA     wise.ita01.com. root.wise.ita01.com. (
                        2022102501      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
3.40.10.in-addr.arpa.   IN      NS      wise.ita01.com.
3                       IN      PTR     wise.ita01.com.
" > /etc/bind/wise/2.40.10.in-addr.arpa
service bind9 restart
}

Berlint() {
echo "
    nameserver 192.168.122.1
" > /etc/resolv.conf

apt-get update
apt-get install bind9 -y

# no 6
echo '
zone "wise.ita01.com" {
    type slave;
    masters { 10.40.2.2; };
    file "/var/lib/bind/wise.ita01.com";
};

zone "operation.wise.ita01.com" {
    type master;
    file "/etc/bind/operation/operation.wise.ita01.com";
};
' > /etc/bind/named.conf.local

echo "
options {
    directory \"/var/cache/bind\";
    // If there is a firewall between you and nameservers you want
    // to talk to, you may need to fix the firewall to allow multiple
    // ports to talk.  See http://www.kb.cert.org/vuls/id/800113
    // If your ISP provided one or more IP addresses for stable 
    // nameservers, you probably want to use them as forwarders.  
    // Uncomment the following block, and insert the addresses replacing 
    // the all-0's placeholder.
    // forwarders {
    //      0.0.0.0;
    // };
    //=====================================================================
    // If BIND logs error messages about the root key being expired,
    // you will need to update your keys.  See https://www.isc.org/bind-keys
    //=====================================================================
    //dnssec-validation auto;

    allow-query{any;};
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
"> /etc/bind/named.conf.options

mkdir -p /etc/bind/operation

# no 7
echo "
\$TTL   604800
@       IN      SOA     operation.wise.ita01.com.       root.operation.wise.ita01.com.
                        2022102501      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
@               IN      NS      operation.wise.ita01.com.
@               IN      A       10.40.3.3
www             IN      CNAME   operation.wise.ita01.com.
strix           IN      A       10.40.3.3
www.strix       IN      CNAME   strix.operation.wise.ita01.com.
" > /etc/bind/operation/operation.wise.ita01.com

service bind9 restart
}

Eden() {
echo "
nameserver 192.168.122.1
" > /etc/resolv.conf

apt-get update

apt-get install wget -y
apt-get install unzip -y
apt-get install apache2 -y
service apache2 start
apt-get install php -y
apt-get install libapache2-mod-php7.0 -y
apt-get install ca-certificates openssl -y
apt-get install apache2-utils -y 

# no 8
echo "
<VirtualHost *:80>
ServerAdmin webmaster@localhost
    DocumentRoot /var/www/wise.ita01.com
    ServerName wise.ita01.com
    ServerAlias www.wise.ita01.com
    # No 9
    Alias "/home" "/var/www/wise.ita01.com/index.php/home"

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/wise.ita01.com.conf

mkdir /var/www/wise.ita01.com
wget -c "https://drive.google.com/uc?export=download&id=1S0XhL9ViYN7TyCj2W66BNEW66BNEXQD2AAAw2e" -O wise.zip
unzip /root/wise.zip
cp -r /root/wise/. /var/www/wise.ita01.com
a2ensite wise.ita01.com
a2enmod rewrite
service apache2 restart

# no 10
echo "
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/eden.wise.ita01.com
    ServerName eden.wise.ita01.com
    ServerAlias www.eden.wise.ita01.com
    # no 11
    <Directory /var/www/eden.wise.ita01.com/public>
        Options +Indexes
    </Directory>

    Alias "/public" "/var/www/eden.wise.ita01.com/public"

    # no 13
    Alias "/js" "/var/www/eden.wise.ita01.com/public/js"

    # no 12
    ErrorDocument 404 /error/404.html
    ErrorDocument 500 /error/404.html
    ErrorDocument 502 /error/404.html
    ErrorDocument 503 /error/404.html
    ErrorDocument 504 /error/404.html

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    # no 17
    <Directory /var/www/eden.wise.ita01.com>
        Options +FollowSymLinks -Multiviews
        AllowOverride All
        </Directory>
</VirtualHost>
" > /etc/apache2/sites-available/eden.wise.ita01.com.conf

mkdir /var/www/eden.wise.ita01.com
wget -c "https://drive.google.com/uc?export=download&id=1q9g6nM85bW5T9f5yoyXtDqoyXtDqonUKKCHOTV" -O eden.wise.zip
unzip /root/eden.wise.zip
cp -r /root/eden.wise/. /var/www/eden.wise.ita01.com
a2ensite eden.wise.ita01.com
a2enmod rewrite

# no 14
echo "
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen 80
Listen 15000
Listen 15500

<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule>
" > /etc/apache2/ports.conf

htpasswd -c -b /var/www/strix.operation.wise.ita01 Twilight opStrix

echo "
<VirtualHost *:15000>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/strix.operation.wise.ita01.com
    ServerName strix.operation.wise.ita01.com
    ServerAlias www.strix.operation.wise.ita01.com

    <Directory \"/var/www/strix.operation.wise.ita01.com\">
        AuthType Basic
        AuthName \"Restricted Content\"
        AuthUserFile /var/www/strix.operation.wise.ita01
        Require valid-user
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
<VirtualHost *:15500>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/strix.operation.wise.ita01.com
        ServerName strix.operation.wise.ita01.com
        ServerAlias www.strix.operation.wise.ita01.com
        # no 15 sudah work
        <Directory \"/var/www/strix.operation.wise.ita01.com\">
            AuthType Basic
            AuthName \"Restricted Content\"
            AuthUserFile /var/www/strix.operation.wise.ita01
            Require valid-user
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/strix.operation.wise.ita01.com.conf

mkdir /var/www/strix.operation.wise.ita01.com
wget -c "https://drive.google.com/uc?export=download&id=1bgd3B6VtDtVv2ouqyM8wLyyM8wLyZGzK5C9maT" -O strix.operation.wise.zip
unzip strix.operation.wise.zip
cp -r /root/strix.operation.wise/. /var/www/strix.operation.wise.ita01.com
a2ensite strix.operation.wise.ita01.com
a2enmod rewrite
service apache2 restart

# no 16
echo "
<VirtualHost *:80>
    Redirect 301 / http://www.wise.ita01.com
    
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/000-default.conf

service apache2 restart

# no 17
echo '
RewriteEngine On
RewriteCond %{REQUEST_URI} !^/public/images/eden.png$
RewriteCond %{REQUEST_FILENAME} !-d 
RewriteRule ^(.*)eden(.*)$ /public/images/eden.png [R=301,L]
' > /var/www/eden.wise.ita01.com/.htaccess

a2ensite eden.wise.ita01.com
}

SSS() {
echo "
nameserver 10.40.3.3
nameserver 10.40.2.2
nameserver 10.40.3.2
nameserver 192.168.122.1
" > /etc/resolv.conf

apt-get update
apt-get install dnsutils -y
apt-get install lynx -y
}

Garden() {
echo '
nameserver 10.40.3.3
nameserver 10.40.2.2
nameserver 10.40.3.2
nameserver 192.168.122.1
' > /etc/resolv.conf

apt-get update
apt-get install dnsutils -y
apt-get install lynx -y
}