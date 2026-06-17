extends Control
## Team selection: pick 3 of ALL classes (16 + protagonist) and choose each one's
## weapon, then CONFIRM. Subclass is chosen IN-RUN at resonance grade 2 (not here).
## Rows scroll. Korean labels from ClassData/ItemData.

const MAX_SELECTION: int = 3
const DEFAULT_TEAM: Array[String] = ["protagonist", "ranger", "vanguard"]

var _selected_ids: Array[String] = []
var _weapon_choice: Dictionary = {}      # class_id -> weapon_id
var _class_buttons: Dictionary = {}      # class_id -> Button (toggle)
var _weapon_buttons: Dictionary = {}     # class_id -> Button (cycle)
var _confirm_button: Button


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
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 8)
	outer.anchor_left = 0.5
	outer.anchor_top = 0.5
	outer.anchor_right = 0.5
	outer.anchor_bottom = 0.5
	outer.offset_left = -220.0
	outer.offset_right = 220.0
	outer.offset_top = -240.0
	outer.offset_bottom = 240.0
	add_child(outer)

	var title: Label = Label.new()
	title.text = "팀 편성 (3명)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	outer.add_child(title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430.0, 400.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	for class_id in ClassData.class_ids():
		_weapon_choice[class_id] = ItemData.default_for(class_id)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rows.add_child(row)

		var cbtn: Button = Button.new()
		cbtn.text = ClassData.class_label(class_id)
		cbtn.toggle_mode = true
		cbtn.custom_minimum_size = Vector2(150.0, 34.0)
		cbtn.add_theme_font_size_override("font_size", 15)
		cbtn.toggled.connect(_on_class_toggled.bind(class_id))
		row.add_child(cbtn)
		_class_buttons[class_id] = cbtn

		var wbtn: Button = Button.new()
		wbtn.custom_minimum_size = Vector2(160.0, 34.0)
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
	outer.add_child(_confirm_button)


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


func refresh() -> void:
	if _confirm_button != null:
		_confirm_button.disabled = (_selected_ids.size() != MAX_SELECTION)


func selected_ids() -> Array:
	return _selected_ids.duplicate()


## Subclass is chosen in-run at grade 2; none picked at team select.
func selected_subclasses() -> Dictionary:
	return {}


func selected_weapons() -> Dictionary:
	var out: Dictionary = {}
	for id in _selected_ids:
		out[id] = _weapon_choice.get(id, ItemData.default_for(id))
	return out


func _on_confirm_pressed() -> void:
	if _selected_ids.size() != MAX_SELECTION:
		return
	var bf: Node = get_parent().get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_method("set_player_team"):
		bf.set_player_team(_selected_ids, {}, selected_weapons())
	visible = false
