import pytest
from app.services.persona import build_persona_system_prompt
from app.models.companion import CompanionState, Trait


def test_build_prompt_includes_name():
    state = CompanionState(companion_id="1", name="Aria")
    prompt = build_persona_system_prompt(state)
    assert "Aria" in prompt


def test_build_prompt_includes_traits():
    state = CompanionState(
        companion_id="1",
        name="Aria",
        traits=[Trait(name="curious", intensity=0.9)],
    )
    prompt = build_persona_system_prompt(state)
    assert "curious" in prompt
    assert "very strongly" in prompt


def test_build_prompt_includes_appearance():
    state = CompanionState(
        companion_id="1",
        name="Aria",
        appearance={"hair_color": "auburn", "eye_color": "green"},
    )
    prompt = build_persona_system_prompt(state)
    assert "auburn" in prompt
    assert "green" in prompt


def test_build_prompt_includes_relationship_stage():
    state = CompanionState(
        companion_id="1",
        name="Aria",
        relationship_stage="confidant",
    )
    prompt = build_persona_system_prompt(state)
    assert "confidant" in prompt


def test_trait_intensity_mapping():
    state = CompanionState(
        companion_id="1",
        name="Bot",
        traits=[
            Trait(name="warm", intensity=0.9),
            Trait(name="funny", intensity=0.6),
            Trait(name="shy", intensity=0.2),
        ],
    )
    prompt = build_persona_system_prompt(state)
    assert "very strongly warm" in prompt
    assert "strongly funny" in prompt
    assert "mildly shy" in prompt


def test_different_personalities_are_distinct():
    a_state = CompanionState(
        companion_id="1", name="Aria",
        traits=[Trait(name="serious", intensity=0.8)],
    )
    b_state = CompanionState(
        companion_id="2", name="Boba",
        traits=[Trait(name="playful", intensity=0.9)],
    )
    prompt_a = build_persona_system_prompt(a_state)
    prompt_b = build_persona_system_prompt(b_state)
    assert prompt_a != prompt_b
    assert "Aria" in prompt_a
    assert "Boba" in prompt_b
