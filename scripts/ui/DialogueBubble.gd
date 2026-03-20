class_name DialogueBubble
extends Control
## 말풍선 UI 컨트롤러
##
## 손님 위에 표시되는 말풍선. NPC 대사 + 플레이어 응답 버튼.
## DialogueSystem과 연동하여 대화를 시각적으로 표현.
##
## 씬 구성 (DialogueBubble.tscn):
##   DialogueBubble (Control, script: DialogueBubble.gd)
##   ├── BubblePanel (NinePatchRect 또는 Panel)
##   │   ├── NPCLabel (RichTextLabel)  — NPC 대사 텍스트
##   │   └── ResponseContainer (VBoxContainer)  — 응답 버튼 목록
##   └── BubbleTail (TextureRect)  — 말풍선 꼬리

signal response_pressed(response_index: int)
signal bubble_closed

@export var type_speed: float = 30.0  ## 타자기 효과 속도 (글자/초)
@export var auto_close_delay: float = 3.0  ## 응답 없는 대사 자동 닫힘 (초)

var _dialogue_system: Node = null
var _target_customer: Node = null
var _is_typing: bool = false
var _displayed_chars: int = 0
var _full_text: String = ""
var _auto_close_timer: float = 0.0

@onready var npc_label: RichTextLabel = $BubblePanel/NPCLabel
@onready var response_container: VBoxContainer = $BubblePanel/ResponseContainer


func _ready() -> void:
	visible = false
	_find_dialogue_system()


func _process(delta: float) -> void:
	_update_position()
	_process_typing(delta)
	_process_auto_close(delta)


## 말풍선 열기. DialogueSystem에서 대화 시작 시 호출.
func show_dialogue(customer: Node, entry: Dictionary) -> void:
	_target_customer = customer
	visible = true
	_clear_responses()

	# NPC 대사 타자기 효과
	_full_text = entry.get("npc_line", "")
	_displayed_chars = 0
	_is_typing = true
	if npc_label:
		npc_label.text = ""

	# 응답 버튼 생성
	var responses: Array = entry.get("responses", [])
	if responses.is_empty():
		_auto_close_timer = auto_close_delay
	else:
		_auto_close_timer = 0.0
		for i in range(responses.size()):
			_add_response_button(i, responses[i])


## 말풍선 닫기.
func hide_dialogue() -> void:
	visible = false
	_target_customer = null
	_is_typing = false
	_auto_close_timer = 0.0
	_clear_responses()
	bubble_closed.emit()


## 타자기 효과 스킵 (탭/클릭 시).
func skip_typing() -> void:
	if _is_typing:
		_is_typing = false
		_displayed_chars = _full_text.length()
		if npc_label:
			npc_label.text = _full_text


func _process_typing(delta: float) -> void:
	if not _is_typing or npc_label == null:
		return
	_displayed_chars += int(type_speed * delta)
	if _displayed_chars >= _full_text.length():
		_displayed_chars = _full_text.length()
		_is_typing = false
	npc_label.text = _full_text.substr(0, _displayed_chars)


func _process_auto_close(delta: float) -> void:
	if _auto_close_timer <= 0.0 or _is_typing:
		return
	_auto_close_timer -= delta
	if _auto_close_timer <= 0.0:
		hide_dialogue()


func _update_position() -> void:
	if _target_customer == null or not is_instance_valid(_target_customer):
		hide_dialogue()
		return
	# 손님 머리 위에 말풍선 배치
	var target_pos: Vector2 = _target_customer.global_position + Vector2(0, -80)
	global_position = target_pos - size * Vector2(0.5, 1.0)


func _add_response_button(index: int, response: Dictionary) -> void:
	if response_container == null:
		return
	var btn := Button.new()
	btn.text = response.get("text", "...")
	btn.pressed.connect(_on_response_pressed.bind(index))
	response_container.add_child(btn)


func _clear_responses() -> void:
	if response_container == null:
		return
	for child in response_container.get_children():
		child.queue_free()


func _on_response_pressed(index: int) -> void:
	response_pressed.emit(index)
	if _dialogue_system and _dialogue_system.has_method("select_response"):
		_dialogue_system.select_response(index)


func _find_dialogue_system() -> void:
	# BarManager 트리에서 검색
	var parent := get_parent()
	while parent:
		var ds := parent.get_node_or_null("DialogueSystem")
		if ds:
			_dialogue_system = ds
			ds.dialogue_started.connect(show_dialogue)
			ds.dialogue_ended.connect(_on_dialogue_ended)
			return
		parent = parent.get_parent()


func _on_dialogue_ended(_customer: Node) -> void:
	hide_dialogue()
