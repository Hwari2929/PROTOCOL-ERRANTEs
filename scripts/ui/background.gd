extends CanvasLayer
## 배경 — 세피아 빈티지 종이 질감 베이스 + 절차적 그레인 오버레이.
## (3D 배경 그래픽은 숨김. 디자인 매너: 영수증/종이/DIY 펑크.)

func _ready() -> void:
	layer = -10

	# 종이 베이스
	var paper := TextureRect.new()
	paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 전술 지도(진짜 종이) 우선, 없으면 종이 텍스처.
	if ResourceLoader.exists("res://assets/bg/bg_map.png"):
		paper.texture = load("res://assets/bg/bg_map.png")
		paper.modulate = Color(0.98, 0.95, 0.88, 1.0)
	elif ResourceLoader.exists("res://assets/ui/paper.png"):
		paper.texture = load("res://assets/ui/paper.png")
		paper.modulate = Color(0.97, 0.93, 0.84, 1.0)
	else:
		paper.self_modulate = Color(0.9, 0.85, 0.74)
	add_child(paper)

	# 절차적 필름 그레인 (타일)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.frequency = 0.42
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.noise = noise
	var grain := TextureRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.texture = nt
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grain.self_modulate = Color(0.25, 0.2, 0.13, 0.10)  # 어두운 세피아 그레인, 낮은 불투명도
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grain)

	# 가장자리 어둡게 (비네트 느낌) — 종이 가장자리 강조
	var vign := ColorRect.new()
	vign.set_anchors_preset(Control.PRESET_FULL_RECT)
	vign.color = Color(0.16, 0.12, 0.08, 0.0)
	vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vign)
