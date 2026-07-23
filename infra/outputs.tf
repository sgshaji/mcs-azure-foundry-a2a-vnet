########## Outputs
##########

########## Outputs ##########
output "a2a_wrapper_url" {
  description = "Public base URL of the A2A wrapper."
  value       = "https://${azurerm_container_app.wrapper.ingress[0].fqdn}"
}

output "a2a_agent_card_url" {
  description = "Agent card URL Copilot Studio will discover."
  value       = "https://${azurerm_container_app.wrapper.ingress[0].fqdn}/.well-known/agent.json"
}

output "a2a_acr_name" {
  description = "Container registry name (use with 'az acr build')."
  value       = azurerm_container_registry.acr.name
}

output "a2a_acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "a2a_wrapper_identity_client_id" {
  description = "Client ID of the wrapper's managed identity."
  value       = azurerm_user_assigned_identity.a2a_wrapper.client_id
}

output "a2a_project_endpoint" {
  description = "Foundry project endpoint the wrapper calls."
  value       = "https://${azapi_resource.ai_foundry.name}.services.ai.azure.com/api/projects/${azapi_resource.ai_foundry_project.name}"
}
