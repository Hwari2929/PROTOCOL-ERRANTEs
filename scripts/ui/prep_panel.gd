extends Control
## 준비(배치) 페이즈 패널 — START 버튼 + 안내. PREP에 표시, COMBAT에 숨김.

var _btn: Button
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # let drag input reach units

	_btn = Button.new()
	_btn.text = "전투 시작"
	_btn.add_theme_font_size_override("font_size", 22)
	# Bottom-right corner — clear of the tactical card row and the deploy zone.
	_btn.anchor_left = 1.0
	_btn.anchor_right = 1.0
	_btn.anchor_top = 1.0
	_btn.anchor_bottom = 1.0
	_btn.offset_left = -210.0
	_btn.offset_right = -20.0
	_btn.offset_top = -84.0
	_btn.offset_bottom = -24.0
	add_child(_btn)

	_label = Label.new()
	_label.text = "유닛을 드래그해 배치 / 대기실로 이동 후 전투 시작"
	_label.add_theme_font_size_override("font_size", 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.anchor_left = 1.0
	_label.anchor_right = 1.0
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = -420.0
	_label.offset_right = -20.0
	_label.offset_top = -116.0
	_label.offset_bottom = -90.0
	add_child(_label)

	_btn.pressed.connect(_on_start_combat_pressed)

	var bf: Node = get_parent().get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_signal("phase_changed"):
		bf.phase_changed.connect(_on_phase_changed)


func _on_start_combat_pressed() -> void:
	var bf: Node = get_parent().get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_method("start_combat"):
		bf.start_combat()


func _on_phase_changed(new_phase: int) -> void:
	visible = new_phase == 0


func refresh() -> void:
	pass