extends Control
## 전술 카드 손패 UI (준비 단계). 실제 카드 덱 느낌:
## 종이 카드 페이스 + 덱 더미 + 드로우/사용/셔플/호버 모션. (DIY 종이 매너)

const CARD_W := 116.0
const CARD_H := 158.0
const SEP := 10.0
const DECK_POS := Vector2(1150.0, 548.0)   # 덱 더미 위치
const HAND_Y := 560.0                       # 손패 기준 y

var _tp_label: Label
var _deck: Node
var _hand_root: Control
var _deck_pile: Control
var _deck_count: Label
var _card_sb: StyleBoxFlat
var _card_sb_hover: StyleBoxFlat
var _paper: Texture2D
var _back: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = _load("res://assets/ui/paper.png")
	_back = _load("res://assets/ui/card_back.png")
	_build_styleboxes()

	_tp_label = Label.new()
	_tp_label.add_theme_font_size_override("font_size", 17)
	_tp_label.position = Vector2(DECK_POS.x - 6.0, DECK_POS.y - 30.0)
	add_child(_tp_label)

	_hand_root = Control.new()
	_hand_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hand_root)

	_build_deck_pile()

	var main: Node = get_parent().get_parent()
	_deck = main.get_node_or_null("TacticalDeck")
	if _deck != null:
		_deck.hand_changed.connect(_on_hand_changed)
		_deck.tp_changed.connect(func(_t): _refresh_tp())
		if _deck.has_signal("shuffled"):
			_deck.shuffled.connect(_play_shuffle_fx)
	var bf: Node = main.get_node_or_null("BattleField")
	if bf != null and bf.has_signal("phase_changed"):
		bf.phase_changed.connect(func(p): visible = (p == 0))
	_refresh()


func _load(p: String) -> Texture2D:
	return load(p) if ResourceLoader.exists(p) else null


func _build_styleboxes() -> void:
	_card_sb = StyleBoxFlat.new()
	_card_sb.bg_color = Color(0.93, 0.88, 0.78, 1.0)
	_card_sb.set_border_width_all(2)
	_card_sb.border_color = Color(0.18, 0.14, 0.1)
	_card_sb.set_corner_radius_all(0)
	_card_sb.content_margin_left = 8.0
	_card_sb.content_margin_right = 8.0
	_card_sb.content_margin_top = 8.0
	_card_sb.content_margin_bottom = 8.0
	_card_sb_hover = _card_sb.duplicate()
	_card_sb_hover.border_color = Color(0.62, 0.23, 0.18)
	_card_sb_hover.set_border_width_all(3)


func _build_deck_pile() -> void:
	_deck_pile = Control.new()
	_deck_pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_pile)
	# 더미 그림자(겹친 카드 느낌)
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


## 카드 뒷면 비주얼 (덱/셔플용)
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


func _on_hand_changed(_hand: Array) -> void:
	_refresh()


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
	var start_x: float = (1280.0 - total_w) * 0.5 + 120.0   # 약간 우측(배치 구역 회피)
	for i in n:
		var target := Vector2(start_x + float(i) * (CARD_W + SEP), HAND_Y)
		_make_card(hand[i], i, target)


func _make_card(card: Dictionary, idx: int, target: Vector2) -> void:
	var cost: int = int(card.get("cost", 1))
	var affordable: bool = int(_deck.get_tp()) >= cost

	var root := Control.new()
	root.size = Vector2(CARD_W, CARD_H)
	root.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_root.add_child(root)

	# 종이 페이스 (Panel + 종이 텍스처 오버레이)
	var face := Panel.new()
	face.add_theme_stylebox_override("panel", _card_sb)
	face.size = Vector2(CARD_W, CARD_H)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(face)
	if _paper != null:
		var pap := TextureRect.new()
		pap.texture = _paper
		pap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pap.position = Vector2(2, 2)
		pap.size = Vector2(CARD_W - 4, CARD_H - 4)
		pap.modulate = Color(1, 1, 1, 0.5)
		pap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.add_child(pap)

	# 제목
	var title := Label.new()
	title.text = String(card.get("label", card.get("id", "")))
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.16, 0.12, 0.08))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.position = Vector2(6, 8)
	title.size = Vector2(CARD_W - 12, 36)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	# 제목 밑줄 (스탬프 레드 룰)
	var rule := ColorRect.new()
	rule.color = Color(0.62, 0.23, 0.18, 0.85)
	rule.position = Vector2(10, 46)
	rule.size = Vector2(CARD_W - 20, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rule)

	# 설명
	var desc := Label.new()
	desc.text = String(card.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.28, 0.22, 0.15))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(8, 56)
	desc.size = Vector2(CARD_W - 16, CARD_H - 64)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(desc)

	# 코스트 스탬프 (좌상단 원형)
	var badge := Panel.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.62, 0.23, 0.18) if affordable else Color(0.45, 0.4, 0.33)
	bsb.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("panel", bsb)
	badge.position = Vector2(-6, -6)
	badge.size = Vector2(28, 28)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge)
	var clab := Label.new()
	clab.text = str(cost)
	clab.add_theme_font_size_override("font_size", 15)
	clab.add_theme_color_override("font_color", Color(0.94, 0.89, 0.79))
	clab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clab.size = Vector2(28, 28)
	clab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(clab)

	# 클릭/호버용 투명 버튼 (페이스 위)
	var btn := Button.new()
	btn.flat = true
	btn.size = Vector2(CARD_W, CARD_H)
	btn.disabled = not affordable
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.add_theme_stylebox_override("focus", empty)
	root.add_child(btn)
	root.modulate = Color(1, 1, 1, 1) if affordable else Color(0.85, 0.82, 0.76, 0.85)

	btn.mouse_entered.connect(func(): _hover(root, target, true))
	btn.mouse_exited.connect(func(): _hover(root, target, false))
	btn.pressed.connect(func(): _play_card(root, idx))

	# 드로우 모션: 덱에서 손패 자리로 날아옴
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
	tw.tween_property(root, "position:y", base.y - (18.0 if on else 0.0), 0.12)
	tw.tween_property(root, "scale", Vector2(1.08, 1.08) if on else Vector2.ONE, 0.12)


func _play_card(root: Control, idx: int) -> void:
	if not is_instance_valid(root):
		return
	# 사용 모션: 위로 떠오르며 회전+페이드
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.set_parallel(true)
	tw.tween_property(root, "position:y", root.position.y - 90.0, 0.22)
	tw.tween_property(root, "rotation", 0.25, 0.22)
	tw.tween_property(root, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(func():
		if _deck != null:
			_deck.play_card(idx))


## 셔플 모션: 덱 더미에서 카드 뒷면들이 부채처럼 퍼졌다 모인다.
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
