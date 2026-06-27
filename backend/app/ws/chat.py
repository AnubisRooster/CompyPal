import json

from fastapi import WebSocket, WebSocketDisconnect

from app.graph.appearance import apply_appearance_deltas, compute_appearance_hash
from app.graph.companions import get_companion_state
from app.graph.memories import create_memory, get_salient_memories
from app.graph.relationships import increment_turn_count
from app.graph.turns import save_turn
from app.graph.users import ensure_user
from app.models.companion import CompanionState
from app.services.appearance import AppearanceService
from app.services.llm import (
    APPEARANCE_TOOL,
    detect_appearance_change,
    detect_emotion,
    extract_memories_from_turn,
    stream_chat,
)
from app.services.persona import build_persona_system_prompt
from app.services.tts import stream_tts
from app.config import settings

_appearance_service = AppearanceService()


async def handle_chat(ws: WebSocket, companion_id: str, user_id: str) -> None:
    await ws.accept()

    state_data = await get_companion_state(companion_id, user_id)
    if state_data is None:
        await ws.send_json({"type": "error", "message": "Companion not found"})
        await ws.close()
        return

    await ensure_user(user_id)
    companion_state = CompanionState(**state_data)

    recent_memories = await get_salient_memories(user_id, companion_id)
    memories_context = _format_memories_for_context(recent_memories)
    system_prompt = build_persona_system_prompt(companion_state)
    if memories_context:
        system_prompt += f"\n\n## Relevant Memories\n{memories_context}"

    conversation_history: list[dict] = []

    try:
        while True:
            raw = await ws.receive_text()
            data = json.loads(raw)

            msg_type = data.get("type", "")

            if msg_type == "user_message":
                user_text = data["text"]
                await _handle_user_message(
                    ws, companion_id, user_id, companion_state,
                    system_prompt, conversation_history, user_text,
                )
            elif msg_type == "audio_transcript":
                user_text = data["text"]
                await _handle_user_message(
                    ws, companion_id, user_id, companion_state,
                    system_prompt, conversation_history, user_text,
                )

    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            await ws.send_json({"type": "error", "message": str(e)})
        except Exception:
            pass


async def _handle_user_message(
    ws: WebSocket,
    companion_id: str,
    user_id: str,
    companion_state: CompanionState,
    system_prompt: str,
    conversation_history: list[dict],
    user_text: str,
) -> None:
    user_turn_id = await save_turn(companion_id, user_id, "user", user_text)
    conversation_history.append({"role": "user", "content": user_text})

    appearance_change = await detect_appearance_change(
        system_prompt, conversation_history
    )

    if appearance_change and "deltas" in appearance_change:
        deltas = appearance_change["deltas"]
        new_appearance = await apply_appearance_deltas(companion_id, deltas)
        companion_state.appearance = new_appearance
        system_prompt = build_persona_system_prompt(companion_state)
        if "appearance_changed" in system_prompt:
            system_prompt += (
                f"\n\nYour appearance just changed in response to the user's request."
            )

        asset_url = await _appearance_service.process_appearance_change(
            companion_id, new_appearance
        )
        if asset_url:
            await ws.send_json({
                "type": "appearance_update",
                "asset_url": asset_url,
                "attributes": new_appearance,
            })

        conversation_history.append({
            "role": "assistant",
            "content": (
                f"I'll update my appearance: {_format_deltas(deltas)}. "
                "Acknowledge this change naturally in your response."
            ),
        })

    full_reply = ""
    async for token in stream_chat(system_prompt, conversation_history):
        full_reply += token
        await ws.send_json({"type": "token", "text": token})

    if not full_reply:
        await ws.send_json({"type": "done"})
        return

    await save_turn(companion_id, user_id, "assistant", full_reply)
    conversation_history.append({"role": "assistant", "content": full_reply})

    extracted = await extract_memories_from_turn(user_text, full_reply)
    for mem in extracted:
        await create_memory(
            user_id=user_id,
            companion_id=companion_id,
            content=mem["content"],
            kind=mem["kind"],
            salience=mem.get("salience", 0.5),
            source_turn_id=user_turn_id,
        )

    emotion = await detect_emotion(
        companion_state.name, user_text, full_reply
    )
    await ws.send_json({"type": "emotion", "state": emotion})

    voice_id = companion_state.voice_id or "21m00Tcm4TlvDq8ikWAM"
    audio_chunks = await stream_tts(full_reply, voice_id)
    for seq, chunk in enumerate(audio_chunks):
        if chunk:
            await ws.send_json({"type": "audio_chunk", "seq": seq, "data": chunk})

    await increment_turn_count(companion_id, user_id)
    await ws.send_json({"type": "done"})


def _format_memories_for_context(memories: list[dict]) -> str:
    if not memories:
        return ""
    lines = []
    for i, mem in enumerate(memories, 1):
        lines.append(f"{i}. [{mem['kind']}] {mem['content']}")
    return "\n".join(lines)


def _format_deltas(deltas: dict[str, str]) -> str:
    return ", ".join(
        f"{k.replace('_', ' ')} = {v}" for k, v in deltas.items()
    )
