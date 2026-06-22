extends Control
## 공명 등급 2 도달 시 서브클래스 선택 메뉴. 트리를 일시정지하고 위에 띄운다.
## 선택할 때까지 닫히지 않으며, 선택 후 일시정지를 해제한다.

var _menu_layer: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_for(unit: Node) -> void:
	if _menu_layer != null and is_instance_valid(_menu_layer):
		_menu_layer.queue_free()
		_menu_layer = null

	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 60
	_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg := ColorRect.new()
	bg.color = Color(Palette.INK0, 0.66)   # 잉크 딤
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_layer.add_child(bg)

	# 종이 카드 패널.
	var card := Panel.new()
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -224.0
	card.offset_right = 224.0
	card.offset_top = -180.0
	card.offset_bottom = 180.0
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	bg.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -200.0
	vbox.offset_right = 200.0
	vbox.offset_top = -160.0
	vbox.offset_bottom = 160.0
	vbox.add_theme_constant_override("separation", 14)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	bg.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "%s — 서브클래스 선택" % ClassData.class_label(unit.sprite_id)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Palette.ACCENT)
	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(title_label)

	for sub_id in ClassData.subclass_ids(unit.sprite_id):
		var sid: String = String(sub_id)
		var btn := Button.new()
		btn.text = ClassData.subclass_label(unit.sprite_id, sid)
		btn.custom_minimum_size = Vector2(380.0, 60.0)
		btn.add_theme_font_size_override("font_size", 22)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_subclass_selected.bind(sid, unit))
		vbox.add_child(btn)

	get_tree().root.add_child(_menu_layer)
	get_tree().paused = true


func _on_subclass_selected(sub_id: String, unit: Node) -> void:
	if unit != null and unit.has_method("set_subclass"):
		unit.set_subclass(sub_id)
	if _menu_layer != null and is_instance_valid(_menu_layer):
		_menu_layer.queue_free()
		_menu_layer = null
	get_tree().paused = false


func is_open() -> bool:
	return _menu_layer != null and is_instance_valid(_menu_layer)
