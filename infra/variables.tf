## As of 6/2025 this is limited to RFC1918 Class B and Class C address space
variable "virtual_network_address_space" {
  description = "The address space for the virtual network"
  type        = string
  default     = "192.168.0.0/16"
}

variable "agent_subnet_address_prefix" {
  description = "The address prefix for the subnet that will be delegated to the Standard Agent"
  type        = string
  default     = "192.168.0.0/24"
}

variable "private_endpoint_subnet_address_prefix" {
  description = "The address prefix for the subnet that contains the private endpoints"
  type        = string
  default     = "192.168.1.0/24"
}

variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}


########## A2A wrapper (Container Apps facade)
##########

variable "aca_subnet_address_prefix" {
  description = "Address prefix for the Container Apps environment subnet (Consumption env requires at least /23)"
  type        = string
  default     = "192.168.2.0/23"
}

variable "wrapper_image" {
  description = "Container image for the A2A wrapper. Defaults to a public placeholder for the first apply; set to the ACR image after building."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "wrapper_auth_enabled" {
  description = "Enable inbound Entra OAuth validation on the wrapper's A2A endpoint. Start false to smoke-test, then set true after the app registration exists."
  type        = bool
  default     = true
}

variable "wrapper_entra_audience" {
  description = "Expected 'aud' of inbound Entra tokens = the wrapper API app registration's Application ID URI or client id."
  type        = string
  default     = ""
}

variable "wrapper_required_scope" {
  description = "Optional scope/role the caller must present (e.g. A2A.Invoke). Leave empty to accept any valid token for the audience."
  type        = string
  default     = ""
}

variable "wrapper_agent_instructions" {
  description = "System instructions for the Foundry agent that the wrapper provisions on startup."
  type        = string
  default     = "You are a helpful assistant hosted in Azure AI Foundry and reached from Copilot Studio over the A2A protocol. Answer clearly and concisely."
}

variable "wrapper_foundry_role" {
  description = "Foundry RBAC role granted to the wrapper identity so it can create and invoke agents. If 'Azure AI User' fails to resolve (post-rename), use 'Foundry User'."
  type        = string
  default     = "Azure AI User"
}
