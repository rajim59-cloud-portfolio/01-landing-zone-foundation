param(
    [string]$TfVars = "infra\local.tfvars"
)

$ErrorActionPreference = "Stop"
$RequiredTags = @("CostCenter", "Env", "Owner", "Project")

if (-not (Test-Path $TfVars)) {
    Write-Host "[warn] $TfVars not found. Checking terraform.tfvars instead..." -ForegroundColor Yellow
    $TfVars = "infra\terraform.tfvars"
    if (-not (Test-Path $TfVars)) {
        Write-Error "Neither local.tfvars nor terraform.tfvars exists."
        exit 1
    }
}

$content = Get-Content $TfVars -Raw
$varContent = ""
if (Test-Path "infra\variables.tf") {
    $varContent = Get-Content "infra\variables.tf" -Raw
}

Write-Host "[validate] Checking configuration in $TfVars..." -ForegroundColor Green

foreach ($tag in $RequiredTags) {
    if ($content -match $tag) {
        Write-Host "  [+] Mandatory Tag '$tag' verified" -ForegroundColor Green
    } else {
        Write-Error "Missing mandatory tag: $tag"
        exit 1
    }
}

# Check location in tfvars or default in variables.tf
if (($content -match 'malaysiawest' -or $content -match 'southeastasia') -or 
    ($varContent -match 'malaysiawest' -or $varContent -match 'southeastasia')) {
    Write-Host "  [+] Location policy alignment verified (malaysiawest/southeastasia)" -ForegroundColor Green
} else {
    Write-Error "Location must be either 'malaysiawest' or 'southeastasia'"
    exit 1
}

Write-Host "[validate] All pre-deployment governance checks passed!" -ForegroundColor Cyan
