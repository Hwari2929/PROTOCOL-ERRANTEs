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

var _info_bg: Panel
var _info_rt: RichTextLabel
var _upgrade_box: VBoxContainer
var _based_engineers: Dictionary = {}   # engineer instance_id → base spawned


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_info_panel()
	_bf = get_node_or_null("../../BattleField")
	if _bf != null and _bf.has_signal("phase_changed"):
		_bf.phase_changed.connect(_on_phase_changed)
	# Team change frees old team-0 units (incl. facility bases) → re-arrange + respawn bases.
	if EventBus.has_signal("team_changed"):
		EventBus.team_changed.connect(func(_ids):
			_arranged = false
			_based_engineers.clear()
			call_deferred("_try_arrange"))
	set_process(true)
	call_deferred("_try_arrange")


func _build_info_panel() -> void:
	_info_bg = Panel.new()
	_info_bg.add_theme_stylebox_override("panel", Palette.card_face(Palette.R_MD, Vector2(3, 3)))
	_info_bg.position = Vector2(6.0, 106.0)
	_info_bg.size = Vector2(238.0, 516.0)
	_info_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_bg.visible = false
	# BINDER 재질: 상단 마스킹 테이프.
	var tape := Decor.tape(72.0, 24.0, -6.0)
	tape.position = Vector2(14.0, -12.0)
	_info_bg.add_child(tape)
	add_child(_info_bg)

	_info_rt = RichTextLabel.new()
	_info_rt.bbcode_enabled = true
	_info_rt.scroll_active = true
	_info_rt.position = Vector2(16.0, 114.0)
	_info_rt.size = Vector2(220.0, 500.0)
	_info_rt.add_theme_font_size_override("normal_font_size", 14)
	_info_rt.add_theme_font_size_override("bold_font_size", 15)
	_info_rt.add_theme_color_override("default_color", Palette.INK0)
	_info_rt.mouse_filter = Control.MOUSE_FILTER_PASS
	_info_rt.visible = false
	add_child(_info_rt)

	# 시설 기반 업그레이드 버튼 패널 (시설 기반 선택 시 표시).
	_upgrade_box = VBoxContainer.new()
	_upgrade_box.position = Vector2(640.0, 116.0)
	_upgrade_box.add_theme_constant_override("separation", 8)
	_upgrade_box.visible = false
	add_child(_upgrade_box)
	var ttl := Label.new()
	ttl.text = "시설 업그레이드"
	ttl.add_theme_font_size_override("font_size", 18)
	_upgrade_box.add_child(ttl)
	for opt in [["turret", "감시 포탑"], ["wall", "방벽 방패"], ["tesla", "테슬라 포탑"]]:
		var b := Button.new()
		b.text = String(opt[1])
		b.custom_minimum_size = Vector2(180.0, 44.0)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_upgrade_pressed.bind(String(opt[0])))
		_upgrade_box.add_child(b)


func _process(_dt: float) -> void:
	# Keep buffs/stats live while a unit is selected (combat).
	if _selected != null and is_instance_valid(_selected) and _info_rt.visible:
		_update_info()


func _on_phase_changed(phase: int) -> void:
	_is_prep = (phase == 0)
	if _is_prep:
		_try_arrange()
	else:
		# 전투 진입: 드래그/선택 해제 + 정보·업그레이드 패널 숨김(선택 링 잔상 방지).
		_dragging = null
		_selected = null
		_update_info()
		if _upgrade_box != null:
			_upgrade_box.visible = false
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
	# 엔지니어마다 시설 기반을 배치 (전투 전 업그레이드 가능).
	for u in players:
		if String(u.get("sprite_id")) == "engineer":
			_spawn_facility_base(u)
	_arranged = true
	queue_redraw()


func _spawn_facility_base(eng: Node) -> void:
	if _bf == null or not _bf.has_method("spawn_minion"):
		return
	var eid: int = eng.get_instance_id()
	if _based_engineers.has(eid):
		return
	_based_engineers[eid] = true
	var a: int = int(eng.get("attack"))
	var stats: Dictionary = {"max_hp": a * 4, "attack": 0, "attack_interval": 2.0, "attack_range": 0.0, "move_speed": 0.0, "armor": a * 2}
	var pos: Vector2 = eng.global_position + Vector2(70.0, 0.0)
	pos.x = clampf(pos.x, DEPLOY.position.x + 24.0, DEPLOY.position.x + DEPLOY.size.x - 24.0)
	var base: Node = _bf.spawn_minion(0, pos, stats, "facility_base")
	if base != null:
		base.set("facility_kind", "base")
		base.set("facility_owner_atk", a)


