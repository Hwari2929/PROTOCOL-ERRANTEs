extends Node
## 증강 시스템 — MAJOR 증강 풀 + 3택 선택 UI + 적용.
## On a resonance grade-up the player picks 1 of 3 MAJOR augments, applied to the
## living player team (team 0). Unit stat vars are written via set() (unit.gd has
## no class_name).

const AUGMENTS: Array = [
	{"id": "impact",       "label": "충격 증폭",     "desc": "피해 +30%",          "effect": {"attack_mult": 1.30}},
	{"id": "keen_aim",     "label": "날카로운 조준", "desc": "공격력 +8",          "effect": {"attack_add": 8}},
	{"id": "sturdy",       "label": "강건함",         "desc": "최대 체력 +15%, 방어도 +2", "effect": {"max_hp_mult": 1.15, "armor_add": 2}},
	{"id": "bulwark",      "label": "불굴의 의지",    "desc": "방어도 +5",          "effect": {"armor_add": 5}},
	{"id": "agile",        "label": "기민한 사수",    "desc": "이동 속도 +25%",     "effect": {"move_speed_mult": 1.25}},
	{"id": "mastery",      "label": "반복 숙달",      "desc": "공격 속도 +18%",     "effect": {"attack_interval_mult": 0.82}},
	{"id": "overcharge",   "label": "과충전",         "desc": "스킬 위력 +30%",     "effect": {"skill_power_mult": 1.30}},
	{"id": "rapid_skills", "label": "신속 시전",      "desc": "스킬 쿨 -20%",       "effect": {"skill_cd_mult": 0.80}},
	{"id": "marksman",     "label": "명사수",         "desc": "사거리 +60, 공격 +10%", "effect": {"attack_range_add": 60.0, "attack_mult": 1.10}},
	{"id": "juggernaut",   "label": "파쇄기",         "desc": "최대 체력 +25%, 방어도 +4", "effect": {"max_hp_mult": 1.25, "armor_add": 4}},
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
	var effect: Dictionary = {}
	for a in AUGMENTS:
		if String(a["id"]) == id:
			effect = a["effect"]
			break
	if effect.is_empty():
		return
	for u in get_tree().get_nodes_in_group("unit"):
		if int(u.get("team")) == 0:
			ClassData.apply_mods(u, effect)


## Build one button per rolled choice and pause until the player picks.
func show_menu(n: int) -> void:
	var choices: Array = roll_choices(n)
	if choices.is_empty():
		return
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = CanvasLayer.new()
	_layer.layer = 50  # above all other UI
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP  # block clicks behind
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.add_child(bg)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -230.0
	vbox.offset_right = 230.0
	vbox.offset_top = -150.0
	vbox.offset_bottom = 150.0
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	bg.add_child(vbox)

	var title: Label = Label.new()
	title.text = "증강 선택 (1택)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	for c in choices:
		var btn: Button = Button.new()
		btn.text = "%s — %s" % [String(c["label"]), String(c["desc"])]
		btn.custom_minimum_size = Vector2(440.0, 56.0)
		btn.add_theme_font_size_override("font_size", 20)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		var cid: String = String(c["id"])
		btn.pressed.connect(func() -> void: _on_pick(cid))
		vbox.add_child(btn)

	get_tree().paused = true


func _on_pick(id: String) -> void:
	apply_augment(id)
	get_tree().paused = false
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
		_layer = null
