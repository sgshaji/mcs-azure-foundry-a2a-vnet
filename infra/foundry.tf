########## AI Foundry account, GPT model deployment, and soft-delete purge
##########

########## Create AI Foundry resource
##########

## Create the AI Foundry resource
##
resource "azapi_resource" "ai_foundry" {
  depends_on = [
    azurerm_subnet.subnet_agent,
    azapi_resource_action.purge_ai_foundry
  ]

  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = "aifoundry${random_string.unique.result}"
  parent_id                 = azurerm_resource_group.rg.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    kind = "AIServices",
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      # Support both Entra ID and API Key authentication for underlining Cognitive Services account
      disableLocalAuth = false

      # Specifies that this is an AI Foundry resource
      allowProjectManagement = true

      # Set custom subdomain name for DNS names created for this Foundry resource
      customSubDomainName = "aifoundry${random_string.unique.result}"

      # Network-related controls
      # Disable public access but allow Trusted Azure Services exception
      publicNetworkAccess = "Disabled"
      networkAcls = {
        defaultAction = "Allow"
      }

      # Enable VNet injection for Standard Agents
      networkInjections = [
        {
          scenario                   = "agent"
          subnetArmId                = azurerm_subnet.subnet_agent.id
          useMicrosoftManagedNetwork = false
        }
      ]
    }
  }
}

## Create a deployment for OpenAI's GPT-5.1 in the AI Foundry resource
##
resource "azurerm_cognitive_deployment" "aifoundry_deployment_gpt_5_1" {
  depends_on = [
    azapi_resource.ai_foundry
  ]

  name                 = "gpt-5.1"
  cognitive_account_id = azapi_resource.ai_foundry.id

  sku {
    name     = "GlobalStandard"
    capacity = 1
  }

  model {
    format  = "OpenAI"
    name    = "gpt-5.1"
    version = "2025-11-13"
  }
}

## Added AI Foundry account purger to avoid running into InUseSubnetCannotBeDeleted-lock caused by the agent subnet delegation.
## The azapi_resource_action.purge_ai_foundry (only gets executed during destroy) purges the AI foundry account removing /subnets/snet-agent/serviceAssociationLinks/legionservicelink so the agent subnet can get properly removed.
resource "azapi_resource_action" "purge_ai_foundry" {
  method      = "DELETE"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${azurerm_resource_group.rg.location}/resourceGroups/${azurerm_resource_group.rg.name}/deletedAccounts/aifoundry${random_string.unique.result}"
  type        = "Microsoft.CognitiveServices/locations/resourceGroups/deletedAccounts@2021-04-30"
  when        = "destroy"

  depends_on = [time_sleep.purge_ai_foundry_cooldown]
}

resource "time_sleep" "purge_ai_foundry_cooldown" {
  destroy_duration = "900s" # 10-15m is enough time to let the backend remove the /subnets/snet-agent/serviceAssociationLinks/legionservicelink

  depends_on = [azurerm_subnet.subnet_agent]
}