func _on_upgrade_pressed(kind: String) -> void:
	if _selected == null or not is_instance_valid(_selected):
		return
	if String(_selected.get("facility_kind")) == "":
		return
	var a: int = int(_selected.get("facility_owner_atk"))
	if a <= 0:
		a = 20
	var stats: Dictionary = {}
	if kind == "turret":
		stats = {"max_hp": a * 6, "attack": a, "attack_interval": 1.0, "attack_range": 200.0, "armor": a * 2}
	elif kind == "tesla":
		stats = {"max_hp": a * 6, "attack": a, "attack_interval": 1.0, "attack_range": 160.0, "armor": a * 2}
	elif kind == "wall":
		stats = {"max_hp": a * 10, "attack": 0, "attack_interval": 2.0, "attack_range": 0.0, "armor": a * 4}
	else:
		return
	for k in stats:
		_selected.set(k, stats[k])
	_selected.set("hp", int(stats["max_hp"]))
	_selected.set("sprite_id", kind)
	_selected.set("facility_kind", kind)
	if _selected.has_method("refresh_sprite"):
		_selected.refresh_sprite()
	_update_info()
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
	if _upgrade_box != null:
		_upgrade_box.visible = show and _is_prep and String(_selected.get("facility_kind")) == "base"
	if not show:
		return
	var u := _selected
	var cid: String = String(u.sprite_id)
	var sid: String = String(u.subclass_id)
	var spd: float = (1.0 / float(u.attack_interval)) if float(u.attack_interval) > 0.0 else 0.0

	# 특수 기물/시설 — 공명도 체계 없이 이름 + 능력치 + 상태만 표시.
	if bool(u.get("is_special")):
		var names: Dictionary = {
			"drone": "수색 드론", "beast": "동물 동료", "wraith": "망령",
			"turret": "감시 포탑", "tesla": "테슬라 포탑", "wall": "방벽",
			"phantom": "환조종", "facility_base": "시설 기반",
		}
		var kind_label: String = "시설" if cid in ["turret", "tesla", "wall", "facility_base"] else "특수 기물"
		var st: Array = []
		st.append("[b]%s[/b]  [color=#5c4d39](%s)[/color]" % [String(names.get(cid, "기물")), kind_label])
		st.append("내구도 %d/%d   공격력 %d" % [int(u.hp), int(u.max_hp), int(u.attack)])
		st.append("공속 %.2f/s   사거리 %d   방어도 %d" % [spd, int(round(float(u.attack_range))), int(u.armor)])
		st.append("[color=#5c4d39]공명도 미적용[/color]")
		if u.has_method("buff_summary"):
			var bf2: Array = u.buff_summary()
			if not bf2.is_empty():
				st.append("[b]현재 상태[/b]\n[color=#4d6a30]%s[/color]" % ", ".join(bf2))
		_info_rt.text = "\n".join(st)
		return

	var cl: Dictionary = LoreData.class_lore(cid)
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
			t.append("[color=#5c4d39]%s[/color]" % String(cl["base"]))

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
				t.append("[color=#8a662a]고유%d %s[/color] %s" % [i + 1, mark, String(sl["tiers"][i])])
	else:
		t.append("")
		t.append("[color=#5c4d39]공명 등급 2에서 서브클래스를 선택합니다.[/color]")

	# 현재 버프 (전투 중)
	if u.has_method("buff_summary"):
		var buffs: Array = u.buff_summary()
		if not buffs.is_empty():
			t.append("")
			t.append("[b]현재 상태[/b]")
			t.append("[color=#4d6a30]%s[/color]" % ", ".join(buffs))

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
		return "[b]기술[/b]\n[color=#5c4d39]고유 특성 기반 (액티브 기술 없음)[/color]\n"
	var out: String = "[b]기술 — %s%s[/b]\n" % [nm, cost]
	if sl.has("skill"):
		out += String(sl["skill"]) + "\n"
	return out


func _draw() -> void:
	if _is_prep:
		# 도면 느낌: 종이 위 잉크 테두리(배치 구역=잉크, 대기실=아카이브 레드).
		draw_rect(DEPLOY, Color(Palette.INK0, 0.05), true)
		draw_rect(DEPLOY, Color(Palette.INK0, 0.7), false, 2.0)
		draw_rect(BENCH, Color(Palette.ACCENT, 0.05), true)
		draw_rect(BENCH, Color(Palette.ACCENT, 0.6), false, 2.0)
		var font: Font = Palette.font(Palette.F_BODY)
		if font == null:
			font = ThemeDB.fallback_font
		draw_string(font, DEPLOY.position + Vector2(8.0, 20.0), "■ 배치 구역", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(Palette.INK0, 0.9))
		draw_string(font, BENCH.position + Vector2(8.0, 20.0), "□ 대기실", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(Palette.ACCENT, 0.9))
	if _selected != null and is_instance_valid(_selected):
		draw_arc(_selected.global_position, 30.0, 0.0, TAU, 32, Color(Palette.ACCENT, 0.95), 2.5)
