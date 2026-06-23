extends Control
## 전술 카드 손패 UI (준비 단계). 슬더슬식 카드 레이아웃:
## 상단=코스트+이름, 중앙=일러스트, 하단=효과. 종이는 은은한 오버레이, 그레인 벡터 톤.

const CARD_W := 150.0
const CARD_H := 208.0
const SEP := 12.0
const DECK_POS := Vector2(1150.0, 498.0)
const HAND_Y := 504.0

# 카드 기울임(틸트) — 누른 채 끌면 포인터 방향으로 기욺. Node2D 래퍼의 skew/scale/rotation으로
# 2D 의사-원근 구현(셰이더/3D 없이 전단(shear)이 깊이감의 핵심 단서).
const TILT_ROT := 0.00095   # dx → z-회전(rad/px)
const TILT_SKEW := 0.0016   # dy → 전단(rad/px)
const TILT_SCALE := 0.00065 # |drag| → 약한 포어쇼트닝
const TILT_ROT_MAX := 0.17
const TILT_SKEW_MAX := 0.32

# 사용 대기(큐) 연출 높이
const PENDING_LIFT := 36.0
const HOVER_LIFT := 18.0

# 카드 → 일러스트 카테고리
const CARD_CAT := {
	"focus_fire": "fire", "heavy_rounds": "fire", "overdrive": "fire", "joint_effort": "fire",
	"melee_drill": "melee", "brutal_strike": "melee", "war_cry": "melee",
	"vitality": "vitality", "fortress": "vitality", "iron_skin": "vitality", "numbers": "vitality",
	"plating": "armor", "bulwark": "armor",
	"adrenaline": "speed", "swift": "speed",
	"longshot": "range", "high_ground": "range",
	"resonant_edge": "skill",
	"rapid_tactics": "tactic", "minor_tactic": "tactic",
}
const CAT_COLOR := {
	"fire": Color(0.62, 0.23, 0.18), "melee": Color(0.5, 0.28, 0.16),
	"vitality": Color(0.38, 0.45, 0.22), "armor": Color(0.3, 0.4, 0.5),
	"speed": Color(0.6, 0.48, 0.2), "range": Color(0.45, 0.33, 0.5),
	"skill": Color(0.55, 0.45, 0.2), "tactic": Color(0.36, 0.4, 0.42),
}

var _tp_label: Label
var _deck: Node
var _hand_root: Control
var _deck_pile: Control
var _deck_count: Label
var _card_sb: StyleBoxFlat
var _paper: Texture2D
var _back: Texture2D
var _illo_cache: Dictionary = {}
var _tilt_vis: Node2D = null
var _tilt_start: Vector2 = Vector2.ZERO
# 카드 즉시 사용 대신 "사용 대기" 큐에 토글 등록 → 전투 시작 시 일괄 사용.
var _cards: Array = []        # 표시 중 카드 메타({root,vis,card,cost,base,pending,sel,tab,btn})
var _pending: Array = []      # 대기 중 카드(dict 참조) 순서 목록


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = _load("res://assets/ui/paper.png")
	_back = _load("res://assets/ui/card_back.png")
	_build_styleboxes()

	_tp_label = Label.new()
	_tp_label.add_theme_font_size_override("font_size", 16)
	var mono := Palette.font(Palette.F_MONO_BOLD)
	if mono != null:
		_tp_label.add_theme_font_override("font", mono)
	_tp_label.add_theme_color_override("font_color", Palette.ACCENT)
	_tp_label.position = Vector2(DECK_POS.x - 4.0, DECK_POS.y - 28.0)
	add_child(_tp_label)

	_hand_root = Control.new()
	_hand_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hand_root)

	_build_deck_pile()

	var main: Node = get_parent().get_parent()
	_deck = main.get_node_or_null("TacticalDeck")
	if _deck != null:
		_deck.hand_changed.connect(func(_h): _refresh())
		_deck.tp_changed.connect(func(_t): _refresh_tp())
		if _deck.has_signal("shuffled"):
			_deck.shuffled.connect(_play_shuffle_fx)
	var bf: Node = main.get_node_or_null("BattleField")
	if bf != null and bf.has_signal("phase_changed"):
		bf.phase_changed.connect(func(p): visible = (p == 0))
	_refresh()


