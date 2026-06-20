extends CanvasLayer
## 배경 — 전투 배경 그래픽은 제거. 크림 종이 톤(clear_color) 위에 은은한 필름 그레인만.

func _ready() -> void:
	layer = -10
	# 절차적 필름 그레인 (타일) — 배경 이미지 없이 종이 질감만.
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
	grain.self_modulate = Color(0.25, 0.2, 0.13, 0.08)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grain)
