#!/bin/bash
clear

# -----------------------------------------------------------------------------

source config.sh

# -----------------------------------------------------------------------------
# Variables

INSTALL_PATH=${PWD}

TIMESTAMP=$(date +'%Y%m%d%H%M%S')

PROJECT_FOLDER=$(basename ${PROJECT_PATH})

DATABASE=$(mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}'" | head -2 | tail -1)

SERVER_NAME=${MAGENTO_BASE_URL##http*://}

APACHE_CONF="${SERVER_NAME}.conf"

# -----------------------------------------------------------------------------
# Host Setup

sudo sh -c "echo '127.0.0.1    ${SERVER_NAME}' >> /etc/hosts"

sudo sh -c "echo '<VirtualHost *:80>\n    ServerName ${SERVER_NAME}\n    DocumentRoot ${PROJECT_PATH}\n</VirtualHost>' > /etc/apache2/sites-available/${APACHE_CONF}"
sudo a2ensite -q ${APACHE_CONF}
sudo service apache2 restart

# -----------------------------------------------------------------------------
# Folders Setup

if [ -d "${PROJECT_PATH}" ]; then
    mv "${PROJECT_PATH}" "${PROJECT_PATH}_${TIMESTAMP}"
fi

if [ ! -d "${PROJECT_PATH}" ]; then
    mkdir -p "${PROJECT_PATH}"
fi

# -----------------------------------------------------------------------------
# Database Setup

if [ ! -z ${DATABASE} ]; then
    mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e \
        "CREATE DATABASE \`${MYSQL_DATABASE}_${TIMESTAMP}\`;"

    mysqldump -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} | mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE}_${TIMESTAMP}
fi

mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e \
    "DROP DATABASE IF EXISTS \`${MYSQL_DATABASE}\`; CREATE DATABASE \`${MYSQL_DATABASE}\`;"

# -----------------------------------------------------------------------------
# Magento Setup

cd "${PROJECT_PATH}"

COMPOSER_AUTH="{\"http-basic\": {\"repo.magento.com\": {\"username\": \"${MAGENTO_PUBLIC_KEY}\", \"password\": \"${MAGENTO_PRIVATE_KEY}\"}}}"
composer config -g http-basic.repo.magento.com ${MAGENTO_PUBLIC_KEY} ${MAGENTO_PRIVATE_KEY}

if [ -z $1 ]; then
    composer create-project --repository=https://repo.magento.com/ magento/project-${MAGENTO_EDITION}-edition .
else
    composer create-project --repository=https://repo.magento.com/ magento/project-${MAGENTO_EDITION}-edition="$1" .
fi

echo ${COMPOSER_AUTH} > auth.json

php bin/magento setup:install \
    --db-host="${MYSQL_HOST}" \
    --db-name="${MYSQL_DATABASE}" \
    --db-user="${MYSQL_USERNAME}" \
    --db-password="${MYSQL_PASSWORD}" \
    --base-url="${MAGENTO_BASE_URL}" \
    --backend-frontname="${MAGENTO_BACKEND_FRONTNAME}" \
    --admin-user="${MAGENTO_ADMIN_USER}" \
    --admin-password="${MAGENTO_ADMIN_PASSWORD}" \
    --admin-firstname="${MAGENTO_ADMIN_FIRSTNAME}" \
    --admin-lastname="${MAGENTO_ADMIN_LASTNAME}" \
    --admin-email="${MAGENTO_ADMIN_EMAIL}" \
    --language="${MAGENTO_LANGUAGE}" \
    --currency="${MAGENTO_CURRENCY}" \
    --timezone="${MAGENTO_TIMEZONE}" \
    --use-rewrites=1

# -----------------------------------------------------------------------------
# Set Developer Mode

php bin/magento deploy:mode:set developer

# -----------------------------------------------------------------------------
# Disable Some Cache Types

php bin/magento cache:disable layout block_html full_page translate

# -----------------------------------------------------------------------------
# Set Session Lifetime

php bin/magento config:set admin/security/session_lifetime 604800

# -----------------------------------------------------------------------------
# Disable Sign Static Files

php bin/magento config:set dev/static/sign 0

# -----------------------------------------------------------------------------
# Allow Symlinks

php bin/magento config:set dev/template/allow_symlink 1

# -----------------------------------------------------------------------------
# Disable WYSIWYG Editor by Default

php bin/magento config:set cms/wysiwyg/enabled hidden

# -----------------------------------------------------------------------------
# Set Admin Startup Page

php bin/magento config:set admin/startup/menu_item_id Magento_Config::system_config

# -----------------------------------------------------------------------------
# Grunt Setup

cd "${PROJECT_PATH}"

mv Gruntfile.js.sample      Gruntfile.js
mv grunt-config.json.sample grunt-config.json
mv package.json.sample      package.json

cp "${INSTALL_PATH}/src/magento/dev/tools/grunt/configs/local-themes.js" "${PROJECT_PATH}/dev/tools/grunt/configs/local-themes.js"

npm install

# -----------------------------------------------------------------------------
# The End - Miscellaneous Commands
