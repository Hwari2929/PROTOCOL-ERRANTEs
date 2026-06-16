extends Control
## 준비(배치) 페이즈 패널 — SCAFFOLD STUB. PB3 implements.
## Shows a START button + instructions during PREP; hidden during COMBAT.

func _ready() -> void:
	# Create Button
	var btn: Button = Button.new()
	btn.text = "START COMBAT"
	btn.add_theme_font_size_override("font_size", 20)
	btn.custom_minimum_size = Vector2(200, 50)
	btn.anchor_right = 0.5
	btn.anchor_bottom = 1.0
	btn.offset_left = -100.0
	btn.offset_right = 100.0
	btn.offset_bottom = -40.0
	add_child(btn)

	# Create Label
	var lbl: Label = Label.new()
	lbl.text = "Drag your units, then START"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(0, -100)
	lbl.custom_minimum_size = Vector2(300, 30)
	add_child(lbl)

	# Connect button pressed signal
	btn.pressed.connect(_on_start_combat_pressed)

	# Find BattleField sibling via guarded path lookup
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