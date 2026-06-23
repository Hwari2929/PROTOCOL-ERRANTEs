extends Control

@onready var _resonance: Node = get_parent().get_parent().get_node_or_null("Resonance")
@onready var _battle_field: Node = get_node_or_null("../../BattleField")
@onready var _content: VBoxContainer = VBoxContainer.new()

var _rows: Array[Control] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    # 빈 영역 클릭이 뒤(전투 시작 버튼 등)로 통과하도록 — 자식 버튼은 그대로 입력 받음.
    _content.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # 가독성용 패널 배경.
    var bg: Panel = Panel.new()
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bg.anchor_left = 1.0
    bg.anchor_right = 1.0
    bg.anchor_top = 0.0
    bg.anchor_bottom = 0.0
    bg.offset_left = -258.0
    bg.offset_right = -8.0
    bg.offset_top = 104.0
    bg.offset_bottom = 320.0
    add_child(bg)
    var tape: Decor = Decor.tape(70.0, 22.0, -6.0)
    tape.position = Vector2(16.0, -11.0)
    bg.add_child(tape)

    add_child(_content)

    _content.anchor_top = 0.0
    _content.anchor_bottom = 0.0
    _content.anchor_left = 1.0
    _content.anchor_right = 1.0
    _content.offset_top = 114.0
    _content.offset_right = -18.0
    _content.offset_left = -248.0
    _content.offset_bottom = 470.0

    var _title: Label = Label.new()
    _title.text = "공명 강화"
    _title.add_theme_font_size_override("font_size", 19)
    var _hf: FontFile = Palette.font(Palette.F_HEAD)
    if _hf != null:
        _title.add_theme_font_override("font", _hf)
    _title.add_theme_color_override("font_color", Palette.ACCENT)
    _content.add_child(_title)

    refresh()

    if _battle_field:
        _battle_field.phase_changed.connect(_on_battle_field_phase_changed)
    if _resonance:
        _resonance.credits_changed.connect(_on_resonance_credits_changed)
    # Team changes free old units via queue_free (deferred) — refresh next frame so
    # the panel reflects the new roster, not the just-freed default trio.
    if EventBus.has_signal("team_changed"):
        EventBus.team_changed.connect(func(_ids): call_deferred("refresh"))

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
        if bool(_unit.get("is_special")):
            continue   # 특수 기물/시설은 공명도 강화 대상이 아님
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