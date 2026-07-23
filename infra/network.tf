########## Virtual network + subnets (agent-delegated and private-endpoint)
##########

## Create a virtual network for the AI Foundry resource and supporting resources
##
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-agents${random_string.unique.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = [
    var.virtual_network_address_space
  ]
}

## Create two subnets one for the Standard Agent VNet injection and one for the AI Foundry resource
##
resource "azurerm_subnet" "subnet_agent" {
  name                 = "snet-agent"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [
    var.agent_subnet_address_prefix
  ]
  delegation {
    name = "Microsoft.App/environments"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_subnet" "subnet_pe" {
  name                 = "snet-pe"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [
    var.private_endpoint_subnet_address_prefix
  ]
}
