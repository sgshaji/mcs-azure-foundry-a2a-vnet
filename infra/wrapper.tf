############################################################
# A2A Wrapper — Container Apps façade in front of the private Foundry agent
#
# Topology: Copilot Studio --(public HTTPS, OAuth)--> Container App
#           --(VNet-integrated egress)--> Foundry private endpoint
#
# Public ingress so Copilot Studio can reach it; egress rides the VNet so the
# wrapper can call the private Foundry endpoint. A user-assigned managed identity
# creates and invokes the agent.
############################################################

########## Variables ##########

########## Networking: dedicated subnet for the Container Apps environment ##########
resource "azurerm_subnet" "subnet_aca" {
  name                 = "snet-aca"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aca_subnet_address_prefix]

  delegation {
    name = "Microsoft.App/environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

########## Identity used by the wrapper to reach ACR and Foundry ##########
resource "azurerm_user_assigned_identity" "a2a_wrapper" {
  name                = "id-a2a-wrapper-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

########## Container registry for the wrapper image ##########
resource "azurerm_container_registry" "acr" {
  name                = "acraifoundry${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "wrapper_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.a2a_wrapper.principal_id
}

## Grant the wrapper identity a Foundry role on the account so it can create/invoke agents.
resource "azurerm_role_assignment" "wrapper_foundry_user" {
  scope                = azapi_resource.ai_foundry.id
  role_definition_name = var.wrapper_foundry_role
  principal_id         = azurerm_user_assigned_identity.a2a_wrapper.principal_id
}

########## Container Apps environment (VNet-injected, public ingress) ##########
resource "azurerm_container_app_environment" "aca_env" {
  name                           = "cae-a2a-${random_string.unique.result}"
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = var.location
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.loganalytics.id
  infrastructure_subnet_id       = azurerm_subnet.subnet_aca.id
  internal_load_balancer_enabled = false
}

########## The wrapper Container App ##########
resource "azurerm_container_app" "wrapper" {
  name                         = "a2a-wrapper-${random_string.unique.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.a2a_wrapper.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.a2a_wrapper.id
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "a2a-wrapper"
      image  = var.wrapper_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PROJECT_ENDPOINT"
        value = "https://${azapi_resource.ai_foundry.name}.services.ai.azure.com/api/projects/${azapi_resource.ai_foundry_project.name}"
      }
      env {
        name  = "MODEL_DEPLOYMENT"
        value = "gpt-5.1"
      }
      env {
        name  = "AGENT_NAME"
        value = "cs-a2a-agent"
      }
      env {
        name  = "AGENT_INSTRUCTIONS"
        value = var.wrapper_agent_instructions
      }
      # Tells DefaultAzureCredential which user-assigned identity to use.
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.a2a_wrapper.client_id
      }
      env {
        name  = "PUBLIC_BASE_URL"
        value = "https://a2a-wrapper-${random_string.unique.result}.${azurerm_container_app_environment.aca_env.default_domain}"
      }
      env {
        name  = "AUTH_ENABLED"
        value = tostring(var.wrapper_auth_enabled)
      }
      env {
        name  = "ENTRA_TENANT_ID"
        value = data.azurerm_client_config.current.tenant_id
      }
      env {
        name  = "ENTRA_AUDIENCE"
        value = var.wrapper_entra_audience
      }
      env {
        name  = "ENTRA_REQUIRED_SCOPE"
        value = var.wrapper_required_scope
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.wrapper_acr_pull
  ]
}
