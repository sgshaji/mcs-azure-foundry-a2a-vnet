"""Foundry backend: create-or-get an agent in the project and invoke it.

Runs inside the VNet (Container App) so it can reach the private Foundry
endpoint. Authenticates with the Container App's managed identity via
DefaultAzureCredential.

NOTE: the exact `azure-ai-projects` surface has changed across versions.
This module isolates every SDK call so it can be adjusted in one place if the
installed version differs. Validate against the pinned version at build time.
"""
from __future__ import annotations

import asyncio
import threading

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

from .config import settings

_client: AIProjectClient | None = None
_agent = None
_lock = threading.Lock()


def _project_client() -> AIProjectClient:
    global _client
    if _client is None:
        _client = AIProjectClient(
            endpoint=settings.project_endpoint,
            credential=DefaultAzureCredential(),
        )
    return _client


def _create_or_get_agent():
    """Idempotently ensure an agent named settings.agent_name exists."""
    global _agent
    if _agent is not None:
        return _agent
    with _lock:
        if _agent is not None:
            return _agent
        pc = _project_client()
        # Agent listing is the one call whose name drifted across SDK versions
        # (list_agents -> list). Resolve defensively so a minor rename can't crash us.
        _lister = getattr(pc.agents, "list_agents", None) or getattr(pc.agents, "list", None)
        existing_agents = _lister() if _lister is not None else []
        for existing in existing_agents:
            if getattr(existing, "name", None) == settings.agent_name:
                _agent = existing
                break
        else:
            _agent = pc.agents.create_agent(
                model=settings.model_deployment,
                name=settings.agent_name,
                instructions=settings.agent_instructions,
            )
    return _agent


def _extract_text(messages) -> str:
    """Best-effort extraction of the newest assistant text from a messages list."""
    for msg in messages:
        if getattr(msg, "role", None) != "assistant":
            continue
        # azure-ai-agents exposes a `text_messages` helper on each message.
        text_messages = getattr(msg, "text_messages", None)
        if text_messages:
            return text_messages[-1].text.value
        # Fallback: iterate raw content parts.
        parts = getattr(msg, "content", None) or []
        for part in parts:
            text = getattr(getattr(part, "text", None), "value", None)
            if text:
                return text
    return "(no response from agent)"


def _ask_sync(user_text: str) -> str:
    pc = _project_client()
    agent = _create_or_get_agent()

    thread = pc.agents.threads.create()
    pc.agents.messages.create(thread_id=thread.id, role="user", content=user_text)
    run = pc.agents.runs.create_and_process(thread_id=thread.id, agent_id=agent.id)

    if getattr(run, "status", None) == "failed":
        return f"Agent run failed: {getattr(run, 'last_error', 'unknown error')}"

    messages = pc.agents.messages.list(thread_id=thread.id, order="desc")
    return _extract_text(messages)


async def ask(user_text: str) -> str:
    """Async wrapper so the A2A executor doesn't block the event loop."""
    return await asyncio.to_thread(_ask_sync, user_text)
