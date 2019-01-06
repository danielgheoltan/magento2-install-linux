#!/bin/bash
clear

# -----------------------------------------------------------------------------

source config.sh

# -----------------------------------------------------------------------------
# Variables

INSTALL_PATH=$(PWD)

TIMESTAMP=$(date +'%Y%m%d%H%M%S')

PROJECT_FOLDER=$(basename ${PROJECT_PATH})

DATABASE=$(mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}'" | head -2 | tail -1)

# -----------------------------------------------------------------------------
# Folders Setup

if [ -d "${PROJECT_PATH}" ]; then
    mv "${PROJECT_PATH}" "${PROJECT_PATH}_${TIMESTAMP}"
fi

if [ ! -d "${PROJECT_PATH}" ]; then
    mkdir "${PROJECT_PATH}"
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

COMPOSER_AUTH={"http-basic": {"repo.magento.com": {"username": "${MAGENTO_PUBLIC_KEY}", "password": "${MAGENTO_PRIVATE_KEY}"}}}

if [ -z $1 ]; then
    composer create-project --repository=https://repo.magento.com/ magento/project-community-edition .
else
    composer create-project --repository=https://repo.magento.com/ magento/project-community-edition="$1" .
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

mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e \
    "USE ${MYSQL_DATABASE}; INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/security/session_lifetime', 604800) ON DUPLICATE KEY UPDATE value = 604800;"

# -----------------------------------------------------------------------------
# Disable Sign Static Files

mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e \
    "USE ${MYSQL_DATABASE}; INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'dev/static/sign', 0) ON DUPLICATE KEY UPDATE value = 0;"

# -----------------------------------------------------------------------------
# Allow Symlinks

mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e \
    "USE ${MYSQL_DATABASE}; INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'dev/template/allow_symlink', 1) ON DUPLICATE KEY UPDATE value = 1;"

# -----------------------------------------------------------------------------
# Disable WYSIWYG Editor by Default

mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e \
    "USE ${MYSQL_DATABASE}; INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'cms/wysiwyg/enabled', 'hidden') ON DUPLICATE KEY UPDATE value = 'hidden';"

# -----------------------------------------------------------------------------
# Set Admin Startup Page

mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e \
    "USE ${MYSQL_DATABASE}; INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'admin/startup/menu_item_id', 'Magento_Config::system_config') ON DUPLICATE KEY UPDATE value = 'Magento_Config::system_config';"

# -----------------------------------------------------------------------------
# Grunt Setup

cd "${PROJECT_PATH}"

mv Gruntfile.js.sample      Gruntfile.js
mv grunt-config.json.sample grunt-config.json
mv package.json.sample      package.json

cp "${INSTALL_PATH}/src/magento/dev/tools/grunt/configs/local-themes.js" "${PROJECT_PATH}/dev/tools/grunt/configs/local-themes.js"

npm install

# -----------------------------------------------------------------------------
# Copy Shell Files

cp "${INSTALL_PATH}/src/magento/deploy"             "${PROJECT_PATH}/deploy"
cp "${INSTALL_PATH}/src/magento/deploy-backend"     "${PROJECT_PATH}/deploy-backend"
cp "${INSTALL_PATH}/src/magento/deploy-frontend"    "${PROJECT_PATH}/deploy-frontend"
cp "${INSTALL_PATH}/src/magento/deploy-theme"       "${PROJECT_PATH}/deploy-theme"
cp "${INSTALL_PATH}/src/magento/deploy-theme-blank" "${PROJECT_PATH}/deploy-theme-blank"
cp "${INSTALL_PATH}/src/magento/deploy-theme-luma"  "${PROJECT_PATH}/deploy-theme-luma"
cp "${INSTALL_PATH}/src/magento/di"                 "${PROJECT_PATH}/di"
cp "${INSTALL_PATH}/src/magento/grunt-theme"        "${PROJECT_PATH}/grunt-theme"
cp "${INSTALL_PATH}/src/magento/grunt-theme-blank"  "${PROJECT_PATH}/grunt-theme-blank"
cp "${INSTALL_PATH}/src/magento/grunt-theme-luma"   "${PROJECT_PATH}/grunt-theme-luma"

# -----------------------------------------------------------------------------
# The End - Miscellaneous Commands
