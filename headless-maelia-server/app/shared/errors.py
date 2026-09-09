"""Application errors and RFC 7807 rendering.

Three families, three treatments:
  - business       -> `DomainError`, turned into a 4xx by the global handler;
  - infrastructure -> propagated as is, the run ends FAILED with the reason;
  - programming    -> never caught locally, 500 with a traceback.
"""

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

PROBLEM_MEDIA_TYPE = "application/problem+json"


class DomainError(Exception):
    """A business rule was violated. Default status: 400."""

    status_code = 400
    title = "Requête invalide"


class NotFoundError(DomainError):
    status_code = 404
    title = "Ressource introuvable"


class ConflictError(DomainError):
    status_code = 409
    title = "État incompatible"


class ValidationError(DomainError):
    status_code = 422
    title = "Données invalides"

    def __init__(self, message: str, issues: list[dict] | None = None) -> None:
        super().__init__(message)
        self.issues = issues or []


def _problem(status: int, title: str, detail: str, **extra) -> JSONResponse:
    body = {"type": "about:blank", "title": title, "status": status, "detail": detail}
    body.update(extra)
    return JSONResponse(status_code=status, content=body, media_type=PROBLEM_MEDIA_TYPE)


def install_error_handlers(app: FastAPI) -> None:
    """A single place turns errors into HTTP responses."""

    @app.exception_handler(DomainError)
    async def _domain(_: Request, exc: DomainError) -> JSONResponse:
        extra = {"issues": exc.issues} if isinstance(exc, ValidationError) else {}
        return _problem(exc.status_code, exc.title, str(exc), **extra)

    @app.exception_handler(RequestValidationError)
    async def _pydantic(_: Request, exc: RequestValidationError) -> JSONResponse:
        return _problem(
            422, "Données invalides", "la requête ne respecte pas le schéma attendu",
            issues=[
                {"field": ".".join(str(p) for p in e["loc"]), "message": e["msg"]}
                for e in exc.errors()
            ],
        )
