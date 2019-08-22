#!/bin/bash
clear

# -----------------------------------------------------------------------------

source config.sh

# -----------------------------------------------------------------------------

./00-install.sh $1

# ./10-install-__________-module-__________
# ./11-install-__________-theme-__________
# ./12-install-__________-languagepack-__________

# ./20-install-__________-module-__________
# ./21-install-__________-theme-__________
# ./22-install-__________-languagepack-__________

# -----------------------------------------------------------------------------

cd ${PROJECT_PATH}

xdg-open "${MAGENTO_BASE_URL}"
xdg-open "${MAGENTO_BASE_URL}/${MAGENTO_BACKEND_FRONTNAME}"
