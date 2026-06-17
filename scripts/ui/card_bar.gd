extends Control
## Tactical card hand UI — shown during PREP. Displays TP and the 3-card hand;
## clicking an affordable card plays it (applies to the player team).

var _tp_label: Label
var _hbox: HBoxContainer
var _deck: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # let drag input reach units

	_tp_label = Label.new()
	_tp_label.add_theme_font_size_override("font_size", 18)
	_tp_label.position = Vector2(16.0, 96.0)
	add_child(_tp_label)

	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 8)
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 0.0
	_hbox.anchor_top = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_left = 16.0
	_hbox.offset_right = 490.0
	_hbox.offset_top = -118.0
	_hbox.offset_bottom = -14.0
	add_child(_hbox)

	var main: Node = get_parent().get_parent()
	_deck = main.get_node_or_null("TacticalDeck")
	if _deck != null:
		_deck.hand_changed.connect(_on_hand_changed)
		_deck.tp_changed.connect(_on_tp_changed)
	var bf: Node = main.get_node_or_null("BattleField")
	if bf != null and bf.has_signal("phase_changed"):
		bf.phase_changed.connect(_on_phase_changed)
	_refresh()


func _on_phase_changed(new_phase: int) -> void:
	visible = new_phase == 0


func _on_hand_changed(_hand: Array) -> void:
	_refresh()


func _on_tp_changed(_tp: int) -> void:
	_refresh()


func _refresh() -> void:
	if _deck == null:
		return
	_tp_label.text = "Tactical Points: %d" % int(_deck.get_tp())
	for c in _hbox.get_children():
		c.queue_free()
	var hand: Array = _deck.get_hand()
	for i in hand.size():
		var card: Dictionary = hand[i]
		var cost: int = int(card.get("cost", 1))
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(150.0, 96.0)
		b.add_theme_font_size_override("font_size", 13)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.text = "%s\n(%d TP)\n%s" % [String(card.get("id", "")).capitalize(), cost, String(card.get("desc", ""))]
		b.disabled = int(_deck.get_tp()) < cost
		var idx: int = i
		b.pressed.connect(func() -> void: _deck.play_card(idx))
		_hbox.add_child(b)
