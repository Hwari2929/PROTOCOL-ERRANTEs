extends Control
## Battle HUD — node progress, resonance grade & credits, WIN/LOSE banner.
## Reads live state from sibling BattleSession / Resonance and reacts to EventBus.
## In-engine text is English (default font has no Hangul glyphs).

var _progress: Label
var _grade: Label
var _banner: Label
var _banner_panel: Panel
var _retry: Button


func _ready() -> void:
	# Let world clicks (unit drag/select) pass through the HUD; only buttons grab input.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 가독성용 패널 배경 (상단 좌측 상태 표시).
	var hud_bg: Panel = Panel.new()
	hud_bg.position = Vector2(8.0, 8.0)
	hud_bg.size = Vector2(252.0, 92.0)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_bg)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(20.0, 14.0)
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	_progress = _make_label(vbox, 24)
	_grade = _make_label(vbox, 24)

	# 결과 배너 — 종이 카드 + 중앙 정렬.
	_banner_panel = Panel.new()
	_banner_panel.anchor_left = 0.5
	_banner_panel.anchor_top = 0.5
	_banner_panel.anchor_right = 0.5
	_banner_panel.anchor_bottom = 0.5
	_banner_panel.offset_left = -180.0
	_banner_panel.offset_right = 180.0
	_banner_panel.offset_top = -70.0
	_banner_panel.offset_bottom = 24.0
	_banner_panel.visible = false
	add_child(_banner_panel)

	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 52)
	var emph: FontFile = load("res://assets/fonts/Paperlogy-9Black.ttf")
	if emph != null:
		_banner.add_theme_font_override("font", emph)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.offset_top = 14.0
	_banner_panel.add_child(_banner)

	_retry = Button.new()
	_retry.text = "다시 시작"
	_retry.add_theme_font_size_override("font_size", 24)
	_retry.anchor_left = 0.5
	_retry.anchor_right = 0.5
	_retry.anchor_top = 0.5
	_retry.anchor_bottom = 0.5
	_retry.offset_left = -90.0
	_retry.offset_right = 90.0
	_retry.offset_top = 44.0
	_retry.offset_bottom = 96.0
	_retry.visible = false
	_retry.process_mode = Node.PROCESS_MODE_ALWAYS
	_retry.pressed.connect(_on_retry_pressed)
	add_child(_retry)

	EventBus.round_started.connect(_on_round_started)
	EventBus.battle_session_ended.connect(_on_session_ended)
	var reso: Node = get_parent().get_parent().get_node_or_null("Resonance")
	if reso != null and reso.has_signal("grade_changed"):
		reso.grade_changed.connect(_on_grade_changed)
	if reso != null and reso.has_signal("credits_changed"):
		reso.credits_changed.connect(_on_grade_changed)

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
	_banner.text = "승리" if victory else "패배"
	_banner.add_theme_color_override("font_color", Color(0.3, 0.42, 0.2) if victory else Color(0.62, 0.23, 0.18))
	_banner_panel.visible = true
	_banner.visible = true
	_retry.visible = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func refresh() -> void:
	var node_i: int = 1
	var node_n: int = 3
	var sess: Node = get_parent().get_parent().get_node_or_null("BattleSession")
	if sess != null:
		if sess.has_method("current_node"):
			node_i = sess.current_node()
		if sess.has_method("node_count"):
			node_n = sess.node_count()
	_progress.text = "노드 %d / %d" % [node_i, node_n]

	var grade: int = 1
	var credits: int = 0
	var reso: Node = get_parent().get_parent().get_node_or_null("Resonance")
	if reso != null:
		if reso.has_method("current_grade"):
			grade = reso.current_grade()
		credits = int(reso.get("credits"))
	_grade.text = "공명 등급 %d   ·   크레딧 %d" % [grade, credits]