class_name Decor
extends Control
## BINDER 재질 사물(emoji 아닌 그리기): 마스킹 테이프 · 종이 클립 · 도장.
## 패널/카드 위에 물리적 사물을 올린 느낌을 준다(압정/핀은 제외).
## 팩토리로 인스턴스를 만들어 대상 Control의 자식으로 add_child.

enum Kind { TAPE, CLIP, STAMP }

var kind: int = Kind.TAPE
var stamp_text: String = "FILED"
var _accent: Color = Palette.ACCENT


## 마스킹 테이프 조각(반투명). 모서리에 비스듬히 붙인다.
static func tape(w: float = 78.0, h: float = 26.0, angle_deg: float = -6.0) -> Decor:
	var d := Decor.new()
	d.kind = Kind.TAPE
	d.size = Vector2(w, h)
	d.pivot_offset = Vector2(w * 0.5, h * 0.5)
	d.rotation = deg_to_rad(angle_deg)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


## 종이 클립 — 패널 상단에 끼운 느낌(상단 가장자리에 걸치게 배치).
static func clip() -> Decor:
	var d := Decor.new()
	d.kind = Kind.CLIP
	d.size = Vector2(26.0, 56.0)
	d.pivot_offset = Vector2(13.0, 28.0)
	d.rotation = deg_to_rad(-16.0)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


## 고무 도장 — 비스듬한 이중 테두리 + 대문자 모노 텍스트(아카이브 레드).
static func stamp(text: String, angle_deg: float = -11.0, w: float = 150.0, h: float = 46.0) -> Decor:
	var d := Decor.new()
	d.kind = Kind.STAMP
	d.stamp_text = text
	d.size = Vector2(w, h)
	d.pivot_offset = Vector2(w * 0.5, h * 0.5)
	d.rotation = deg_to_rad(angle_deg)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


func _draw() -> void:
	match kind:
		Kind.TAPE: _draw_tape()
		Kind.CLIP: _draw_clip()
		Kind.STAMP: _draw_stamp()


func _draw_tape() -> void:
	var col := Color(0.89, 0.863, 0.769, 0.82)   # BINDER tape #e3dcc4cc
	draw_rect(Rect2(Vector2.ZERO, size), col, true)
	# 양 끝의 거친(톱니) 가장자리 암시 + 은은한 잉크 외곽.
	draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.INK0, 0.14), false, 1.0)
	var step := 6.0
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x + step * 0.5, 2.5), Color(Palette.INK0, 0.10), 1.0)
		draw_line(Vector2(x, size.y), Vector2(x + step * 0.5, size.y - 2.5), Color(Palette.INK0, 0.10), 1.0)
		x += step
	# 대각 하이라이트(셀로판 느낌).
	draw_line(Vector2(4, 5), Vector2(size.x - 6, 7), Color(1, 1, 1, 0.12), 2.0)


func _draw_clip() -> void:
	var col := Color(Palette.INK1, 0.92)
	var w := 2.4
	var cx := size.x * 0.5
	# 바깥 루프 + 안쪽 짧은 루프(살짝 아래로 오프셋) = 종이 클립 실루엣.
	_stroke_stadium(Vector2(cx, 26.0), 8.0, 22.0, col, w)
	_stroke_stadium(Vector2(cx, 30.0), 4.0, 15.0, col, w)


## 세로 스타디움(둥근 양끝) 외곽선.
func _stroke_stadium(center: Vector2, hw: float, hh: float, col: Color, w: float) -> void:
	var sy := hh - hw
	draw_line(center + Vector2(-hw, -sy), center + Vector2(-hw, sy), col, w)
	draw_line(center + Vector2(hw, -sy), center + Vector2(hw, sy), col, w)
	draw_arc(center + Vector2(0, -sy), hw, PI, TAU, 14, col, w)
	draw_arc(center + Vector2(0, sy), hw, 0.0, PI, 14, col, w)


func _draw_stamp() -> void:
	var col := Color(_accent, 0.88)
	# 이중 테두리(고무 도장 잉크 번짐 느낌).
	draw_rect(Rect2(Vector2.ZERO, size), col, false, 2.5)
	draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color(_accent, 0.6), false, 1.4)
	var font: Font = Palette.font(Palette.F_MONO_BOLD)
	if font == null:
		font = ThemeDB.fallback_font
	var fs := 22
	var ts := font.get_string_size(stamp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var pos := Vector2((size.x - ts.x) * 0.5, (size.y + ts.y) * 0.5 - 4.0)
	draw_string(font, pos, stamp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