func _load(p: String) -> Texture2D:
	return load(p) if ResourceLoader.exists(p) else null


func _illo(cat: String) -> Texture2D:
	if _illo_cache.has(cat):
		return _illo_cache[cat]
	var t := _load("res://assets/ui/cards/%s.png" % cat)
	_illo_cache[cat] = t
	return t


func _build_styleboxes() -> void:
	# BINDER 카드면: paper-0 + 두꺼운 잉크 외곽선 + sm 라운드 + 청키 키섀도.
	_card_sb = Palette.card_face(Palette.R_SM, Vector2(3, 3))


func _build_deck_pile() -> void:
	_deck_pile = Control.new()
	_deck_pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_pile)
	for i in range(3):
		var shadow := _card_face_back()
		shadow.position = DECK_POS + Vector2(float(i) * 2.5, float(-i) * 2.5)
		shadow.modulate = Color(1, 1, 1, 0.5 + 0.16 * float(i))
		_deck_pile.add_child(shadow)
	_deck_count = Label.new()
	_deck_count.add_theme_font_size_override("font_size", 13)
	var mono := Palette.font(Palette.F_MONO)
	if mono != null:
		_deck_count.add_theme_font_override("font", mono)
	_deck_count.add_theme_color_override("font_color", Palette.PAPER0)
	_deck_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_count.position = DECK_POS + Vector2(0.0, CARD_H - 26.0)
	_deck_count.size = Vector2(CARD_W, 22.0)
	_deck_pile.add_child(_deck_count)


func _card_face_back() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(CARD_W, CARD_H)
	c.size = Vector2(CARD_W, CARD_H)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _back != null:
		var t := TextureRect.new()
		t.texture = _back
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.size = Vector2(CARD_W, CARD_H)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(t)
	else:
		var p := Panel.new()
		p.add_theme_stylebox_override("panel", _card_sb)
		p.size = Vector2(CARD_W, CARD_H)
		c.add_child(p)
	return c


func _refresh_tp() -> void:
	if _deck == null:
		return
	var tp: int = int(_deck.get_tp())
	var q: int = _pending_cost()
	# 대기 중이면 잔여 TP와 큐 소모량을 함께 표기(모노 라벨 → 영문).
	_tp_label.text = "TP %d  USE %d" % [tp - q, q] if q > 0 else "TP %d" % tp


func _pending_cost() -> int:
	var s: int = 0
	for c in _pending:
		s += int(c.get("cost", 1))
	return s


func _refresh() -> void:
	if _deck == null:
		return
	# 새 패(노드 전환 등)면 대기 큐는 무효 → 초기화.
	_pending.clear()
	_cards.clear()
	for c in _hand_root.get_children():
		c.queue_free()
	if _deck_count != null:
		_deck_count.text = "DECK %d" % int(_deck.deck_count())
	var hand: Array = _deck.get_hand()
	var n: int = hand.size()
	var total_w: float = float(n) * CARD_W + float(max(0, n - 1)) * SEP
	var start_x: float = (1280.0 - total_w) * 0.5 + 110.0
	for i in n:
		var target := Vector2(start_x + float(i) * (CARD_W + SEP), HAND_Y)
		_make_card(hand[i], i, target)
	_update_affordability()
	_refresh_tp()


