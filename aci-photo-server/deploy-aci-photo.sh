#!/bin/bash
# Pass in source media file folder as the first script argument.
# Support Azure blob storage SAS

# Prompt user for input and store it in a variable
# STORAGE_KEY value shouldn't contain any sed special characters esp. '/'
read -p "Enter the Azure File Share name: " FILE_SHARE
read -p "Enter Storage account name: " STORAGE_ACCOUNT
read -p "Enter Storage account key: " STORAGE_KEY

# Generate SAS token and construct file share URL with SAS
expiry_date=$(date -u -d "1 day" '+%Y-%m-%dT%H:%M:%SZ')
sas_token=$(az storage share generate-sas --account-name $STORAGE_ACCOUNT --name $FILE_SHARE \
    --permissions rwl --expiry $expiry_date --https-only --output tsv)

# Construct file share URL
file_share_url="https://$STORAGE_ACCOUNT.file.core.windows.net/$FILE_SHARE?$sas_token"
# Copy directory to Azure File Share
azcopy copy $1 $file_share_url --recursive=true

sed "s/{file_share}/$FILE_SHARE/g" aci-photo.yaml > /tmp/aci-photo-filled.yaml
sed -i "s/{storage_account}/$STORAGE_ACCOUNT/g" /tmp/aci-photo-filled.yaml
sed -i "s/{storage_key}/$STORAGE_KEY/g" /tmp/aci-photo-filled.yaml
az container create -g rg-eastasia --file /tmp/aci-photo-filled.yaml
