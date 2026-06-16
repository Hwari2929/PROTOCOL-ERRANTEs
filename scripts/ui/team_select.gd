extends Control

var _selected_ids: Array[String] = []
const MAX_SELECTION: int = 3
const DEFAULT_TEAM: Array[String] = ["protagonist", "ranger", "vanguard"]
const CLASS_LIST: Array[String] = ["protagonist", "ranger", "vanguard", "commander", "medic"]

var _confirm_button: Button
var _vbox: VBoxContainer

func _ready() -> void:
	_build_ui()
	# Pre-select default trio
	for team_id in DEFAULT_TEAM:
		var btn: Button = _vbox.get_node_or_null(team_id) as Button
		if btn != null:
			btn.button_pressed = true
	refresh()

func _build_ui() -> void:
	# Semi-transparent full-rect background
	var bg: ColorRect = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	# Centred VBoxContainer
	_vbox = VBoxContainer.new()
	_vbox.name = "TeamSelectVBox"
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 8)
	# Centre the panel on screen.
	_vbox.anchor_left = 0.5
	_vbox.anchor_top = 0.5
	_vbox.anchor_right = 0.5
	_vbox.anchor_bottom = 0.5
	_vbox.offset_left = -130.0
	_vbox.offset_right = 130.0
	_vbox.offset_top = -170.0
	_vbox.offset_bottom = 170.0
	add_child(_vbox)
	
	# Title
	var title: Label = Label.new()
	title.name = "Title"
	title.text = "SELECT YOUR TEAM (3)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)
	
	# Team toggle buttons
	for team_id in CLASS_LIST:
		var btn: Button = Button.new()
		btn.name = team_id
		btn.text = team_id.capitalize()
		btn.toggle_mode = true
		btn.add_theme_font_size_override("font_size", 16)
		btn.toggled.connect(_on_team_toggled.bind(team_id, btn))
		_vbox.add_child(btn)
		
	# Confirm button
	_confirm_button = Button.new()
	_confirm_button.name = "ConfirmButton"
	_confirm_button.text = "CONFIRM"
	_confirm_button.disabled = true
	_confirm_button.add_theme_font_size_override("font_size", 18)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_vbox.add_child(_confirm_button)

func _on_team_toggled(pressed: bool, team_id: String, btn: Button) -> void:
	if pressed:
		if _selected_ids.size() >= MAX_SELECTION:
			# Enforce maximum: ignore toggle and revert button state
			btn.button_pressed = false
			return
		_selected_ids.append(team_id)
	else:
		_selected_ids.erase(team_id)
	refresh()

func refresh() -> void:
	# Recompute CONFIRM enabled state
	_confirm_button.disabled = (_selected_ids.size() != MAX_SELECTION)

func selected_ids() -> Array[String]:
	return _selected_ids.duplicate()

func _on_confirm_pressed() -> void:
	if _selected_ids.size() != MAX_SELECTION:
		return
		
	var battle_field: Node = get_parent().get_parent().get_node_or_null("BattleField")
	if battle_field != null and battle_field.has_method("set_player_team"):
		battle_field.set_player_team(_selected_ids)
		
	visible = false