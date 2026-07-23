########## Azure AI Search — vector store
##########

## Create an AI Search instance that will be used to store vector embeddings
##
resource "azapi_resource" "ai_search" {
  type                      = "Microsoft.Search/searchServices@2025-05-01"
  name                      = "aifoundry${random_string.unique.result}search"
  parent_id                 = azurerm_resource_group.rg.id
  location                  = var.location
  schema_validation_enabled = true

  body = {
    sku = {
      name = "standard"
    }

    identity = {
      type = "SystemAssigned"
    }

    properties = {

      # Search-specific properties
      replicaCount   = 1
      partitionCount = 1
      hostingMode    = "Default"
      semanticSearch = "disabled"

      # Identity-related controls
      disableLocalAuth = false
      authOptions = {
        aadOrApiKey = {
          aadAuthFailureMode = "http401WithBearerChallenge"
        }
      }
      # Networking-related controls
      publicNetworkAccess = "Disabled"
      networkRuleSet = {
        bypass = "None"
      }
    }
  }
}
