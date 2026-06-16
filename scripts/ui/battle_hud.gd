extends Control
## Battle HUD — Displays run state on screen.
## Subscribes to EventBus battle signals and reflects run state on screen.

var _progress_label: Label
var _grade_label: Label
var _banner_label: Label

func _ready() -> void:
    # Create child Labels
    _progress_label = Label.new()
    _progress_label.name = "ProgressLabel"
    _progress_label.add_theme_font_size_override("font_size", 24)
    add_child(_progress_label)

    _grade_label = Label.new()
    _grade_label.name = "GradeLabel"
    _grade_label.add_theme_font_size_override("font_size", 24)
    add_child(_grade_label)

    _banner_label = Label.new()
    _banner_label.name = "BannerLabel"
    _banner_label.add_theme_font_size_override("font_size", 32)
    _banner_label.visible = false
    add_child(_banner_label)

    # Connect to EventBus autoload signals
    if EventBus:
        EventBus.round_started.connect(_on_event_bus_round_started)
        EventBus.battle_session_ended.connect(_on_event_bus_battle_session_ended)

    # Connect to sibling Resonance grade_changed signal
    var resonance_node: Node = get_parent().get_node_or_null("Resonance")
    if resonance_node:
        resonance_node.grade_changed.connect(_on_resonance_grade_changed)

    # Initial state
    refresh()

func _on_event_bus_round_started(round_number: int) -> void:
    refresh()

func _on_event_bus_battle_session_ended(victory: bool) -> void:
    _banner_label.text = "WIN" if victory else "LOSE"
    _banner_label.visible = true

func _on_resonance_grade_changed(grade: String) -> void:
    refresh()

func refresh() -> void:
    # Read current state from siblings via guarded get_parent lookups
    var battle_field: Node = get_parent().get_node_or_null("BattleField")
    var resonance_node: Node = get_parent().get_node_or_null("Resonance")
    var battle_session: Node = get_parent().get_node_or_null("BattleSession")

    # Update node progress
    var total_nodes: int = 3
    var current_node: int = 1
    if GameManager:
        if GameManager.has_method("get_current_node"):
            var result = GameManager.get_current_node()
            if result is int:
                current_node = result
    _progress_label.text = "Node %d/%d" % [current_node, total_nodes]

    # Update resonance grade & credits
    var grade: String = "S"
    var credits: int = 0
    if resonance_node:
        if resonance_node.has_method("get_grade"):
            grade = resonance_node.get_grade()
    if ResourceManager:
        if ResourceManager.has_method("get_credits"):
            credits = ResourceManager.get_credits()
    _grade_label.text = "Grade: %s | Credits: %d" % [grade, credits]

    # Hide banner if session is not ended (prevent stale banner)
    # Only show banner if explicitly triggered by signal, but ensure it's hidden if session is active/ended without signal
    if battle_session:
        if battle_session.has_method("is_session_ended"):
            if not battle_session.is_session_ended():
                _banner_label.visible = false