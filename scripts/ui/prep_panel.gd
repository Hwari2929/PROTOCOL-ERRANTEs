extends Control
## 준비(배치) 페이즈 패널 — START 버튼 + 안내. PREP에 표시, COMBAT에 숨김.

var _btn: Button
var _label: Label
var _resonate: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # let drag input reach units

	_btn = Button.new()
	_btn.text = "전투 시작"
	_btn.add_theme_font_size_override("font_size", 22)
	# Small button, bottom-centre (does NOT cover the deploy zone).
	_btn.anchor_left = 0.5
	_btn.anchor_right = 0.5
	_btn.anchor_top = 1.0
	_btn.anchor_bottom = 1.0
	_btn.offset_left = -120.0
	_btn.offset_right = 120.0
	_btn.offset_top = -76.0
	_btn.offset_bottom = -20.0
	add_child(_btn)

	_label = Label.new()
	_label.text = "유닛을 배치한 뒤 전투를 시작하세요"
	_label.add_theme_font_size_override("font_size", 18)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.5
	_label.anchor_right = 0.5
	_label.anchor_top = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_left = -180.0
	_label.offset_right = 180.0
	_label.offset_top = -206.0
	_label.offset_bottom = -178.0
	add_child(_label)

	# RESONATE: spend energy credits -> equal 공명도 -> grade up (+inhesion +augment).
	_resonate = Button.new()
	_resonate.add_theme_font_size_override("font_size", 20)
	_resonate.anchor_left = 0.5
	_resonate.anchor_right = 0.5
	_resonate.anchor_top = 1.0
	_resonate.anchor_bottom = 1.0
	_resonate.offset_left = -120.0
	_resonate.offset_right = 120.0
	_resonate.offset_top = -150.0
	_resonate.offset_bottom = -94.0
	add_child(_resonate)
	_resonate.pressed.connect(_on_resonate_pressed)

	_btn.pressed.connect(_on_start_combat_pressed)

	var bf: Node = get_parent().get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_signal("phase_changed"):
		bf.phase_changed.connect(_on_phase_changed)
	var reso: Node = get_parent().get_parent().get_node_or_null("Resonance")
	if reso != null and reso.has_signal("credits_changed"):
		reso.credits_changed.connect(_on_credits_changed)
	_update_resonate()


func _on_start_combat_pressed() -> void:
	var bf: Node = get_parent().get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_method("start_combat"):
		bf.start_combat()


func _on_phase_changed(new_phase: int) -> void:
	visible = new_phase == 0
	if new_phase == 0:
		_update_resonate()


func _on_credits_changed(_credits: int) -> void:
	_update_resonate()


func _on_resonate_pressed() -> void:
	var main: Node = get_parent().get_parent()
	var reso: Node = main.get_node_or_null("Resonance")
	if reso == null or not reso.has_method("resonate_all"):
		return
	var gained: int = reso.resonate_all()
	if gained > 0:
		var bf: Node = main.get_node_or_null("BattleField")
		if bf != null and bf.has_method("apply_inhesion_for_grade"):
			bf.apply_inhesion_for_grade(reso.current_grade())
		var aug: Node = main.get_node_or_null("AugmentSystem")
		if aug != null and aug.has_method("show_menu"):
			aug.show_menu(3)
	_update_resonate()


func _update_resonate() -> void:
	if _resonate == null:
		return
	var reso: Node = get_parent().get_parent().get_node_or_null("Resonance")
	var c: int = 0
	if reso != null:
		c = int(reso.get("credits"))
	_resonate.text = "공명 (%dc)" % c
	_resonate.disabled = c <= 0


func refresh() -> void:
	_update_resonate()
