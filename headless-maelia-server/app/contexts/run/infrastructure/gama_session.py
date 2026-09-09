"""Session GAMA persistante — pilotage d'un run complet.

Contrainte structurante du protocole gama-server : **si le socket se ferme, GAMA
détruit la simulation**. La connexion doit donc rester ouverte du `load` jusqu'à
la fin. C'est pour cette raison qu'un run est porté par une tâche worker dédiée,
et non par une requête HTTP.

On parle le protocole JSON directement plutôt que via `gama-client` : le flux de
messages doit être relayé au fil de l'eau, ce que l'API bloquante du client ne
permet pas simplement.
"""

import asyncio
import json
import logging
from collections.abc import Awaitable, Callable
from typing import Any

import websockets

from app.shared.config import settings

log = logging.getLogger("maelia.gama")

EventHandler = Callable[[dict[str, Any]], Awaitable[None]]

# Réponses terminales d'une commande.
TERMINAL = {
    "CommandExecutedSuccessfully",
    "MalformedRequest",
    "UnableToExecuteRequest",
    "GamaServerError",
    "RuntimeError",
    "SimulationError",
}

# Messages signalant qu'une simulation s'est arrêtée.
ENDED = {"SimulationEnded"}
# Marqueur écrit par main.gaml juste avant `do pause` (cf. wait_for_end).
END_MARKERS = ("*********** FIN DE SIMULATION ***********",)
FAILED = {"SimulationError", "RuntimeError", "GamaServerError"}


class GamaError(RuntimeError):
    """Erreur remontée par gama-server (commande refusée ou simulation en échec)."""


class GamaSession:
    """Connexion WebSocket unique, tenue ouverte pendant toute la durée du run."""

    def __init__(self, on_event: EventHandler | None = None) -> None:
        self._on_event = on_event
        self._ws: Any = None
        self.exp_id: str | None = None

    async def __aenter__(self) -> "GamaSession":
        self._ws = await websockets.connect(
            settings.gama_ws_url,
            max_size=None,      # les réponses `describe` dépassent le Mo
            ping_interval=20,   # garde la connexion vivante pendant les longs runs
            ping_timeout=None,
        )
        return self

    async def __aexit__(self, *_exc: object) -> None:
        if self._ws is not None:
            await self._ws.close()
            self._ws = None

    # ── plomberie ────────────────────────────────────────────────────────────

    async def _emit(self, message: dict[str, Any]) -> None:
        if self._on_event is not None:
            await self._on_event(message)

    @staticmethod
    def _text_of(message: dict[str, Any]) -> str:
        content = message.get("content")
        text = content.get("message") if isinstance(content, dict) else content
        return text if isinstance(text, str) else ""

    async def _read_until(
        self,
        wanted: set[str],
        timeout: float,
        text_markers: tuple[str, ...] = (),
    ) -> dict[str, Any]:
        """Lit le flux en relayant chaque message, jusqu'à un type `wanted`
        ou une ligne de console contenant l'un des `text_markers`."""

        async def _loop() -> dict[str, Any]:
            while True:
                message = json.loads(await self._ws.recv())
                await self._emit(message)
                if message.get("type") in wanted:
                    return message
                if text_markers:
                    text = self._text_of(message)
                    if any(marker in text for marker in text_markers):
                        return {
                            "type": "SimulationEnded",
                            "content": text,
                            "detected_from": "console",
                        }

        return await asyncio.wait_for(_loop(), timeout=timeout)

    async def _command(
        self, payload: dict[str, Any], timeout: float | None = None
    ) -> dict[str, Any]:
        await self._ws.send(json.dumps(payload))
        reply = await self._read_until(TERMINAL, timeout or settings.GAMA_COMMAND_TIMEOUT)
        if reply.get("type") != "CommandExecutedSuccessfully":
            raise GamaError(f"{payload.get('type')} refusé par GAMA : {reply}")
        return reply

    # ── commandes ────────────────────────────────────────────────────────────

    async def load(
        self,
        model: str,
        experiment: str,
        parameters: list[dict[str, Any]] | None = None,
        until: str | None = None,
    ) -> str:
        """Compile le modèle et instancie l'expérience. Renvoie l'`exp_id`.

        Étape la plus lente (compilation GAML complète de MAELIA : ~35 s), d'où un
        délai propre, distinct de celui des autres commandes.
        """
        payload: dict[str, Any] = {
            "type": "load",
            "model": model,
            "experiment": experiment,
            "console": True,
            "status": True,
            "dialog": False,
            "runtime": True,
            "parameters": parameters or [],
        }
        if until:
            payload["until"] = until

        reply = await self._command(payload, timeout=settings.GAMA_RUN_TIMEOUT)
        self.exp_id = reply.get("content")
        if not self.exp_id:
            raise GamaError(f"load n'a pas renvoyé d'exp_id : {reply}")
        return self.exp_id

    async def play(self) -> None:
        await self._command({"type": "play", "exp_id": self.exp_id, "sync": False})

    async def stop(self) -> None:
        try:
            await self._command({"type": "stop", "exp_id": self.exp_id})
        except Exception as exc:  # arrêt best-effort : ne doit jamais masquer l'erreur d'origine
            log.warning("stop(%s) a échoué : %s", self.exp_id, exc)

    async def expression(self, expr: str) -> Any:
        reply = await self._command({"type": "expression", "exp_id": self.exp_id, "expr": expr})
        return reply.get("content")

    async def wait_for_end(
        self,
        timeout: float | None = None,
        text_markers: tuple[str, ...] = END_MARKERS,
    ) -> dict[str, Any]:
        """Bloque jusqu'à la fin de la simulation, en relayant tout le flux au passage.

        `SimulationEnded` ne suffit pas pour MAELIA : le modèle exécute `do pause`
        AVANT de poser `simulationTerminee`, si bien que l'expérience est déjà en
        pause quand la condition `until:` devient vraie — GAMA n'émet alors pas
        toujours l'événement. On surveille donc aussi le marqueur que le modèle
        écrit sur la console en fin de run.
        """
        message = await self._read_until(
            ENDED | FAILED, timeout or settings.GAMA_RUN_TIMEOUT, text_markers=text_markers
        )
        if message.get("type") in FAILED:
            raise GamaError(f"simulation en échec : {message}")
        return message