func _make_card(card: Dictionary, idx: int, target: Vector2) -> void:
	var cid: String = String(card.get("id", ""))
	var cost: int = int(card.get("cost", 1))
	var affordable: bool = int(_deck.get_tp()) >= cost
	var cat: String = String(CARD_CAT.get(cid, "tactic"))
	var accent: Color = CAT_COLOR.get(cat, Color(0.5, 0.3, 0.2))

	var root := Control.new()
	root.size = Vector2(CARD_W, CARD_H)
	root.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_root.add_child(root)

	# 비주얼을 Node2D(vis) 아래 inner Control에 담고 vis를 카드 중앙에 둠 → skew/scale/rotation이
	# 카드 중심을 기준으로 돈다. 입력 Button은 root 직속(형제, 비주얼 위).
	var vis := Node2D.new()
	vis.position = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	root.add_child(vis)
	var inner := Control.new()
	inner.position = Vector2(-CARD_W * 0.5, -CARD_H * 0.5)
	inner.size = Vector2(CARD_W, CARD_H)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vis.add_child(inner)

	# 카드 페이스
	var face := Panel.new()
	face.add_theme_stylebox_override("panel", _card_sb)
	face.size = Vector2(CARD_W, CARD_H)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(face)
	# 종이 은은한 오버레이
	if _paper != null:
		var pap := TextureRect.new()
		pap.texture = _paper
		pap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pap.position = Vector2(2, 2)
		pap.size = Vector2(CARD_W - 4, CARD_H - 4)
		pap.modulate = Color(1, 1, 1, 0.22)
		pap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.add_child(pap)

	# 상단 카테고리 띠
	var band := ColorRect.new()
	band.color = Color(accent.r, accent.g, accent.b, 0.92)
	band.position = Vector2(3, 3)
	band.size = Vector2(CARD_W - 6, 28)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(band)
	# 이름
	var title := Label.new()
	title.text = String(card.get("label", cid))
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Palette.PAPER0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(28, 4)
	title.size = Vector2(CARD_W - 40, 26)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(title)

	# 일러스트 박스
	var box := ColorRect.new()
	box.color = Palette.PAPER2
	box.position = Vector2(10, 38)
	box.size = Vector2(CARD_W - 20, 112)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	var box_border := Panel.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0, 0, 0, 0)
	bsb.set_border_width_all(Palette.BW)
	bsb.border_color = Palette.INK0
	bsb.set_corner_radius_all(Palette.R_XS)
	box_border.add_theme_stylebox_override("panel", bsb)
	box_border.position = box.position
	box_border.size = box.size
	box_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box_border)
	var illo := _illo(cat)
	if illo != null:
		var ir := TextureRect.new()
		ir.texture = illo
		ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ir.position = box.position + Vector2(6, 4)
		ir.size = box.size - Vector2(12, 8)
		ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(ir)

	# 효과 설명 (하단)
	var desc := Label.new()
	desc.text = String(card.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Palette.INK0)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(8, 154)
	desc.size = Vector2(CARD_W - 16, CARD_H - 160)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(desc)

	# 코스트 스탬프
	var badge := Panel.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = accent if affordable else Color(0.45, 0.4, 0.33)
	bs.set_corner_radius_all(15)
	bs.set_border_width_all(Palette.BW)
	bs.border_color = Palette.PAPER0
	Palette.with_key_shadow(bs, Vector2(2, 2))
	badge.add_theme_stylebox_override("panel", bs)
	badge.position = Vector2(-7, -7)
	badge.size = Vector2(32, 32)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(badge)
	var clab := Label.new()
	clab.text = str(cost)
	clab.add_theme_font_size_override("font_size", 16)
	var mono := Palette.font(Palette.F_MONO_BOLD)
	if mono != null:
		clab.add_theme_font_override("font", mono)
	clab.add_theme_color_override("font_color", Palette.PAPER0)
	clab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clab.size = Vector2(32, 32)
	clab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(clab)

	# 사용 대기 강조: 아카이브 레드 외곽선(평시 숨김) — vis 안이라 카드와 함께 기욺.
	var sel := Panel.new()
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0, 0, 0, 0)
	ssb.set_border_width_all(Palette.BW_BOLD)
	ssb.border_color = Palette.ACCENT
	ssb.set_corner_radius_all(Palette.R_SM)
	Palette.with_key_shadow(ssb, Vector2(0, 0))
	sel.add_theme_stylebox_override("panel", ssb)
	sel.size = Vector2(CARD_W, CARD_H)
	sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sel.visible = false
	inner.add_child(sel)

	# "출격 대기" 탭 리본 — 카드 위쪽(root 직속, 기울지 않음).
	var tab := Panel.new()
	var tsb := Palette.chip_box(Palette.ACCENT, Palette.R_XS)
	Palette.with_key_shadow(tsb, Vector2(2, 2))
	tab.add_theme_stylebox_override("panel", tsb)
	tab.position = Vector2(CARD_W * 0.5 - 47.0, -26.0)
	tab.size = Vector2(94.0, 24.0)
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.visible = false
	root.add_child(tab)
	var tlab := Label.new()
	tlab.text = "▲ 출격 대기"
	tlab.add_theme_font_size_override("font_size", 13)
	tlab.add_theme_color_override("font_color", Palette.PAPER0)
	tlab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tlab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tlab.set_anchors_preset(Control.PRESET_FULL_RECT)
	tlab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.add_child(tlab)

	# 클릭/호버
	var btn := Button.new()
	btn.flat = true
	btn.size = Vector2(CARD_W, CARD_H)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(s, empty)
	root.add_child(btn)

	var meta := {
		"root": root, "vis": vis, "card": card, "cost": cost,
		"base": target, "pending": false, "sel": sel, "tab": tab,
		"btn": btn, "badge_sb": bs,
	}
	_cards.append(meta)

	btn.mouse_entered.connect(func(): _hover(meta, true))
	btn.mouse_exited.connect(func(): _hover(meta, false))
	btn.pressed.connect(func(): _toggle_card(meta))
	btn.button_down.connect(func(): _begin_tilt(vis))
	btn.button_up.connect(func(): _end_tilt(vis))

	# 드로우 모션
	root.position = DECK_POS
	root.scale = Vector2(0.6, 0.6)
	root.rotation = 0.5
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(root, "position", target, 0.32).set_delay(float(idx) * 0.07)
	tw.tween_property(root, "scale", Vector2.ONE, 0.32).set_delay(float(idx) * 0.07)
	tw.tween_property(root, "rotation", 0.0, 0.32).set_delay(float(idx) * 0.07)


