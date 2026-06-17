extends Control

@onready var _resonance: Node = get_parent().get_parent().get_node_or_null("Resonance")
@onready var _battle_field: Node = get_node_or_null("../../BattleField")
@onready var _content: VBoxContainer = VBoxContainer.new()

var _rows: Array[Control] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_content)

    _content.anchor_top = 0.0
    _content.anchor_bottom = 0.0
    _content.anchor_left = 1.0
    _content.anchor_right = 1.0
    _content.offset_top = 110.0
    _content.offset_right = -16.0
    _content.offset_left = -250.0
    _content.offset_bottom = 470.0

    var _title: Label = Label.new()
    _title.text = "공명 강화"
    _title.add_theme_font_size_override("font_size", 20)
    _content.add_child(_title)

    refresh()

    if _battle_field:
        _battle_field.phase_changed.connect(_on_battle_field_phase_changed)
    if _resonance:
        _resonance.credits_changed.connect(_on_resonance_credits_changed)

func _on_battle_field_phase_changed(phase: int) -> void:
    visible = (phase == 0)
    refresh()

func _on_resonance_credits_changed() -> void:
    refresh()

func refresh() -> void:
    for _row in _rows:
        _row.queue_free()
    _rows.clear()

    if not _battle_field or not _resonance:
        return

    var _units: Array = _battle_field.units_of(0)
    for _unit in _units:
        var _hbox: HBoxContainer = HBoxContainer.new()

        var _label: Label = Label.new()
        _label.text = ClassData.class_label(_unit.sprite_id) + " 등급 " + str(_unit.current_res_grade())
        _label.add_theme_font_size_override("font_size", 16)
        _hbox.add_child(_label)

        var _button: Button = Button.new()
        _button.text = "공명 (8c)"
        _button.disabled = (_resonance.credits < 8)
        _button.add_theme_font_size_override("font_size", 16)
        _button.pressed.connect(func(): _on_resonate_pressed(_unit))
        _hbox.add_child(_button)

        _content.add_child(_hbox)
        _rows.append(_hbox)

func _on_resonate_pressed(unit: Node) -> void:
    if not _resonance:
        return
    if _resonance.credits >= 8:
        _resonance.credits -= 8
        _resonance.credits_changed.emit(_resonance.credits)
        var gained: int = unit.gain_resonance(8)
        if gained > 0:
            if unit.current_res_grade() >= 2 and not unit.has_subclass():
                var _subclass_menu: Node = get_parent().get_node_or_null("SubclassMenu")
                if _subclass_menu:
                    _subclass_menu.show_for(unit)
            else:
                var _augment_system: Node = get_parent().get_node_or_null("AugmentSystem")
                if _augment_system:
                    _augment_system.show_menu(3)
        refresh()