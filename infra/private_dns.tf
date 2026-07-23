########## Private DNS zones and VNet links
##########

########## Create Private DNS Zones, Links, and Private Endpoints
##########

## Create required Private DNS Zones
##
resource "azurerm_private_dns_zone" "plz_cosmos_db" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "plz_ai_search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "plz_storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "plz_cognitive_services" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "plz_ai_services" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "plz_openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

## Create Private DNS Zone Links to link the Private DNS Zones to the virtual network
##
resource "azurerm_private_dns_zone_virtual_network_link" "plz_cosmos_db_link" {
  depends_on = [
    azurerm_private_dns_zone.plz_cosmos_db,
    azurerm_virtual_network.vnet
  ]
  name                  = "cosmosdb-${random_string.unique.result}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.plz_cosmos_db.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "plz_ai_search_link" {
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.plz_cosmos_db_link,
    azurerm_private_dns_zone.plz_ai_search,
    azurerm_virtual_network.vnet
  ]

  name                  = "aisearch-${random_string.unique.result}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.plz_ai_search.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "plz_storage_blob_link" {
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.plz_ai_search_link,
    azurerm_private_dns_zone.plz_storage_blob,
    azurerm_virtual_network.vnet
  ]
  name                  = "storage-${random_string.unique.result}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.plz_storage_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "plz_cognitive_services_link" {
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.plz_storage_blob_link,
    azurerm_private_dns_zone.plz_cognitive_services,
    azurerm_virtual_network.vnet
  ]
  name                  = "cogsvc-${random_string.unique.result}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.plz_cognitive_services.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "plz_ai_services_link" {
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.plz_cognitive_services_link,
    azurerm_private_dns_zone.plz_ai_services,
    azurerm_virtual_network.vnet
  ]
  name                  = "aiservices-${random_string.unique.result}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.plz_ai_services.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "plz_openai_link" {
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.plz_ai_services_link,
    azurerm_private_dns_zone.plz_openai,
    azurerm_virtual_network.vnet
  ]
  name                  = "openai-${random_string.unique.result}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.plz_openai.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}
