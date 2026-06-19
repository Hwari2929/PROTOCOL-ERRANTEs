extends Node2D
class_name RangeFX
## 기술 사용 시 범위 표시 — 잉크 링이 퍼지며 사라진다. (DIY 종이 매너: 스탬프 잉크 원)

var _r: float = 0.0
var _color: Color = Color(0.62, 0.23, 0.18)
var _alpha: float = 0.6


static func spawn(parent: Node2D, center: Vector2, radius: float, color: Color = Color(0.62, 0.23, 0.18)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var fx := RangeFX.new()
	fx._color = color
	fx.z_index = 5
	parent.add_child(fx)
	fx.global_position = center
	var tw := fx.create_tween()
	tw.set_parallel(true)
	tw.tween_method(fx._set_r, radius * 0.25, radius, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(fx._set_a, 0.55, 0.0, 0.45)
	tw.chain().tween_callback(fx.queue_free)


func _set_r(v: float) -> void:
	_r = v
	queue_redraw()


func _set_a(a: float) -> void:
	_alpha = a
	queue_redraw()


func _draw() -> void:
	var c := Color(_color.r, _color.g, _color.b, _alpha)
	draw_arc(Vector2.ZERO, _r, 0.0, TAU, 48, c, 2.5)
	draw_arc(Vector2.ZERO, _r * 0.5, 0.0, TAU, 36, Color(c.r, c.g, c.b, _alpha * 0.5), 1.5)
