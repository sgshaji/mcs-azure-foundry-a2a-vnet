"""Entra ID (Azure AD) bearer-token validation middleware.

Copilot Studio's A2A connector (OAuth 2.0) obtains a token and presents it as
`Authorization: Bearer <jwt>`. This middleware validates that token's signature,
issuer, audience and (optionally) a required scope/role.

The agent card and health endpoints are intentionally left unauthenticated so
Copilot Studio can discover the agent before a connection exists.
"""
from __future__ import annotations

import jwt
from jwt import PyJWKClient
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

from .config import settings

_PUBLIC_PATHS = ("/.well-known", "/health")


class EntraAuthMiddleware(BaseHTTPMiddleware):
    def __init__(self, app):
        super().__init__(app)
        # PyJWKClient caches signing keys internally.
        self._jwks: PyJWKClient | None = (
            PyJWKClient(settings.jwks_uri) if settings.auth_enabled else None
        )

    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        if any(path.startswith(p) for p in _PUBLIC_PATHS):
            return await call_next(request)

        # Agent-card discovery on the root (GET /) must stay open even with auth on;
        # only the A2A RPC (POST /) is protected.
        if request.method == "GET" and path == "/":
            return await call_next(request)

        if not settings.auth_enabled:
            return await call_next(request)

        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return JSONResponse({"error": "missing_bearer_token"}, status_code=401)

        token = auth_header[len("Bearer "):].strip()
        try:
            signing_key = self._jwks.get_signing_key_from_jwt(token)  # type: ignore[union-attr]
            claims = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256"],
                audience=settings.entra_audience,
                issuer=settings.issuer,
            )
        except Exception as exc:  # noqa: BLE001 - surface a clean 401 to the caller
            return JSONResponse(
                {"error": "invalid_token", "detail": str(exc)}, status_code=401
            )

        if settings.required_scope:
            scopes = set((claims.get("scp") or "").split())
            roles = set(claims.get("roles") or [])
            if settings.required_scope not in scopes | roles:
                return JSONResponse({"error": "insufficient_scope"}, status_code=403)

        return await call_next(request)
