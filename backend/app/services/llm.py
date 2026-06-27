import json
from collections.abc import AsyncIterator
from typing import Any

from anthropic import AsyncAnthropic

from app.config import settings

_client: AsyncAnthropic | None = None

_MODEL_ID = "claude-sonnet-4-20250514"

APPEARANCE_TOOL: dict[str, Any] = {
    "name": "update_appearance",
    "description": (
        "Update the companion's appearance based on the user's request. "
        "Call this when the user asks to change something about how the companion looks. "
        "The companion should acknowledge the change in its next response."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "deltas": {
                "type": "object",
                "description": (
                    "Key-value pairs of appearance attributes to change. "
                    "Common keys: hair_color, hair_style, eye_color, skin_color, "
                    "beard_style, glasses, outfit. Values are free-text descriptions."
                ),
                "additionalProperties": {"type": "string"},
            }
        },
        "required": ["deltas"],
    },
}


def get_client() -> AsyncAnthropic:
    global _client
    if _client is None:
        _client = AsyncAnthropic(api_key=settings.anthropic_api_key)
    return _client


async def stream_chat(
    system_prompt: str,
    messages: list[dict],
    tools: list[dict] | None = None,
) -> AsyncIterator[str]:
    client = get_client()
    async with client.messages.stream(
        model=_MODEL_ID,
        max_tokens=1024,
        system=system_prompt,
        messages=messages,
        tools=tools,
    ) as stream:
        async for chunk in stream:
            if chunk.type == "content_block_delta" and chunk.delta.type == "text_delta":
                yield chunk.delta.text


async def detect_appearance_change(
    system_prompt: str,
    messages: list[dict],
) -> dict[str, Any] | None:
    client = get_client()
    try:
        response = await client.messages.create(
            model=_MODEL_ID,
            max_tokens=256,
            system=system_prompt + (
                "\n\nIf the user is asking to change your appearance, use the "
                "update_appearance tool to record the changes."
            ),
            messages=messages,
            tools=[APPEARANCE_TOOL],
        )
        for block in response.content:
            if block.type == "tool_use" and block.name == "update_appearance":
                return block.input
    except Exception:
        pass
    return None


async def extract_memories_from_turn(
    user_message: str,
    assistant_reply: str,
) -> list[dict]:
    client = get_client()
    response = await client.messages.create(
        model=_MODEL_ID,
        max_tokens=1024,
        system=(
            "You are a memory extraction system. Analyze a conversation turn between "
            "a user and an AI companion. Extract any factual information, preferences, "
            "events, or emotional states that would be worth remembering.\n\n"
            "Return a JSON array of objects with these fields:\n"
            "- content: a concise summary of what to remember (1 sentence)\n"
            "- kind: one of 'fact', 'preference', 'event', 'emotion'\n"
            "- salience: a float from 0.0 (trivial) to 1.0 (very important)\n\n"
            "If nothing is worth remembering, return an empty array [].\n"
            "Return ONLY valid JSON, no other text."
        ),
        messages=[
            {
                "role": "user",
                "content": f"User: {user_message}\n\nAssistant: {assistant_reply}",
            }
        ],
    )
    content = response.content[0].text
    try:
        return json.loads(content)
    except (json.JSONDecodeError, IndexError, KeyError):
        return []


async def detect_emotion(
    companion_state_text: str,
    user_message: str,
    assistant_reply: str,
) -> str:
    client = get_client()
    response = await client.messages.create(
        model=_MODEL_ID,
        max_tokens=50,
        system=(
            "Given the companion's personality and the conversation turn, "
            "determine the companion's emotional state in one word. "
            "Choose from: warm, amused, thoughtful, curious, concerned, playful, "
            "serious, excited, sympathetic, Neutral. "
            "Return ONLY the single word, nothing else."
        ),
        messages=[
            {
                "role": "user",
                "content": (
                    f"Personality: {companion_state_text}\n\n"
                    f"User: {user_message}\n\n"
                    f"Assistant: {assistant_reply}"
                ),
            }
        ],
    )
    return response.content[0].text.strip()
