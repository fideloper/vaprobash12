#!/usr/bin/env bash

echo ">>> Installing October"

# Test if PHP is installed
php -v > /dev/null 2>&1 || { printf "!!! PHP is not installed.\n    Installing October aborted!\n"; exit 0; }

# Test if Composer is installed
composer -v > /dev/null 2>&1 || { printf "!!! Composer is not installed.\n    Installing October aborted!\n"; exit 0; }

# Test if Composer is installed
composer -v > /dev/null 2>&1 || { printf "!!! Composer is not installed.\n    Installing October aborted!"; exit 0; }

# Test if Server IP is set in Vagrantfile
[[ -z "$1" ]] && { printf "!!! IP address not set. Check the Vagrantfile.\n    Installing October aborted!\n"; exit 0; }

# Check if October root is set. If not set use default
if [ -z "$2" ]; then
    october_root_folder="/vagrant/october"
else
    october_root_folder="$2"
fi

# Test if HHVM is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

# Test if Apache or Nginx is installed
nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

apache2 -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?

# Create October folder if needed
if [ ! -d $october_root_folder ]; then
    mkdir -p $october_root_folder
fi

if [ ! -f "$october_root_folder/composer.json" ]; then
    # Create October
    if [ $HHVM_IS_INSTALLED -eq 0 ]; then
        hhvm /usr/local/bin/composer create-project --prefer-dist october/october:dev-master $october_root_folder
    else
        composer create-project --prefer-dist october/october:dev-master $october_root_folder
    fi
else
    # Go to vagrant folder
    cd $october_root_folder

    # Install October
    if [ $HHVM_IS_INSTALLED -eq 0 ]; then
        hhvm /usr/local/bin/composer install --prefer-dist
    else
        composer install --prefer-dist
    fi

    # Go to the previous folder
    cd -
fi

if [ $NGINX_IS_INSTALLED -eq 0 ]; then
    nginx_root=$(echo "$october_root_folder" | sed 's/\//\\\//g')

    # Change default vhost created
    sed -i "s/root \/vagrant/root $nginx_root/" /etc/nginx/sites-available/vagrant
    sudo service nginx reload
fi

if [ $APACHE_IS_INSTALLED -eq 0 ]; then
    # Remove apache vhost from default and create a new one
    rm /etc/apache2/sites-enabled/$1.xip.io.conf > /dev/null 2>&1
    rm /etc/apache2/sites-available/$1.xip.io.conf > /dev/null 2>&1
    vhost -s $1.xip.io -d "$october_root_folder"
    sudo service apache2 reload
fi
