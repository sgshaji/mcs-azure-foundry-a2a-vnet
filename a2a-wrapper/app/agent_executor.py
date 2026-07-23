"""A2A AgentExecutor that delegates each incoming task to the Foundry agent."""
from __future__ import annotations

from a2a.server.agent_execution import AgentExecutor, RequestContext
from a2a.server.events import EventQueue
from a2a.utils import new_agent_text_message

from .foundry_client import ask


class FoundryAgentExecutor(AgentExecutor):
    async def execute(self, context: RequestContext, event_queue: EventQueue) -> None:
        user_input = context.get_user_input()
        reply = await ask(user_input)
        await event_queue.enqueue_event(new_agent_text_message(reply))

    async def cancel(self, context: RequestContext, event_queue: EventQueue) -> None:
        # Foundry runs are short-lived and processed synchronously; nothing to cancel.
        raise NotImplementedError("Cancellation is not supported.")
