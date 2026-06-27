import json

from fastapi import WebSocket, WebSocketDisconnect

from app.graph.companions import get_companion_state
from app.graph.memories import create_memory, get_salient_memories
from app.graph.relationships import increment_turn_count
from app.graph.turns import save_turn
from app.graph.users import ensure_user
from app.models.companion import CompanionState
from app.services.llm import detect_emotion, extract_memories_from_turn, stream_chat
from app.services.persona import build_persona_system_prompt


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

            if data.get("type") != "user_message":
                continue

            user_text = data["text"]

            user_turn_id = await save_turn(companion_id, user_id, "user", user_text)

            conversation_history.append({"role": "user", "content": user_text})

            full_reply = ""
            async for token in stream_chat(system_prompt, conversation_history):
                full_reply += token
                await ws.send_json({"type": "token", "text": token})

            if full_reply:
                await save_turn(companion_id, user_id, "assistant", full_reply)
                conversation_history.append(
                    {"role": "assistant", "content": full_reply}
                )

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

                await increment_turn_count(companion_id, user_id)

            await ws.send_json({"type": "done"})

    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            await ws.send_json({"type": "error", "message": str(e)})
        except Exception:
            pass


def _format_memories_for_context(memories: list[dict]) -> str:
    if not memories:
        return ""
    lines = []
    for i, mem in enumerate(memories, 1):
        lines.append(f"{i}. [{mem['kind']}] {mem['content']}")
    return "\n".join(lines)
