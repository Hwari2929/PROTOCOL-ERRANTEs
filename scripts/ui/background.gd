extends CanvasLayer
## 전장 배경 — 월드 뒤(layer -10)에 풀스크린 배경 이미지 + 가독성용 어두운 오버레이.
## 페이즈에 따라 준비/전투 배경을 전환한다.

var _tex: TextureRect
var _overlay: ColorRect
var _battle: Texture2D
var _prep: Texture2D


func _ready() -> void:
	layer = -10
	_battle = _load("res://assets/bg/bg_battle.png")
	_prep = _load("res://assets/bg/bg_prep.png")
	if _prep == null:
		_prep = _battle

	_tex = TextureRect.new()
	_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex.texture = _prep
	add_child(_tex)

	# 가독성용 어두운 그라데이션 오버레이.
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.04, 0.055, 0.08, 0.42)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	var bf: Node = get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_signal("phase_changed"):
		bf.phase_changed.connect(_on_phase)


func _load(p: String) -> Texture2D:
	if ResourceLoader.exists(p):
		return load(p)
	return null


func _on_phase(phase: int) -> void:
	if _tex == null:
		return
	_tex.texture = _prep if phase == 0 else _battle
	_overlay.color = Color(0.04, 0.055, 0.08, 0.42 if phase == 0 else 0.30)
