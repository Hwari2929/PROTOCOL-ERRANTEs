extends Node
## 증강 시스템 — MAJOR 증강 풀 + 3택 선택 UI + 적용.
## On a resonance grade-up the player picks 1 of 3 MAJOR augments, applied to the
## living player team (team 0). Unit stat vars are written via set() (unit.gd has
## no class_name).

const AUGMENTS: Array = [
	{"id": "impact",   "label": "충격 증폭",     "desc": "피해 +30%"},
	{"id": "keen_aim", "label": "날카로운 조준", "desc": "공격력 +20%"},
	{"id": "sturdy",   "label": "강건함",         "desc": "최대 체력 +15%, 방어도 +2"},
	{"id": "bulwark",  "label": "불굴의 의지",    "desc": "방어도 +5"},
	{"id": "agile",    "label": "기민한 사수",    "desc": "이동 속도 +25%"},
	{"id": "mastery",  "label": "반복 숙달",      "desc": "공격 속도 +18%"},
]

var _layer: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func pool_size() -> int:
	return AUGMENTS.size()


## n DISTINCT random augments (clamped to the pool size).
func roll_choices(n: int) -> Array:
	var available: Array = AUGMENTS.duplicate()
	available.shuffle()
	var count: int = mini(n, available.size())
	return available.slice(0, count)


func apply_augment(id: String) -> void:
	for u in get_tree().get_nodes_in_group("unit"):
		if int(u.get("team")) != 0:
			continue
		match id:
			"impact":
				u.set("attack", int(round(float(u.get("attack")) * 1.3)))
			"keen_aim":
				u.set("attack", int(round(float(u.get("attack")) * 1.2)))
			"sturdy":
				u.set("max_hp", int(round(float(u.get("max_hp")) * 1.15)))
				u.set("hp", int(round(float(u.get("hp")) * 1.15)))
				u.set("armor", int(u.get("armor")) + 2)
			"bulwark":
				u.set("armor", int(u.get("armor")) + 5)
			"agile":
				u.set("move_speed", float(u.get("move_speed")) * 1.25)
			"mastery":
				u.set("attack_interval", maxf(0.2, float(u.get("attack_interval")) * 0.82))


## Build one button per rolled choice and pause until the player picks.
func show_menu(n: int) -> void:
	var choices: Array = roll_choices(n)
	if choices.is_empty():
		return
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = CanvasLayer.new()
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.position = Vector2(440.0, 240.0)
	vbox.add_theme_constant_override("separation", 12)
	_layer.add_child(vbox)

	var title: Label = Label.new()
	title.text = "증강 선택 (1택)"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	for c in choices:
		var btn: Button = Button.new()
		btn.text = "%s — %s" % [c["label"], c["desc"]]
		btn.custom_minimum_size = Vector2(360.0, 56.0)
		btn.add_theme_font_size_override("font_size", 20)
		var cid: String = c["id"]
		btn.pressed.connect(func() -> void: _on_pick(cid))
		vbox.add_child(btn)

	get_tree().paused = true


func _on_pick(id: String) -> void:
	apply_augment(id)
	get_tree().paused = false
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
		_layer = null
