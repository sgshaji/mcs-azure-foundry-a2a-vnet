########## Cosmos DB account — agent thread storage
##########

## Create the Cosmos DB account to store agent threads
##
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "aifoundry${random_string.unique.result}cosmosdb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # General settings
  offer_type        = "Standard"
  kind              = "GlobalDocumentDB"
  free_tier_enabled = false

  # Set security-related settings
  local_authentication_disabled = true
  public_network_access_enabled = false

  # Set high availability and failover settings
  automatic_failover_enabled       = false
  multiple_write_locations_enabled = false

  # Configure consistency settings
  consistency_policy {
    consistency_level = "Session"
  }

  # Configure single location with no zone redundancy to reduce costs
  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }
}
