#!/bin/bash





# Variables
DOMAIN='terraform.mydocker.ga'
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'
WEB_USER='www-data'
USER='yourusername'
NGINX_SCHEME='$scheme'
NGINX_REQUEST_URI='$request_uri'

# Functions
ok() { echo -e '\e[32m'$DOMAIN'\e[m'; } # Green
die() { echo -e '\e[1;31m'$DOMAIN'\e[m'; exit 1; }


# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$DOMAIN <<EOF
# www to non-www
server {
    # If user goes to www direc them to non www
    server_name *.$DOMAIN;
    return 301 $NGINX_SCHEME://$DOMAIN$NGINX_REQUEST_URI;
}
server {
    # Just the server name
    server_name $DOMAIN;
    root        /var/www/$DOMAIN/public_html;

    # Logs
    access_log $WEB_DIR/$DOMAIN/logs/access.log;
    error_log  $WEB_DIR/$DOMAIN/logs/error.log;

    # Includes
    # include global/common.conf;
    # include global/wordpress.conf;

    # Listen to port 8080, cause of Varnis
    # Must be defined after the common.conf include
    #listen 127.0.0.1:8080;
}
EOF

# Creating {public,log} directories
mkdir -p $WEB_DIR/$DOMAIN/{public_html,logs}

# Creating index.html file
cat > $WEB_DIR/$DOMAIN/public_html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
        <title>$DOMAIN</title>
        <meta charset="utf-8" />
</head>
<body class="container">
        <header><h1>$DOMAIN<h1></header>
        <div id="wrapper">

Hello World
</div>
        <footer>© $(date +%Y)</footer>
</body>
</html>
EOF

# Changing permissions
chown -R $USER:$WEB_USER $WEB_DIR/$DOMAIN

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE_VHOSTS/$DOMAIN $NGINX_ENABLED_VHOSTS/$DOMAIN

# Restart
echo "nginx  restart again"
/etc/init.d/nginx restart

ok "Site Created for $DOMAIN"       
