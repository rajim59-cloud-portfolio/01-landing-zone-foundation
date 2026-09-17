#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────
LOCATION="${LOCATION:-malaysiawest}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-tfstate}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-sttfstaterajim01}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"

# ─── Colors for readability ───────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[bootstrap]${NC} $1"; }
warn() { echo -e "${YELLOW}[warn]${NC} $1"; }

# ─── Pre-flight checks ────────────────────────────────────────────
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI not found. Install: https://aka.ms/installazurecli"
  exit 1
fi

if ! az account show &> /dev/null; then
  echo "❌ Not logged in. Run: az login"
  exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
log "Using subscription: $SUBSCRIPTION_ID"

# ─── Resource Group ───────────────────────────────────────────────
log "Creating resource group: $RESOURCE_GROUP in $LOCATION"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags "Purpose=TerraformState" "Env=shared" "Owner=rajim" "CostCenter=portfolio-01" \
  --output none

# ─── Storage Account ──────────────────────────────────────────────
log "Creating storage account: $STORAGE_ACCOUNT"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags "Purpose=TerraformState" "Env=shared" "Owner=rajim" "CostCenter=portfolio-01" \
  --output none

# ─── Blob Container ───────────────────────────────────────────────
log "Creating blob container: $CONTAINER_NAME"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --output none

# ─── Enable versioning (state recovery) ───────────────────────────
log "Enabling blob versioning for state recovery"
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --output none

# ─── Summary ──────────────────────────────────────────────────────
echo ""
log "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. cd infra"
echo "  2. terraform init"
echo "  3. terraform plan"
echo ""
echo "Backend config (already set in infra/backend.tf):"
echo "  resource_group_name  = \"$RESOURCE_GROUP\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  container_name       = \"$CONTAINER_NAME\""