extends Control

var _background: ColorRect
var _center_container: CenterContainer
var _vbox: VBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _record_label: Label
var _start_button: Button

func _ready() -> void:
	# 종이 질감 배경 (영수증/빈티지 매너) — 뒤 전장을 가린다.
	if ResourceLoader.exists("res://assets/ui/paper.png"):
		var tex := TextureRect.new()
		tex.texture = load("res://assets/ui/paper.png")
		tex.modulate = Palette.PAPER0
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(tex)
	_background = ColorRect.new()
	_background.color = Color(Palette.PAPER2, 0.35) if ResourceLoader.exists("res://assets/ui/paper.png") else Palette.PAPER1
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP  # block the screen behind
	add_child(_background)

	# Center container for layout
	_center_container = CenterContainer.new()
	_center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_center_container)

	# Vertical box for stacking elements
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 16)
	_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center_container.add_child(_vbox)

	# Title Label
	_title_label = Label.new()
	_title_label.text = "PROTOCOL ERRANTES"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var emphasis: FontFile = load("res://assets/fonts/Paperlogy-8ExtraBold.ttf")
	if emphasis != null:
		_title_label.add_theme_font_override("font", emphasis)
	_title_label.add_theme_font_size_override("font_size", 66)
	_title_label.add_theme_color_override("font_color", Palette.ACCENT)
	_title_label.add_theme_color_override("font_outline_color", Palette.PAPER0)
	_title_label.add_theme_constant_override("outline_size", 6)
	_vbox.add_child(_title_label)

	# Subtitle Label
	_subtitle_label = Label.new()
	_subtitle_label.text = "전술 오토배틀러"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 24)
	_subtitle_label.add_theme_color_override("font_color", Palette.INK2)
	_vbox.add_child(_subtitle_label)

	# Persistent record line — 모노 카탈로그 라벨(대문자)
	_record_label = Label.new()
	var rec: Dictionary = SaveStore.load_record()
	_record_label.text = "BEST %d NODES   ·   WINS %d / %d RUNS" % [int(rec["best_nodes"]), int(rec["wins"]), int(rec["runs"])]
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.add_theme_font_size_override("font_size", 14)
	var mono: FontFile = Palette.font(Palette.F_MONO)
	if mono != null:
		_record_label.add_theme_font_override("font", mono)
	_record_label.add_theme_color_override("font_color", Palette.INK3)
	_vbox.add_child(_record_label)

	# Start Button
	_start_button = Button.new()
	_start_button.text = "▶  시작"
	_start_button.add_theme_font_size_override("font_size", 26)
	_start_button.custom_minimum_size = Vector2(260.0, 64.0)
	_start_button.pressed.connect(dismiss)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	_vbox.add_child(spacer)
	_vbox.add_child(_start_button)

	# BINDER 재질: 비스듬한 고무 도장(아카이브 표지 느낌).
	var stamp := Decor.stamp("CASE No.2049", -11.0, 186.0, 48.0)
	stamp.position = Vector2(936.0, 96.0)
	add_child(stamp)

func dismiss() -> void:
	visible = false

func refresh() -> void:
	visible = true