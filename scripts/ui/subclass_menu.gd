extends Control

var _menu_layer: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func show_for(unit: Node) -> void:
	if _menu_layer:
		_menu_layer.queue_free()
		_menu_layer = null

	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 55
	_menu_layer.name = "SubclassMenuLayer"

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_menu_layer.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	bg.add_child(vbox)

	var title_label := Label.new()
	title_label.name = "Title"
	title_label.text = "서브클래스 선택"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)

	var sub_ids: Array = ClassData.subclass_ids(unit.sprite_id)
	for sub_id in sub_ids:
		var btn := Button.new()
		btn.name = "Subclass_" + str(sub_id)
		btn.text = ClassData.subclass_label(unit.sprite_id, sub_id)
		btn.add_theme_font_size_override("font_size", 20)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_subclass_selected.bind(sub_id, unit))
		vbox.add_child(btn)

	get_tree().root.add_child(_menu_layer)
	visible = false

func _on_subclass_selected(sub_id: int, unit: Node) -> void:
	if unit and unit.has_method("set_subclass"):
		unit.set_subclass(sub_id)
	get_tree().paused = false
	if _menu_layer:
		_menu_layer.queue_free()
		_menu_layer = null
	get_tree().paused = true

func is_open() -> bool:
	return _menu_layer != null