func _begin_tilt(vis: Node2D) -> void:
	_tilt_vis = vis
	_tilt_start = get_global_mouse_position()


func _end_tilt(vis: Node2D) -> void:
	if _tilt_vis == vis:
		_tilt_vis = null
	if vis != null and is_instance_valid(vis):
		# ease-pop 복귀(톡 하고 펴짐)
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel(true)
		tw.tween_property(vis, "rotation", 0.0, 0.28)
		tw.tween_property(vis, "skew", 0.0, 0.28)
		tw.tween_property(vis, "scale", Vector2.ONE, 0.28)


func _process(_dt: float) -> void:
	# 누른 채 끌면 포인터 방향으로 카드가 기욺.
	if _tilt_vis == null or not is_instance_valid(_tilt_vis):
		_tilt_vis = null
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var off: Vector2 = get_global_mouse_position() - _tilt_start
	_tilt_vis.rotation = clampf(off.x * TILT_ROT, -TILT_ROT_MAX, TILT_ROT_MAX)
	_tilt_vis.skew = clampf(off.y * TILT_SKEW, -TILT_SKEW_MAX, TILT_SKEW_MAX)
	var sh: float = minf(abs(off.x), 200.0) * TILT_SCALE
	var sv: float = minf(abs(off.y), 200.0) * TILT_SCALE
	_tilt_vis.scale = Vector2(maxf(0.82, 1.0 - sh), maxf(0.82, 1.0 - sv))


