extends Control

var _background: ColorRect
var _center_container: CenterContainer
var _vbox: VBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _record_label: Label
var _start_button: Button

func _ready() -> void:
	# Full-screen dark background
	_background = ColorRect.new()
	_background.color = Color(0.04, 0.04, 0.06, 1.0)
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
	_title_label.add_theme_font_size_override("font_size", 60)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	_vbox.add_child(_title_label)

	# Subtitle Label
	_subtitle_label = Label.new()
	_subtitle_label.text = "전술 오토배틀러"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 24)
	_subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_vbox.add_child(_subtitle_label)

	# Persistent record line
	_record_label = Label.new()
	var rec: Dictionary = SaveStore.load_record()
	_record_label.text = "Best: %d nodes   ·   Wins %d / %d runs" % [int(rec["best_nodes"]), int(rec["wins"]), int(rec["runs"])]
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.add_theme_font_size_override("font_size", 16)
	_record_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	_vbox.add_child(_record_label)

	# Start Button
	_start_button = Button.new()
	_start_button.text = "시작"
	_start_button.add_theme_font_size_override("font_size", 24)
	_start_button.add_theme_color_override("font_color", Color.WHITE)
	_start_button.pressed.connect(dismiss)
	_vbox.add_child(_start_button)

func dismiss() -> void:
	visible = false

func refresh() -> void:
	visible = true