extends Control
## 준비/전투 상호작용: 배치 구역 + 대기실(bench) 표시, 유닛 드래그 배치(준비 단계),
## 기물 탭 시 정보 패널(능력치 + 고유 특성 + 서브클래스 기술/메커니즘 + 현재 버프) 표시.
## 정보는 전투 중에도 탭으로 확인 가능(버프 확인용). 루트는 IGNORE → 빈 곳 클릭만 여기로.

const DEPLOY := Rect2(252.0, 116.0, 352.0, 384.0)
const BENCH := Rect2(252.0, 512.0, 352.0, 80.0)
const PICK_RADIUS := 34.0

var _bf: Node = null
var _selected: Node = null
var _dragging: Node = null
var _drag_offset: Vector2 = Vector2.ZERO
var _arranged: bool = false
var _is_prep: bool = true

var _info_bg: ColorRect
var _info_rt: RichTextLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_info_panel()
	_bf = get_node_or_null("../../BattleField")
	if _bf != null and _bf.has_signal("phase_changed"):
		_bf.phase_changed.connect(_on_phase_changed)
	set_process(true)
	call_deferred("_try_arrange")


func _build_info_panel() -> void:
	_info_bg = ColorRect.new()
	_info_bg.color = Color(0.04, 0.05, 0.08, 0.90)
	_info_bg.position = Vector2(6.0, 106.0)
	_info_bg.size = Vector2(238.0, 516.0)
	_info_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_bg.visible = false
	add_child(_info_bg)

	_info_rt = RichTextLabel.new()
	_info_rt.bbcode_enabled = true
	_info_rt.scroll_active = true
	_info_rt.position = Vector2(16.0, 114.0)
	_info_rt.size = Vector2(220.0, 500.0)
	_info_rt.add_theme_font_size_override("normal_font_size", 14)
	_info_rt.add_theme_font_size_override("bold_font_size", 15)
	_info_rt.mouse_filter = Control.MOUSE_FILTER_PASS
	_info_rt.visible = false
	add_child(_info_rt)


func _process(_dt: float) -> void:
	# Keep buffs/stats live while a unit is selected (combat).
	if _selected != null and is_instance_valid(_selected) and _info_rt.visible:
		_update_info()


func _on_phase_changed(phase: int) -> void:
	_is_prep = (phase == 0)
	if _is_prep:
		_try_arrange()
	else:
		_dragging = null
	queue_redraw()


func _try_arrange() -> void:
	if _arranged or _bf == null or not _bf.has_method("units_of"):
		return
	var players: Array = _bf.units_of(0)
	if players.is_empty():
		return
	for i in players.size():
		var u: Node = players[i]
		u.set("benched", false)
		u.global_position = Vector2(DEPLOY.position.x + 88.0 + float(i % 2) * 150.0, DEPLOY.position.y + 70.0 + float(i / 2) * 96.0)
	_arranged = true
	queue_redraw()


func _player_units() -> Array:
	if _bf != null and _bf.has_method("units_of"):
		return _bf.units_of(0)
	return []


func _pick_unit(pos: Vector2) -> Node:
	var best: Node = null
	var best_d: float = PICK_RADIUS
	for u in _player_units():
		var d: float = u.global_position.distance_to(pos)
		if d <= best_d:
			best_d = d
			best = u
	return best


func _event_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return event.position
	return Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	var pressed_evt: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	var released_evt: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) or (event is InputEventScreenTouch and not event.pressed)
	var motion_evt: bool = (event is InputEventMouseMotion) or (event is InputEventScreenDrag)

	if pressed_evt:
		var u := _pick_unit(_event_pos(event))
		if u != null:
			_selected = u
			_update_info()
			queue_redraw()
			if _is_prep:   # drag only allowed during prep
				_dragging = u
				_drag_offset = u.global_position - _event_pos(event)
	elif released_evt:
		if _dragging != null:
			_dragging.set("benched", BENCH.has_point(_dragging.global_position))
			_dragging = null
			_update_info()
			queue_redraw()
	elif motion_evt and _dragging != null and _is_prep:
		var p := _event_pos(event) + _drag_offset
		p.x = clampf(p.x, DEPLOY.position.x + 24.0, DEPLOY.position.x + DEPLOY.size.x - 24.0)
		p.y = clampf(p.y, DEPLOY.position.y + 24.0, BENCH.position.y + BENCH.size.y - 16.0)
		_dragging.global_position = p
		queue_redraw()


