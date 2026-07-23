# `infra/` — Terraform

Provisions the network-isolated Azure AI Foundry Standard Agent and the Container Apps hosting
for the A2A wrapper. This is a single root module using a **local** state backend by default.

## File map

| File | Contents |
|---|---|
| `main.tf` | Random suffix + resource group |
| `network.tf` | Virtual network and subnets (agent-delegated, private-endpoint, Container Apps) |
| `storage.tf`, `cosmos.tf`, `search.tf` | Agent data stores (all private, local-auth disabled) |
| `foundry.tf` | Foundry account, `gpt-5.1` deployment, soft-delete purge on destroy |
| `foundry_project.tf` | Project, service connections, capability host |
| `private_dns.tf`, `private_endpoints.tf` | Private DNS zones/links and private endpoints |
| `monitor.tf` | Log Analytics, Application Insights, AMPLS (private tracing) |
| `rbac.tf` | Role assignments + RBAC propagation waits |
| `wrapper.tf` | ACR, user-assigned identity, Container Apps environment + the wrapper app |
| `variables.tf` | All input variables (base + wrapper) |
| `outputs.tf` | Wrapper URLs, ACR name, project endpoint, wrapper identity client id |
| `data.tf`, `locals.tf`, `providers.tf`, `versions.tf` | Supporting configuration |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars     # set `location`, size CIDRs
export ARM_SUBSCRIPTION_ID="<subscription-id>"   # PowerShell: $env:ARM_SUBSCRIPTION_ID="..."
terraform init
terraform apply
```

See the [root README](../README.md) for the full quick-start (including building the wrapper
image and wiring Copilot Studio) and the variable reference.

## Remote state (recommended for teams)

State is local by default. To store it in Azure Storage, uncomment the backend block in
`versions.tf` and run `terraform init -migrate-state`:

```hcl
# versions.tf
backend "azurerm" {
  resource_group_name  = "..."
  storage_account_name = "..."
  container_name       = "tfstate"
  key                  = "foundry-a2a.tfstate"
}
```

## Conventions

- **`.tf` files are CRLF.** The Storage Blob Data Owner ABAC `condition` is a line-ending-sensitive
  heredoc that is stored as CRLF in state. `terraform fmt` rewrites files as LF — if you run it,
  re-normalize `.tf` back to CRLF, or a `terraform apply` will show a spurious replacement of that
  one role assignment (functionally identical, but avoidable).
- **`.terraform.lock.hcl` is committed** to pin provider versions; `terraform.tfstate*`,
  `*.tfvars`, and saved plans are git-ignored.
