"""Sonde bas niveau du protocole gama-server (JSON sur WebSocket).

Sert aux vérifications ponctuelles — compiler un modèle, lister ses expériences.
Le pilotage d'un run complet passe par `gama_session.GamaSession`, qui garde la
connexion ouverte.
"""

import asyncio
import json
from typing import Any

import websockets

from app.shared.config import settings

# Réponses terminales : on arrête de lire dès qu'on en reçoit une.
_TERMINAL = {
    "CommandExecutedSuccessfully",
    "MalformedRequest",
    "UnableToExecuteRequest",
    "GamaServerError",
    "RuntimeError",
    "SimulationError",
}


async def send_command(command: dict[str, Any], timeout: float | None = None) -> dict[str, Any]:
    """Ouvre une connexion, envoie une commande, renvoie la première réponse terminale."""
    timeout = timeout or settings.GAMA_COMMAND_TIMEOUT

    async def _exchange() -> dict[str, Any]:
        async with websockets.connect(settings.gama_ws_url, max_size=None) as ws:
            await ws.send(json.dumps(command))
            while True:
                raw = await ws.recv()
                message = json.loads(raw)
                # ConnectionSuccessful et les messages de statut précèdent la réponse.
                if message.get("type") in _TERMINAL:
                    return message

    return await asyncio.wait_for(_exchange(), timeout=timeout)


async def describe_model(model_path: str | None = None) -> dict[str, Any]:
    """Compile le modèle côté GAMA et renvoie ses expériences.

    Sonde de bout en bout la plus utile : elle prouve à la fois que le socket
    répond, que GAMA voit le modèle au chemin partagé, et qu'il compile.
    """
    return await send_command(
        {
            "type": "describe",
            "model": str(model_path or settings.MAELIA_MODEL_PATH),
            "experiments": True,
        }
    )
