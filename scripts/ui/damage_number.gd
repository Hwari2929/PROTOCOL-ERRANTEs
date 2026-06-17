extends Label
class_name DamageNumber
## Floating combat damage text. Spawns under a Node2D (world space), drifts up and
## fades, then frees itself.

static func spawn(parent: Node2D, pos: Vector2, amount: int, color: Color = Color.WHITE) -> void:
	spawn_text(parent, pos, str(amount), color)


## Floating text (skill names, etc.).
static func spawn_text(parent: Node2D, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var dn: Label = Label.new()
	dn.text = text
	dn.position = pos + Vector2(-8.0, -34.0)
	dn.z_index = 100
	dn.add_theme_font_size_override("font_size", 18)
	dn.add_theme_color_override("font_color", color)
	parent.add_child(dn)
	var t: Tween = dn.create_tween()
	t.set_parallel(true)
	t.tween_property(dn, "position:y", dn.position.y - 30.0, 0.6)
	t.tween_property(dn, "modulate:a", 0.0, 0.6)
	t.finished.connect(dn.queue_free)
