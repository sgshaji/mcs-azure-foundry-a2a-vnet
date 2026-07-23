"""A2A wrapper entry point.

Exposes:
  GET  /.well-known/agent.json   -> agent card (public, what Copilot Studio probes)
  GET  /health                   -> liveness probe (public)
  POST /                         -> A2A JSON-RPC endpoint (OAuth-protected)

The A2A protocol surface is provided by the official `a2a-sdk`; we add a
`/.well-known/agent.json` alias (Copilot Studio's expected discovery path) and
Entra OAuth validation on the RPC endpoint.
"""
from __future__ import annotations

from a2a.server.apps import A2AStarletteApplication
from a2a.server.request_handlers import DefaultRequestHandler
from a2a.server.tasks import InMemoryTaskStore
from a2a.types import AgentCapabilities, AgentCard, AgentSkill
from starlette.requests import Request
from starlette.responses import JSONResponse

from .agent_executor import FoundryAgentExecutor
from .auth import EntraAuthMiddleware
from .config import settings

_SKILL = AgentSkill(
    id="general-assistant",
    name="General assistant",
    description="Answers questions and completes tasks using an Azure AI Foundry agent.",
    tags=["foundry", "assistant"],
    examples=["What can you help me with?", "Summarize this text."],
)

CARD = AgentCard(
    name=settings.card_name,
    description=settings.card_description,
    url=f"{settings.public_base_url}/",
    version="1.0.0",
    default_input_modes=["text"],
    default_output_modes=["text"],
    capabilities=AgentCapabilities(streaming=False),
    skills=[_SKILL],
)

_request_handler = DefaultRequestHandler(
    agent_executor=FoundryAgentExecutor(),
    task_store=InMemoryTaskStore(),
)

# Build the A2A Starlette app (RPC endpoint + SDK-native card route).
app = A2AStarletteApplication(agent_card=CARD, http_handler=_request_handler).build()


async def _agent_json(_: Request) -> JSONResponse:
    # Copilot Studio expects the card at /.well-known/agent.json.
    return JSONResponse(CARD.model_dump(mode="json", by_alias=True, exclude_none=True))


async def _health(_: Request) -> JSONResponse:
    return JSONResponse({"status": "ok"})


app.add_route("/.well-known/agent.json", _agent_json, methods=["GET"])
# Newer A2A spec renamed the well-known card path; clients like Copilot Studio probe this one.
app.add_route("/.well-known/agent-card.json", _agent_json, methods=["GET"])
app.add_route("/health", _health, methods=["GET"])
# Some A2A clients (e.g. Copilot Studio) validate the endpoint with GET / and expect the card.
# POST / remains the A2A JSON-RPC endpoint provided by the SDK; this only adds the GET method.
app.add_route("/", _agent_json, methods=["GET"])

# Auth runs last-added => outermost; it lets /.well-known, /health, and GET / through.
app.add_middleware(EntraAuthMiddleware)
