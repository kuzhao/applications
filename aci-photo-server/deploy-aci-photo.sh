#!/bin/bash
set -x
# Pass in source media file folder as the first script argument.
# Support Azure blob storage SAS

# Prompt user for input and store it in a variable
# STORAGE_KEY value shouldn't contain any sed special characters esp. '/'
read -p "Enter the Azure File Share name: " FILE_SHARE
read -p "Enter Storage account name: " STORAGE_ACCOUNT
read -p "Enter Storage account key: " STORAGE_KEY

export AZCOPY_ACCOUNT_KEY=$STORAGE_KEY
# Construct file share URL for account key authentication
file_share_url="https://$STORAGE_ACCOUNT.file.core.windows.net/$FILE_SHARE"
# Copy directory to Azure File Share using account key authentication
azcopy copy $1 $file_share_url --recursive

sed "s/{file_share}/$FILE_SHARE/g" aci-photo.yaml > /tmp/aci-photo-filled.yaml
sed -i "s/{storage_account}/$STORAGE_ACCOUNT/g" /tmp/aci-photo-filled.yaml
sed -i "s|{storage_key}|$(printf '%s' "$STORAGE_KEY" | sed 's/[&|]/\\&/g')|g" /tmp/aci-photo-filled.yaml
#az container create -g rg-canadacentral --file /tmp/aci-photo-filled.yaml
