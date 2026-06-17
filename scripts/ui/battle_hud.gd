extends Control
## Battle HUD — node progress, resonance grade & credits, WIN/LOSE banner.
## Reads live state from sibling BattleSession / Resonance and reacts to EventBus.
## In-engine text is English (default font has no Hangul glyphs).

var _progress: Label
var _grade: Label
var _banner: Label
var _retry: Button


func _ready() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(16.0, 12.0)
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	_progress = _make_label(vbox, 24)
	_grade = _make_label(vbox, 24)

	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 48)
	_banner.position = Vector2(540.0, 300.0)
	_banner.visible = false
	add_child(_banner)

	_retry = Button.new()
	_retry.text = "RETRY"
	_retry.add_theme_font_size_override("font_size", 24)
	_retry.position = Vector2(560.0, 370.0)
	_retry.custom_minimum_size = Vector2(160.0, 52.0)
	_retry.visible = false
	_retry.process_mode = Node.PROCESS_MODE_ALWAYS
	_retry.pressed.connect(_on_retry_pressed)
	add_child(_retry)

	EventBus.round_started.connect(_on_round_started)
	EventBus.battle_session_ended.connect(_on_session_ended)
	var reso: Node = get_parent().get_node_or_null("Resonance")
	if reso != null and reso.has_signal("grade_changed"):
		reso.grade_changed.connect(_on_grade_changed)

	refresh()


func _make_label(parent: Node, size: int) -> Label:
	var l: Label = Label.new()
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _on_round_started(_round_number: int) -> void:
	refresh()


func _on_grade_changed(_new_grade: int) -> void:
	refresh()


func _on_session_ended(victory: bool) -> void:
	_banner.text = "VICTORY" if victory else "DEFEAT"
	_banner.modulate = Color(0.6, 1.0, 0.6) if victory else Color(1.0, 0.5, 0.5)
	_banner.visible = true
	_retry.visible = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func refresh() -> void:
	var node_i: int = 1
	var node_n: int = 3
	var sess: Node = get_parent().get_node_or_null("BattleSession")
	if sess != null:
		if sess.has_method("current_node"):
			node_i = sess.current_node()
		if sess.has_method("node_count"):
			node_n = sess.node_count()
	_progress.text = "Node %d / %d" % [node_i, node_n]

	var grade: int = 1
	var credits: int = 0
	var reso: Node = get_parent().get_node_or_null("Resonance")
	if reso != null:
		if reso.has_method("current_grade"):
			grade = reso.current_grade()
		credits = int(reso.get("credits"))
	_grade.text = "Resonance Grade %d   |   Credits %d" % [grade, credits]