func _update_info() -> void:
	var show := _selected != null and is_instance_valid(_selected)
	_info_bg.visible = show
	_info_rt.visible = show
	if not show:
		return
	var u := _selected
	var cid: String = String(u.sprite_id)
	var sid: String = String(u.subclass_id)
	var cl: Dictionary = LoreData.class_lore(cid)
	var spd: float = (1.0 / float(u.attack_interval)) if float(u.attack_interval) > 0.0 else 0.0
	var t: Array = []
	var sub_label: String = ClassData.subclass_label(cid, sid) if sid != "" else "서브클래스 미선택"
	t.append("[b]%s · %s[/b]" % [ClassData.class_label(cid), sub_label])
	t.append("공명 등급 %d   %s" % [int(u.current_res_grade()), "[대기]" if bool(u.get("benched")) else "[배치]"])
	t.append("")
	t.append("체력 %d/%d   공격력 %d" % [int(u.hp), int(u.max_hp), int(u.attack)])
	t.append("공속 %.2f/s   사거리 %d   방어도 %d" % [spd, int(round(float(u.attack_range))), int(u.armor)])

	# 고유 특성
	if not cl.is_empty():
		t.append("")
		t.append("[b]고유 특성 — %s[/b]" % String(cl.get("trait_name", "")))
		if cl.has("trait"):
			t.append(String(cl["trait"]))
		if cl.has("base"):
			t.append("[color=#9fb0c8]%s[/color]" % String(cl["base"]))

	# 서브클래스 기술 + 메커니즘
	if sid != "":
		var sl: Dictionary = LoreData.sub_lore(cid, sid)
		t.append("")
		t.append(_skill_block(u, sl))
		if sl.has("tiers"):
			t.append("[b]서브클래스 메커니즘[/b]")
			var tier_now: int = int(u.inhesion_tier)
			for i in (sl["tiers"] as Array).size():
				var mark: String = "✓" if i < tier_now else "·"
				t.append("[color=#c8b86a]고유%d %s[/color] %s" % [i + 1, mark, String(sl["tiers"][i])])
	else:
		t.append("")
		t.append("[color=#9fb0c8]공명 등급 2에서 서브클래스를 선택합니다.[/color]")

	# 현재 버프 (전투 중)
	if u.has_method("buff_summary"):
		var buffs: Array = u.buff_summary()
		if not buffs.is_empty():
			t.append("")
			t.append("[b]현재 상태[/b]")
			t.append("[color=#8fd6a0]%s[/color]" % ", ".join(buffs))

	_info_rt.text = "\n".join(t)


func _skill_block(u: Node, sl: Dictionary) -> String:
	var ab: Node = u.get_node_or_null("Ability")
	var cost: String = ""
	if ab != null:
		var sid: String = String(ab.get("ability_id"))
		var stype: String = String(ab.get("skill_type"))
		if sid != "":
			if stype == "general":
				cost = " (쿨 %.0f초)" % float(ab.get("cooldown"))
			elif stype == "special":
				cost = " (충전 %dpt)" % int(ab.get("charge_req"))
	var nm: String = String(sl.get("skill_name", ""))
	if nm == "":
		# 패시브 클래스: 기술 대신 고유 특성으로 동작
		return "[b]기술[/b]\n[color=#9fb0c8]고유 특성 기반 (액티브 기술 없음)[/color]\n"
	var out: String = "[b]기술 — %s%s[/b]\n" % [nm, cost]
	if sl.has("skill"):
		out += String(sl["skill"]) + "\n"
	return out


func _draw() -> void:
	if _is_prep:
		draw_rect(DEPLOY, Color(0.25, 0.7, 0.4, 0.10), true)
		draw_rect(DEPLOY, Color(0.35, 0.85, 0.5, 0.55), false, 2.0)
		draw_rect(BENCH, Color(0.7, 0.6, 0.25, 0.10), true)
		draw_rect(BENCH, Color(0.9, 0.75, 0.35, 0.55), false, 2.0)
		var font := ThemeDB.fallback_font
		draw_string(font, DEPLOY.position + Vector2(8.0, 20.0), "배치 구역", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 1.0, 0.7, 0.8))
		draw_string(font, BENCH.position + Vector2(8.0, 20.0), "대기실", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.55, 0.8))
	if _selected != null and is_instance_valid(_selected):
		draw_arc(_selected.global_position, 30.0, 0.0, TAU, 32, Color(1.0, 0.95, 0.4, 0.9), 2.5)
