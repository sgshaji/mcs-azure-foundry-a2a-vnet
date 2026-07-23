########## Foundation — unique suffix + resource group
##########

## Create a random string
##
resource "random_string" "unique" {
  length      = 4
  min_numeric = 4
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

## Create a resource group for the resources to be stored in
##
resource "azurerm_resource_group" "rg" {
  name     = "rg-aifoundry${random_string.unique.result}"
  location = var.location
}
