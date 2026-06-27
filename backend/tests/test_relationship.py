from app.services.relationship import stage_for_turn_count


def test_acquaintance_at_zero():
    assert stage_for_turn_count(0) == "acquaintance"


def test_acquaintance_below_threshold():
    assert stage_for_turn_count(5) == "acquaintance"


def test_friend_at_threshold():
    assert stage_for_turn_count(10) == "friend"


def test_friend_above_threshold():
    assert stage_for_turn_count(25) == "friend"


def test_confidant_at_threshold():
    assert stage_for_turn_count(50) == "confidant"


def test_confidant_above_threshold():
    assert stage_for_turn_count(100) == "confidant"
