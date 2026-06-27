STAGE_THRESHOLDS: list[tuple[int, str]] = [
    (0, "acquaintance"),
    (10, "friend"),
    (50, "confidant"),
]


def stage_for_turn_count(count: int) -> str:
    stage = "acquaintance"
    for threshold, s in reversed(STAGE_THRESHOLDS):
        if count >= threshold:
            stage = s
            break
    return stage
