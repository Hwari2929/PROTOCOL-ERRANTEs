class_name DialogueSystem
extends Node
## 대화 진행 매니저
##
## CustomerAI ↔ DialogueSystem ↔ DialogueBubble(UI)
## 대화 시작 → NPC 대사 표시 → 플레이어 응답 선택 → 효과 적용 → 종료/연속
##
## BarManager 자식 노드 또는 독립 싱글톤으로 배치.

signal dialogue_started(customer: Node, entry: Dictionary)
signal response_selected(customer: Node, response: Dictionary)
signal dialogue_ended(customer: Node)

## 현재 대화 중인 손님
var active_customer: Node = null
## 현재 표시 중인 대화 항목
var active_entry: Dictionary = {}
## 대화 중 여부
var is_active: bool = false


## 대화 시작. CustomerAI와 UI에서 호출.
func start_dialogue(customer: Node) -> bool:
	if is_active:
		return false
	if customer == null:
		return false

	active_customer = customer
	is_active = true

	var context := _get_context_for_customer(customer)
	var dialogue_data := _get_dialogue_data(customer)
	if dialogue_data == null:
		_end_dialogue()
		return false

	active_entry = dialogue_data.pick_entry(context)
	if active_entry.is_empty():
		_end_dialogue()
		return false

	dialogue_started.emit(customer, active_entry)

	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.chat_started.emit(StringName(customer.name))

	return true


## 플레이어가 응답 선택. UI에서 호출.
func select_response(response_index: int) -> void:
	if not is_active or active_entry.is_empty():
		return

	var responses: Array = active_entry.get("responses", [])
	if response_index < 0 or response_index >= responses.size():
		_end_dialogue()
		return

	var response: Dictionary = responses[response_index]
	_apply_effect(response)
	response_selected.emit(active_customer, response)

	# 연속 대화 확인
	var next_context: StringName = response.get("next_context", &"")
	if next_context != &"":
		var dialogue_data := _get_dialogue_data(active_customer)
		if dialogue_data:
			active_entry = dialogue_data.pick_entry(next_context)
			if not active_entry.is_empty():
				dialogue_started.emit(active_customer, active_entry)
				return

	_end_dialogue()


## 대화 강제 종료.
func cancel_dialogue() -> void:
	if is_active:
		_end_dialogue()


## NPC 대사 텍스트 반환 (UI용).
func get_npc_line() -> String:
	return active_entry.get("npc_line", "")


## 현재 응답 선택지 목록 반환 (UI용).
func get_responses() -> Array:
	return active_entry.get("responses", [])


func _end_dialogue() -> void:
	var customer := active_customer
	active_customer = null
	active_entry = {}
	is_active = false

	if customer:
		dialogue_ended.emit(customer)
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.chat_ended.emit(StringName(customer.name))


func _apply_effect(response: Dictionary) -> void:
	if active_customer == null:
		return

	var effect: StringName = response.get("effect", &"none")
	var value: int = response.get("effect_value", 0)

	match effect:
		&"patience_up":
			if active_customer.get("_patience_remaining") != null:
				active_customer._patience_remaining = minf(
					active_customer._patience_remaining + value,
					active_customer._max_patience
				)
		&"satisfaction_up":
			if active_customer.get("customer_satisfaction") != null:
				active_customer.customer_satisfaction += value
		&"satisfaction_down":
			if active_customer.get("customer_satisfaction") != null:
				active_customer.customer_satisfaction -= value
		&"none":
			pass


## 손님의 현재 상태에 맞는 대화 문맥 결정.
func _get_context_for_customer(customer: Node) -> StringName:
	if not customer.get("current_state"):
		return &"idle"

	var state: int = customer.current_state
	# CustomerAI.State 값에 대응
	match state:
		3, 4:  # BROWSING, ORDERING
			return &"greeting"
		5:  # WAITING_FOR_ORDER
			return &"waiting"
		6:  # CONSUMING
			return &"eating"
		7:  # IDLE
			return &"idle"
		9:  # LEAVING
			return &"farewell"
		_:
			return &"idle"


## 손님에게 연결된 DialogueData 가져오기.
func _get_dialogue_data(customer: Node) -> DialogueData:
	if customer.get("customer_data") == null:
		return null
	var cdata: CustomerData = customer.customer_data
	# CustomerData에 dialogue_data 필드가 있으면 사용
	if cdata.get("dialogue") is DialogueData:
		return cdata.dialogue
	return null
