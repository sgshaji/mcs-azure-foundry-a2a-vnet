########## Storage account for agent data
##########

########## Create resoures required to store agent data
##########

## Create a storage account for agent data
##
resource "azurerm_storage_account" "storage_account" {
  name                = "aifoundry${random_string.unique.result}storage"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  ## Identity configuration
  shared_access_key_enabled = false

  ## Network access configuration
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  network_rules {
    default_action = "Deny"
    bypass = [
      "AzureServices"
    ]
  }
}
