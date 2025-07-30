#!/bin/bash

# Variables
RESOURCE_GROUP="$(openssl rand -hex 4)"
LOCATION="canadacentral"
LOAD_BALANCER_NAME="utility-lb"
BACKEND_POOL_NAME="be"

# Prerequisites: Azure CLI logged in, subscription set, and resource group created.
az_login() {
  az account show -o table
  if ! [ $? -eq 0 ]; then
      echo "Please az login first."
    az login --use-device-code
    if [[ $? -ne 0 ]]; then
      echo "az login failed. Quitting"
      exit 1
    fi
  else
      # Prompt user to confirm if the correct sub is selected
      echo "Is the above correct subscription? Press Ctrl-C to cancel" && read DUMMY_INPUT
  fi
}

az_login
# Create resource group
az group create -n $RESOURCE_GROUP -l $LOCATION

# Deploy VMs
az deployment group create -g "$RESOURCE_GROUP" -f azuredeploy.json -p azuredeploy.parameters.json
# Create the load balancer
az network lb create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$LOAD_BALANCER_NAME" \
  --sku Standard \
  --backend-pool-name "$BACKEND_POOL_NAME"

# Get all NICs in the resource group
NIC_IDS=$(az network nic list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].id" \
  --output tsv)

# Add each NIC to the load balancer's backend pool
for NIC_ID in $NIC_IDS; do
  az network nic ip-config address-pool add \
    --address-pool "$BACKEND_POOL_NAME" \
    --lb-name "$LOAD_BALANCER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --nic-name $(basename "$NIC_ID") \
    --ip-config-name "ipconfig1"
done

# Create an outbound rule for the backend pool to use the public IP
OUTBOUND_RULE_NAME="utility-lb-outbound-rule"
az network lb outbound-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --lb-name "$LOAD_BALANCER_NAME" \
  --name "$OUTBOUND_RULE_NAME" \
  --frontend-ip-configs LoadBalancerFrontEnd \
  --address-pool "$BACKEND_POOL_NAME" \
  --protocol All \
  --idle-timeout 4

echo "Load balancer '$LOAD_BALANCER_NAME' created, NICs added to backend pool '$BACKEND_POOL_NAME', and outbound rule '$OUTBOUND_RULE_NAME' configured."

