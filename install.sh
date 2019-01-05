#!/bin/bash
clear

# -----------------------------------------------------------------------------

source config.sh

# -----------------------------------------------------------------------------

./00-install.sh $1

# call 10-install-__________-module-__________
# call 11-install-__________-theme-__________
# call 12-install-__________-languagepack-__________

# call 20-install-__________-module-__________
# call 21-install-__________-theme-__________
# call 22-install-__________-languagepack-__________

# -----------------------------------------------------------------------------

cd ${PROJECT_PATH}

./deploy

xdg-open "${MAGENTO_BASE_URL}"
xdg-open "${MAGENTO_BASE_URL}/${MAGENTO_BACKEND_FRONTNAME}"
