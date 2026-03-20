class_name CraftingPanel
extends Control
## 단계별 제조 UI 패널
##
## CraftingSession의 각 단계를 시각적으로 표시.
## 플레이어가 선택지 버튼을 눌러 제조를 진행.
##
## 씬 구성 (CraftingPanel.tscn):
##   CraftingPanel (Control, script: CraftingPanel.gd)
##   ├── Header (Label)          — 단계 안내 텍스트
##   ├── ChoiceContainer (HBoxContainer)  — 선택지 버튼 목록
##   ├── ProgressBar (ProgressBar)  — 진행률 표시
##   └── ResultLabel (Label)     — 완료 시 결과 표시

signal choice_made(step_index: int, choice_id: StringName)
signal crafting_finished(session: CraftingSession)

var _session: CraftingSession = null

@onready var header: Label = $Header
@onready var choice_container: HBoxContainer = $ChoiceContainer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var result_label: Label = $ResultLabel


func _ready() -> void:
	visible = false


## 제조 세션 시작. MenuSystem에서 호출.
func start_session(session: CraftingSession) -> void:
	_session = session
	visible = true
	if result_label:
		result_label.visible = false

	session.step_advanced.connect(_on_step_advanced)
	session.session_completed.connect(_on_session_completed)

	_display_current_step()


## 현재 단계 표시.
func _display_current_step() -> void:
	if _session == null:
		return

	var step := _session.get_current_step()
	if step == null:
		return

	if header:
		header.text = step.prompt_text
	if progress_bar:
		progress_bar.value = _session.get_progress() * 100.0

	_clear_choices()

	var choices := _session.get_current_choices()
	for choice in choices:
		_add_choice_button(choice)


func _add_choice_button(choice: RecipeChoice) -> void:
	if choice_container == null:
		return
	var btn := Button.new()
	btn.text = choice.display_name
	btn.custom_minimum_size = Vector2(120, 60)
	btn.pressed.connect(_on_choice_pressed.bind(choice.id))
	choice_container.add_child(btn)


func _clear_choices() -> void:
	if choice_container == null:
		return
	for child in choice_container.get_children():
		child.queue_free()


func _on_choice_pressed(choice_id: StringName) -> void:
	if _session == null:
		return
	var step_idx := _session.current_step_index
	_session.select_choice(choice_id)
	choice_made.emit(step_idx, choice_id)


func _on_step_advanced(_step_index: int, _step: RecipeStep) -> void:
	_display_current_step()


func _on_session_completed(quality: float, _choices: Dictionary) -> void:
	_clear_choices()
	if header:
		header.text = "완성!"
	if progress_bar:
		progress_bar.value = 100.0
	if result_label:
		result_label.visible = true
		var grade := "S" if quality >= 1.0 else ("A" if quality >= 0.7 else ("B" if quality >= 0.4 else "C"))
		result_label.text = "품질: %s (%.0f%%)" % [grade, quality * 100.0]

	crafting_finished.emit(_session)

	# 잠시 후 패널 닫기
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(_close_panel)


func _close_panel() -> void:
	visible = false
	_session = null
