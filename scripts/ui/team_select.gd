extends Control
## Team selection: pick 3 of 5 classes and choose each one's subclass, then CONFIRM.
## In-engine labels use English ids (default font has no Hangul); Korean labels live in
## ClassData for when the font cycle lands.

const MAX_SELECTION: int = 3
const DEFAULT_TEAM: Array[String] = ["protagonist", "ranger", "vanguard"]
const CLASS_LIST: Array[String] = ["protagonist", "ranger", "vanguard", "commander", "medic"]

var _selected_ids: Array[String] = []
var _subclass_choice: Dictionary = {}    # class_id -> subclass_id
var _weapon_choice: Dictionary = {}      # class_id -> weapon_id
var _class_buttons: Dictionary = {}      # class_id -> Button (toggle)
var _sub_buttons: Dictionary = {}        # class_id -> Button (cycle)
var _weapon_buttons: Dictionary = {}     # class_id -> Button (cycle)
var _confirm_button: Button
var _vbox: VBoxContainer


func _ready() -> void:
	_build_ui()
	for team_id in DEFAULT_TEAM:
		var btn: Button = _class_buttons.get(team_id)
		if btn != null:
			btn.button_pressed = true
	refresh()


func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 8)
	_vbox.anchor_left = 0.5
	_vbox.anchor_top = 0.5
	_vbox.anchor_right = 0.5
	_vbox.anchor_bottom = 0.5
	_vbox.offset_left = -270.0
	_vbox.offset_right = 270.0
	_vbox.offset_top = -200.0
	_vbox.offset_bottom = 200.0
	add_child(_vbox)

	var title: Label = Label.new()
	title.text = "팀 편성 (3명)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	_vbox.add_child(title)

	for class_id in CLASS_LIST:
		_subclass_choice[class_id] = ClassData.default_subclass(class_id)
		_weapon_choice[class_id] = ItemData.default_for(class_id)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_vbox.add_child(row)

		var cbtn: Button = Button.new()
		cbtn.text = ClassData.class_label(class_id)
		cbtn.toggle_mode = true
		cbtn.custom_minimum_size = Vector2(130.0, 36.0)
		cbtn.add_theme_font_size_override("font_size", 15)
		cbtn.toggled.connect(_on_class_toggled.bind(class_id))
		row.add_child(cbtn)
		_class_buttons[class_id] = cbtn

		var sbtn: Button = Button.new()
		sbtn.custom_minimum_size = Vector2(120.0, 36.0)
		sbtn.add_theme_font_size_override("font_size", 13)
		sbtn.pressed.connect(_on_subclass_cycle.bind(class_id))
		row.add_child(sbtn)
		_sub_buttons[class_id] = sbtn
		_update_sub_button(class_id)

		var wbtn: Button = Button.new()
		wbtn.custom_minimum_size = Vector2(130.0, 36.0)
		wbtn.add_theme_font_size_override("font_size", 13)
		wbtn.pressed.connect(_on_weapon_cycle.bind(class_id))
		row.add_child(wbtn)
		_weapon_buttons[class_id] = wbtn
		_update_weapon_button(class_id)

	_confirm_button = Button.new()
	_confirm_button.text = "확정"
	_confirm_button.disabled = true
	_confirm_button.custom_minimum_size = Vector2(0.0, 40.0)
	_confirm_button.add_theme_font_size_override("font_size", 18)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_vbox.add_child(_confirm_button)


func _on_class_toggled(pressed: bool, class_id: String) -> void:
	if pressed:
		if _selected_ids.size() >= MAX_SELECTION:
			var b: Button = _class_buttons.get(class_id)
			if b != null:
				b.button_pressed = false
			return
		if not _selected_ids.has(class_id):
			_selected_ids.append(class_id)
	else:
		_selected_ids.erase(class_id)
	refresh()


func _on_subclass_cycle(class_id: String) -> void:
	var subs: Array = ClassData.subclass_ids(class_id)
	if subs.size() <= 1:
		return
	var cur: String = String(_subclass_choice.get(class_id, ""))
	var idx: int = subs.find(cur)
	idx = (idx + 1) % subs.size()
	_subclass_choice[class_id] = subs[idx]
	_update_sub_button(class_id)


func _update_sub_button(class_id: String) -> void:
	var sbtn: Button = _sub_buttons.get(class_id)
	if sbtn == null:
		return
	var sub_id: String = String(_subclass_choice.get(class_id, ""))
	sbtn.text = ClassData.subclass_label(class_id, sub_id)


func _on_weapon_cycle(class_id: String) -> void:
	var ws: Array = ItemData.weapon_ids()
	if ws.size() <= 1:
		return
	var cur: String = String(_weapon_choice.get(class_id, ""))
	var idx: int = ws.find(cur)
	idx = (idx + 1) % ws.size()
	_weapon_choice[class_id] = ws[idx]
	_update_weapon_button(class_id)


func _update_weapon_button(class_id: String) -> void:
	var wbtn: Button = _weapon_buttons.get(class_id)
	if wbtn == null:
		return
	wbtn.text = "무기: " + ItemData.weapon_label(String(_weapon_choice.get(class_id, "")))


func selected_weapons() -> Dictionary:
	var out: Dictionary = {}
	for id in _selected_ids:
		out[id] = _weapon_choice.get(id, ItemData.default_for(id))
	return out


func refresh() -> void:
	if _confirm_button != null:
		_confirm_button.disabled = (_selected_ids.size() != MAX_SELECTION)


func selected_ids() -> Array:
	return _selected_ids.duplicate()


func selected_subclasses() -> Dictionary:
	var out: Dictionary = {}
	for id in _selected_ids:
		out[id] = _subclass_choice.get(id, ClassData.default_subclass(id))
	return out


func _on_confirm_pressed() -> void:
	if _selected_ids.size() != MAX_SELECTION:
		return
	var bf: Node = get_parent().get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_method("set_player_team"):
		bf.set_player_team(_selected_ids, selected_subclasses(), selected_weapons())
	visible = false
