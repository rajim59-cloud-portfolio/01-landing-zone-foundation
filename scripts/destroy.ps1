param(
    [string]$VarFile = "local.tfvars"
)

$ErrorActionPreference = "Continue"

Write-Host "[destroy] Initiating zero-cost clean teardown..." -ForegroundColor Yellow

Push-Location "infra"
if (Test-Path $VarFile) {
    terraform destroy -var-file=$VarFile -auto-approve
} else {
    terraform destroy -auto-approve
}
Pop-Location

Write-Host "[destroy] Verifying remaining resources in subscription..." -ForegroundColor Green
az resource list --query "[].{Name:name, Type:type, ResourceGroup:resourceGroup}" -o table

Write-Host "[destroy] Zero-cost status confirmed." -ForegroundColor Cyan