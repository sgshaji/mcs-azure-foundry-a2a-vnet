########## Private endpoints for the network-isolated services
##########

## Create Private Endpoints for resources
##
resource "azurerm_private_endpoint" "pe_storage" {
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.plz_ai_search_link,
    azurerm_private_dns_zone_virtual_network_link.plz_storage_blob_link,
    azurerm_private_dns_zone_virtual_network_link.plz_cognitive_services_link,
    azurerm_private_dns_zone_virtual_network_link.plz_ai_services_link,
    azurerm_private_dns_zone_virtual_network_link.plz_openai_link,
    azurerm_private_dns_zone_virtual_network_link.plz_cosmos_db_link,
    azurerm_storage_account.storage_account,
    azurerm_virtual_network.vnet
  ]

  name                = "${azurerm_storage_account.storage_account.name}-private-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_pe.id

  private_service_connection {
    name                           = "${azurerm_storage_account.storage_account.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    subresource_names = [
      "blob"
    ]
    is_manual_connection = false
  }

  private_dns_zone_group {
    name = "${azurerm_storage_account.storage_account.name}-dns-config"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.plz_storage_blob.id
    ]
  }
}

resource "azurerm_private_endpoint" "pe_cosmosdb" {
  depends_on = [
    azurerm_private_endpoint.pe_storage,
    azurerm_cosmosdb_account.cosmosdb,
    azurerm_virtual_network.vnet
  ]

  name                = "${azurerm_cosmosdb_account.cosmosdb.name}-private-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_pe.id

  private_service_connection {
    name                           = "${azurerm_cosmosdb_account.cosmosdb.name}-private-link-service-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmosdb.id
    subresource_names = [
      "Sql"
    ]
    is_manual_connection = false
  }

  private_dns_zone_group {
    name = "${azurerm_cosmosdb_account.cosmosdb.name}-dns-config"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.plz_cosmos_db.id
    ]
  }
}

resource "azurerm_private_endpoint" "pe_aisearch" {
  depends_on = [
    azurerm_private_endpoint.pe_cosmosdb,
    azapi_resource.ai_search,
    azurerm_virtual_network.vnet
  ]

  name                = "${azapi_resource.ai_search.name}-private-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_pe.id

  private_service_connection {
    name                           = "${azapi_resource.ai_search.name}-private-link-service-connection"
    private_connection_resource_id = azapi_resource.ai_search.id
    subresource_names = [
      "searchService"
    ]
    is_manual_connection = false
  }

  private_dns_zone_group {
    name = "${azapi_resource.ai_search.name}-dns-config"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.plz_ai_search.id
    ]
  }
}

resource "azurerm_private_endpoint" "pe_aifoundry" {
  depends_on = [
    azurerm_private_endpoint.pe_aisearch,
    azapi_resource.ai_foundry,
    azurerm_virtual_network.vnet
  ]

  name                = "${azapi_resource.ai_foundry.name}-private-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_pe.id

  private_service_connection {
    name                           = "${azapi_resource.ai_foundry.name}-private-link-service-connection"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names = [
      "account"
    ]
    is_manual_connection = false
  }

  private_dns_zone_group {
    name = "${azapi_resource.ai_foundry.name}-dns-config"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.plz_cognitive_services.id,
      azurerm_private_dns_zone.plz_ai_services.id,
      azurerm_private_dns_zone.plz_openai.id
    ]
  }
}