func _settle_y(meta: Dictionary) -> float:
	# 카드가 안착할 y(대기 중이면 들려 있음).
	var base: Vector2 = meta["base"]
	return base.y - (PENDING_LIFT if bool(meta["pending"]) else 0.0)


func _hover(meta: Dictionary, on: bool) -> void:
	var root: Control = meta["root"]
	if not is_instance_valid(root):
		return
	var pending: bool = bool(meta["pending"])
	var y := _settle_y(meta) - (HOVER_LIFT if on else 0.0)
	var sc := 1.08 if on else (1.04 if pending else 1.0)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(root, "position:y", y, 0.12)
	tw.tween_property(root, "scale", Vector2(sc, sc), 0.12)


## 카드 클릭 = 사용 대기 큐 토글(즉시 사용 아님). 전투 시작 시 일괄 사용.
func _toggle_card(meta: Dictionary) -> void:
	var card: Dictionary = meta["card"]
	if bool(meta["pending"]):
		_pending.erase(card)
		meta["pending"] = false
	else:
		var cost: int = int(meta["cost"])
		if cost > int(_deck.get_tp()) - _pending_cost():
			_reject(meta)   # TP 부족 → 등록 거부
			return
		_pending.append(card)
		meta["pending"] = true
	_apply_pending_visual(meta)
	_update_affordability()
	_refresh_tp()


func _apply_pending_visual(meta: Dictionary) -> void:
	var root: Control = meta["root"]
	var pending: bool = bool(meta["pending"])
	(meta["sel"] as CanvasItem).visible = pending
	(meta["tab"] as CanvasItem).visible = pending
	var sc := 1.04 if pending else 1.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel(true)
	tw.tween_property(root, "position:y", _settle_y(meta), 0.2)
	tw.tween_property(root, "scale", Vector2(sc, sc), 0.2)


## 잔여 TP로 등록 불가한(대기 아님) 카드는 흐리게 + 비활성. 대기 카드는 항상 토글 가능.
func _update_affordability() -> void:
	var remain: int = int(_deck.get_tp()) - _pending_cost()
	for meta in _cards:
		var root: Control = meta["root"]
		if not is_instance_valid(root):
			continue
		var pending: bool = bool(meta["pending"])
		var ok: bool = pending or int(meta["cost"]) <= remain
		(meta["btn"] as Button).disabled = not ok and not pending
		root.modulate = Color(1, 1, 1, 1) if ok else Color(0.84, 0.82, 0.77, 0.85)


func _reject(meta: Dictionary) -> void:
	# TP 부족 피드백: 코스트 배지를 잠깐 흔든다.
	var root: Control = meta["root"]
	if not is_instance_valid(root):
		return
	var x: float = (meta["base"] as Vector2).x
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(root, "position:x", x - 6.0, 0.04)
	tw.tween_property(root, "position:x", x + 6.0, 0.06)
	tw.tween_property(root, "position:x", x, 0.05)


## 전투 시작 직전 호출(prep_panel) — 대기 카드를 등록 순서대로 일괄 사용.
func commit_pending() -> void:
	if _deck == null:
		return
	var queue: Array = _pending.duplicate()
	_pending.clear()
	for card in queue:
		_deck.play_card_ref(card)


func _play_shuffle_fx() -> void:
	if not visible:
		return
	for i in range(6):
		var card := _card_face_back()
		card.position = DECK_POS
		card.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
		add_child(card)
		var off := Vector2(randf_range(-70, 70), randf_range(-40, 20))
		var tw := create_tween().set_trans(Tween.TRANS_QUAD)
		tw.set_parallel(true)
		tw.tween_property(card, "position", DECK_POS + off, 0.16).set_delay(float(i) * 0.03)
		tw.tween_property(card, "rotation", randf_range(-0.4, 0.4), 0.16).set_delay(float(i) * 0.03)
		tw.chain().tween_property(card, "position", DECK_POS, 0.16)
		tw.parallel().tween_property(card, "rotation", 0.0, 0.16)
		tw.chain().tween_callback(card.queue_free)
