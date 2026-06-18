extends Control
## 준비 페이즈 상호작용 총괄: 배치 구역 + 대기실(bench) 표시, 유닛 드래그 배치,
## 탭하면 유닛 정보(능력치/기술/쿨다운/사거리/대상) 패널 표시.
## 루트는 MOUSE_FILTER_IGNORE → 카드/버튼은 각자 입력을 받고, 빈 곳 클릭만 여기로 떨어진다.

const DEPLOY := Rect2(244.0, 116.0, 360.0, 384.0)   # 배치 구역
const BENCH := Rect2(244.0, 512.0, 360.0, 80.0)     # 대기실
const PICK_RADIUS := 34.0

var _bf: Node = null
var _selected: Node = null
var _dragging: Node = null
var _drag_offset: Vector2 = Vector2.ZERO
var _arranged: bool = false
var _is_prep: bool = true

var _info_bg: ColorRect
var _info_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_info_panel()
	_bf = get_node_or_null("../../BattleField")
	if _bf != null and _bf.has_signal("phase_changed"):
		_bf.phase_changed.connect(_on_phase_changed)
	# arrange shortly after spawn (team may be set after _ready)
	call_deferred("_try_arrange")


func _build_info_panel() -> void:
	_info_bg = ColorRect.new()
	_info_bg.color = Color(0.05, 0.06, 0.09, 0.88)
	_info_bg.position = Vector2(8.0, 112.0)
	_info_bg.size = Vector2(228.0, 414.0)
	_info_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_bg.visible = false
	add_child(_info_bg)

	_info_label = Label.new()
	_info_label.position = Vector2(20.0, 124.0)
	_info_label.size = Vector2(208.0, 396.0)
	_info_label.add_theme_font_size_override("font_size", 16)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_label.visible = false
	add_child(_info_label)


func _on_phase_changed(phase: int) -> void:
	_is_prep = (phase == 0)
	if _is_prep:
		_try_arrange()
	else:
		_selected = null
		_dragging = null
	_update_info()
	queue_redraw()


## Lay out player units inside the deploy zone the first time we see them.
func _try_arrange() -> void:
	if _arranged or _bf == null or not _bf.has_method("units_of"):
		return
	var players: Array = _bf.units_of(0)
	if players.is_empty():
		return
	var n: int = players.size()
	for i in n:
		var u: Node = players[i]
		var col: int = i % 2
		var row: int = i / 2
		u.set("benched", false)
		u.global_position = Vector2(DEPLOY.position.x + 90.0 + float(col) * 150.0, DEPLOY.position.y + 70.0 + float(row) * 96.0)
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
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return event.position
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return event.position
	return Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not _is_prep:
		return
	var pressed_evt: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	var released_evt: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) or (event is InputEventScreenTouch and not event.pressed)
	var motion_evt: bool = (event is InputEventMouseMotion) or (event is InputEventScreenDrag)

	if pressed_evt:
		var pos := _event_pos(event)
		var u := _pick_unit(pos)
		if u != null:
			_selected = u
			_dragging = u
			_drag_offset = u.global_position - pos
			_update_info()
			queue_redraw()
	elif released_evt:
		if _dragging != null:
			# Drop: benched if inside the bench rect, else deployed.
			_dragging.set("benched", BENCH.has_point(_dragging.global_position))
			_dragging = null
			queue_redraw()
	elif motion_evt and _dragging != null:
		var p := _event_pos(event) + _drag_offset
		# clamp to the deploy ∪ bench column
		p.x = clampf(p.x, DEPLOY.position.x + 24.0, DEPLOY.position.x + DEPLOY.size.x - 24.0)
		p.y = clampf(p.y, DEPLOY.position.y + 24.0, BENCH.position.y + BENCH.size.y - 16.0)
		_dragging.global_position = p
		_update_info()
		queue_redraw()


func _update_info() -> void:
	var show := _is_prep and _selected != null and is_instance_valid(_selected)
	_info_bg.visible = show
	_info_label.visible = show
	if not show:
		return
	var u := _selected
	var cls: String = ClassData.class_label(u.sprite_id)
	var sub: String = ""
	if String(u.subclass_id) != "":
		sub = ClassData.subclass_label(u.sprite_id, u.subclass_id)
	var spd: float = 0.0
	if float(u.attack_interval) > 0.0:
		spd = 1.0 / float(u.attack_interval)
	var lines: Array = []
	lines.append("%s%s" % [cls, ("  ·  " + sub) if sub != "" else ""])
	lines.append("공명 등급 %d   %s" % [int(u.current_res_grade()), "[대기]" if bool(u.get("benched")) else "[배치]"])
	lines.append("")
	lines.append("체력      %d / %d" % [int(u.hp), int(u.max_hp)])
	lines.append("공격력    %d" % int(u.attack))
	lines.append("공격속도  %.2f /s" % spd)
	lines.append("사거리    %d" % int(round(float(u.attack_range))))
	lines.append("방어도    %d" % int(u.armor))
	lines.append("")
	lines.append(_skill_text(u))
	_info_label.text = "\n".join(lines)


func _skill_text(u: Node) -> String:
	var ab: Node = u.get_node_or_null("Ability")
	if ab == null:
		return "기술: 없음"
	var out: Array = []
	var sid: String = String(ab.get("ability_id"))
	if sid != "":
		out.append(_one_skill(sid, String(ab.get("skill_type")), ab))
	var cid: String = String(ab.get("class_ability_id"))
	if cid != "":
		out.append(_one_skill(cid, "special", ab))
	if out.is_empty():
		# 위치 기반 기본 스킬(레거시) — 패시브 클래스(센티넬/아비터 등)는 고유 특성으로 동작.
		var kind: String = ClassData.skill_for(u.sprite_id)
		var kmap: Dictionary = {"nova": "광역 폭발", "volley": "연사", "fortify": "요새화", "rally": "독려", "mend": "치유"}
		if kind != "":
			return "기술: %s (위치 기본기)" % String(kmap.get(kind, kind))
		return "기술: 고유 특성"
	return "\n".join(out)


func _one_skill(id: String, stype: String, ab: Node) -> String:
	var info: Dictionary = ClassData.ability_display(id)
	var nm: String = String(info.get("name", id))
	var cost: String = ""
	if stype == "general":
		cost = "쿨 %.0f초" % float(ab.get("cooldown"))
	elif stype == "special":
		cost = "충전 %dpt" % int(ab.get("class_charge_req") if id == String(ab.get("class_ability_id")) else ab.get("charge_req"))
	var tgt: String = String(info.get("target", "-"))
	var rng: String = String(info.get("range", "-"))
	return "기술: %s\n  %s · 대상 %s · 범위 %s" % [nm, cost, tgt, rng]


func _draw() -> void:
	if not _is_prep:
		return
	# 배치 구역
	draw_rect(DEPLOY, Color(0.25, 0.7, 0.4, 0.10), true)
	draw_rect(DEPLOY, Color(0.35, 0.85, 0.5, 0.55), false, 2.0)
	# 대기실
	draw_rect(BENCH, Color(0.7, 0.6, 0.25, 0.10), true)
	draw_rect(BENCH, Color(0.9, 0.75, 0.35, 0.55), false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, DEPLOY.position + Vector2(8.0, 20.0), "배치 구역", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 1.0, 0.7, 0.8))
	draw_string(font, BENCH.position + Vector2(8.0, 20.0), "대기실", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.55, 0.8))
	# 선택 표시
	if _selected != null and is_instance_valid(_selected):
		draw_arc(_selected.global_position, 30.0, 0.0, TAU, 32, Color(1.0, 0.95, 0.4, 0.9), 2.5)
