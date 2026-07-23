"""Runtime configuration for the A2A wrapper, sourced from environment variables.

All Foundry/identity settings are injected by the Container App (see Terraform).
Nothing secret is hard-coded here.
"""
from __future__ import annotations

import os


def _bool(value: str | None, default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


class Settings:
    # --- Foundry backend (the agent this wrapper fronts) ---
    # e.g. https://<account>.services.ai.azure.com/api/projects/<project>
    project_endpoint: str = os.environ.get("PROJECT_ENDPOINT", "")
    model_deployment: str = os.environ.get("MODEL_DEPLOYMENT", "gpt-5.1")
    agent_name: str = os.environ.get("AGENT_NAME", "cs-a2a-agent")
    agent_instructions: str = os.environ.get(
        "AGENT_INSTRUCTIONS",
        "You are a helpful assistant hosted in Azure AI Foundry and reached "
        "from Copilot Studio over the A2A protocol. Answer clearly and concisely.",
    )

    # --- Public identity of this wrapper (used in the agent card) ---
    # The externally reachable base URL, e.g. https://a2a-wrapper.<region>.azurecontainerapps.io
    public_base_url: str = os.environ.get("PUBLIC_BASE_URL", "http://localhost:8080").rstrip("/")
    card_name: str = os.environ.get("CARD_NAME", "Foundry Assistant (A2A)")
    card_description: str = os.environ.get(
        "CARD_DESCRIPTION",
        "An Azure AI Foundry agent exposed over the A2A protocol for Copilot Studio.",
    )

    # --- Inbound auth (Copilot Studio -> wrapper), Entra OAuth 2.0 ---
    auth_enabled: bool = _bool(os.environ.get("AUTH_ENABLED"), True)
    entra_tenant_id: str = os.environ.get("ENTRA_TENANT_ID", "")
    # Expected 'aud' claim on inbound tokens = the wrapper API's App ID URI or client id.
    entra_audience: str = os.environ.get("ENTRA_AUDIENCE", "")
    # Optional scope/role the caller must present (e.g. "A2A.Invoke").
    required_scope: str = os.environ.get("ENTRA_REQUIRED_SCOPE", "")

    @property
    def issuer(self) -> str:
        return f"https://login.microsoftonline.com/{self.entra_tenant_id}/v2.0"

    @property
    def jwks_uri(self) -> str:
        return f"https://login.microsoftonline.com/{self.entra_tenant_id}/discovery/v2.0/keys"


settings = Settings()
