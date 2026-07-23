# `a2a-wrapper/` — A2A façade for the private Foundry agent

A lightweight [A2A protocol](https://a2a-protocol.org/) server (Python / Starlette on the
official `a2a-sdk`) that sits in front of a network-isolated Azure AI Foundry agent. It presents
a public HTTPS surface that external A2A clients (e.g. Microsoft Copilot Studio) can reach, while
calling Foundry only over the virtual network using a managed identity.

## Endpoints

| Method & path | Auth | Purpose |
|---|---|---|
| `GET /.well-known/agent.json` | public | Agent card (A2A discovery) |
| `GET /.well-known/agent-card.json` | public | Agent card alias (newer A2A spec / Copilot Studio) |
| `GET /` | public | Agent card (some clients probe the root) |
| `GET /health` | public | Liveness probe |
| `POST /` | **protected** | A2A JSON-RPC endpoint (Entra OAuth when `AUTH_ENABLED=true`) |

On a request, `agent_executor.py` hands the task to `foundry_client.py`, which lazily creates (or
reuses) an agent in the Foundry project and invokes it, then returns the reply as an A2A message.

## Configuration (environment variables)

All values are injected by the Container App (see `infra/wrapper.tf`); nothing is hard-coded.

| Variable | Purpose |
|---|---|
| `PROJECT_ENDPOINT` | Foundry project endpoint the wrapper calls |
| `MODEL_DEPLOYMENT` | Model deployment name (default `gpt-5.1`) |
| `AGENT_NAME` / `AGENT_INSTRUCTIONS` | Name + system prompt of the agent the wrapper provisions |
| `PUBLIC_BASE_URL` | The wrapper's externally reachable base URL (used in the agent card) |
| `AZURE_CLIENT_ID` | Tells `DefaultAzureCredential` which user-assigned identity to use |
| `AUTH_ENABLED` | Enforce inbound Entra OAuth on `POST /` (`true`/`false`) |
| `ENTRA_TENANT_ID` / `ENTRA_AUDIENCE` / `ENTRA_REQUIRED_SCOPE` | Inbound token validation (issuer, audience, optional scope/role) |

## Build & deploy

The image is built in Azure Container Registry (no local Docker needed) and rolled out via
Terraform (`wrapper_image`):

```bash
az acr build --registry <acr-name> --image a2a-wrapper:v1 .
# then set wrapper_image in infra/terraform.tfvars and `terraform apply`
```

The `Dockerfile` runs an import smoke-test (`python -c "import app.main"`) at build time, so a
broken import or dependency fails the **build** instead of crash-looping at runtime.

## Dependency pinning

`a2a-sdk` and `azure-ai-projects` are pinned to major-compatible ranges (`a2a-sdk >=0.2.5,<0.3`,
`azure-ai-projects >=1.0.0,<2.0.0`) — later majors reorganized their module/API surface and break
this app's imports. Update deliberately, not by floating to `latest`.

## Local development

```bash
python -m venv .venv && . .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
export PROJECT_ENDPOINT="https://<account>.services.ai.azure.com/api/projects/<project>"
export AUTH_ENABLED=false
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

Reaching a *private* Foundry endpoint from your workstation requires network line-of-sight to the
VNet (VPN/Bastion/jumpbox); otherwise run inside the deployed Container App.
