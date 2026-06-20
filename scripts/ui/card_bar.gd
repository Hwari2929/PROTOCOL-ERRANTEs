extends Control
## 전술 카드 손패 UI (준비 단계). 슬더슬식 카드 레이아웃:
## 상단=코스트+이름, 중앙=일러스트, 하단=효과. 종이는 은은한 오버레이, 그레인 벡터 톤.

const CARD_W := 150.0
const CARD_H := 208.0
const SEP := 12.0
const DECK_POS := Vector2(1150.0, 498.0)
const HAND_Y := 504.0

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = _load("res://assets/ui/paper.png")
	_back = _load("res://assets/ui/card_back.png")
	_build_styleboxes()

	_tp_label = Label.new()
	_tp_label.add_theme_font_size_override("font_size", 17)
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
	_card_sb = StyleBoxFlat.new()
	_card_sb.bg_color = Color(0.94, 0.89, 0.79, 1.0)
	_card_sb.set_border_width_all(2)
	_card_sb.border_color = Color(0.18, 0.14, 0.1)
	_card_sb.set_corner_radius_all(0)


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
	_deck_count.add_theme_font_size_override("font_size", 14)
	_deck_count.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))
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
	if _deck != null:
		_tp_label.text = "TP %d" % int(_deck.get_tp())


func _refresh() -> void:
	if _deck == null:
		return
	_refresh_tp()
	if _deck_count != null:
		_deck_count.text = "덱 %d" % int(_deck.deck_count())
	for c in _hand_root.get_children():
		c.queue_free()
	var hand: Array = _deck.get_hand()
	var n: int = hand.size()
	var total_w: float = float(n) * CARD_W + float(max(0, n - 1)) * SEP
	var start_x: float = (1280.0 - total_w) * 0.5 + 110.0
	for i in n:
		var target := Vector2(start_x + float(i) * (CARD_W + SEP), HAND_Y)
		_make_card(hand[i], i, target)


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

	# 카드 페이스
	var face := Panel.new()
	face.add_theme_stylebox_override("panel", _card_sb)
	face.size = Vector2(CARD_W, CARD_H)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(face)
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
	band.color = Color(accent.r, accent.g, accent.b, 0.85)
	band.position = Vector2(2, 2)
	band.size = Vector2(CARD_W - 4, 30)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	# 이름
	var title := Label.new()
	title.text = String(card.get("label", cid))
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.96, 0.92, 0.83))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(28, 4)
	title.size = Vector2(CARD_W - 40, 26)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	# 일러스트 박스
	var box := ColorRect.new()
	box.color = Color(0.88, 0.83, 0.72, 1.0)
	box.position = Vector2(10, 38)
	box.size = Vector2(CARD_W - 20, 112)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var box_border := Panel.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0, 0, 0, 0)
	bsb.set_border_width_all(2)
	bsb.border_color = Color(0.2, 0.16, 0.11, 0.8)
	bsb.set_corner_radius_all(0)
	box_border.add_theme_stylebox_override("panel", bsb)
	box_border.position = box.position
	box_border.size = box.size
	box_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box_border)
	var illo := _illo(cat)
	if illo != null:
		var ir := TextureRect.new()
		ir.texture = illo
		ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ir.position = box.position + Vector2(6, 4)
		ir.size = box.size - Vector2(12, 8)
		ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(ir)

	# 효과 설명 (하단)
	var desc := Label.new()
	desc.text = String(card.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(8, 154)
	desc.size = Vector2(CARD_W - 16, CARD_H - 160)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(desc)

	# 코스트 스탬프
	var badge := Panel.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = accent if affordable else Color(0.45, 0.4, 0.33)
	bs.set_corner_radius_all(15)
	bs.set_border_width_all(2)
	bs.border_color = Color(0.96, 0.92, 0.83, 0.9)
	badge.add_theme_stylebox_override("panel", bs)
	badge.position = Vector2(-7, -7)
	badge.size = Vector2(32, 32)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge)
	var clab := Label.new()
	clab.text = str(cost)
	clab.add_theme_font_size_override("font_size", 17)
	clab.add_theme_color_override("font_color", Color(0.96, 0.92, 0.83))
	clab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clab.size = Vector2(32, 32)
	clab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(clab)

	# 클릭/호버
	var btn := Button.new()
	btn.flat = true
	btn.size = Vector2(CARD_W, CARD_H)
	btn.disabled = not affordable
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(s, empty)
	root.add_child(btn)
	root.modulate = Color(1, 1, 1, 1) if affordable else Color(0.86, 0.83, 0.77, 0.9)
	btn.mouse_entered.connect(func(): _hover(root, target, true))
	btn.mouse_exited.connect(func(): _hover(root, target, false))
	btn.pressed.connect(func(): _play_card(root, idx))

	# 드로우 모션
	root.position = DECK_POS
	root.scale = Vector2(0.6, 0.6)
	root.rotation = 0.5
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(root, "position", target, 0.32).set_delay(float(idx) * 0.07)
	tw.tween_property(root, "scale", Vector2.ONE, 0.32).set_delay(float(idx) * 0.07)
	tw.tween_property(root, "rotation", 0.0, 0.32).set_delay(float(idx) * 0.07)


func _hover(root: Control, base: Vector2, on: bool) -> void:
	if not is_instance_valid(root):
		return
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(root, "position:y", base.y - (22.0 if on else 0.0), 0.12)
	tw.tween_property(root, "scale", Vector2(1.08, 1.08) if on else Vector2.ONE, 0.12)


func _play_card(root: Control, idx: int) -> void:
	if not is_instance_valid(root):
		return
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.set_parallel(true)
	tw.tween_property(root, "position:y", root.position.y - 100.0, 0.22)
	tw.tween_property(root, "rotation", 0.25, 0.22)
	tw.tween_property(root, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(func():
		if _deck != null:
			_deck.play_card(idx))


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
