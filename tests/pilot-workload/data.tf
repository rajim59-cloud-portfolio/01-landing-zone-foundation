# Read landing zone outputs from remote state
data "terraform_remote_state" "landing_zone" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstaterajim01"
    container_name       = "tfstate"
    key                  = "landing-zone.tfstate"
  }
}