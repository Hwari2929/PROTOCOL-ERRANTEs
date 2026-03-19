class_name CustomerAI
extends Node2D
## 손님 행동 AI (개별 손님에 부착)
##
## 상태 머신:
##   ENTERING → MOVING_TO_SEAT → SEATED → ORDERING →
##   WAITING_FOR_ORDER → EATING → LEAVING
##
## 씬 구성 (CustomerNPC.tscn):
##   CustomerNPC (CustomerAI)
##   ├── Sprite2D
##   ├── NavigationAgent2D  (선택: 경로 탐색)
##   └── InteractionArea (Area2D)

enum State {
	ENTERING,
	MOVING_TO_SEAT,
	SEATED,
	ORDERING,
	WAITING_FOR_ORDER,
	EATING,
	LEAVING,
}

signal state_changed(old_state: State, new_state: State)
signal order_decided(menu_id: StringName)
signal satisfaction_calculated(value: int)

## 이동 속도 (픽셀/초)
@export var move_speed: float = 80.0
## 식사 시간 (초)
@export var eat_duration: float = 5.0
## 주문 결정까지 대기 시간
@export var order_delay: float = 2.0
## 주문 대기 인내심 (초). 초과 시 불만족 퇴장.
@export var patience: float = 30.0

var current_state: State = State.ENTERING
var assigned_seat: Node2D = null
var ordered_menu_id: StringName = &""
var customer_satisfaction: int = 0

var _target_position: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
var _patience_timer: float = 0.0
var _bar_manager: Node = null
var _menu_system: Node = null


func _ready() -> void:
	_bar_manager = _find_bar_manager()
	_menu_system = _find_menu_system()


func _process(delta: float) -> void:
	match current_state:
		State.ENTERING, State.MOVING_TO_SEAT:
			_process_movement(delta)
		State.SEATED:
			_process_seated(delta)
		State.ORDERING:
			_process_ordering()
		State.WAITING_FOR_ORDER:
			_process_waiting(delta)
		State.EATING:
			_process_eating(delta)
		State.LEAVING:
			_process_leaving(delta)


## 좌석 배정. CustomerSpawner에서 호출.
func assign_seat(seat: Node2D) -> void:
	assigned_seat = seat
	_target_position = seat.global_position
	_change_state(State.MOVING_TO_SEAT)


## 주문 수령. MenuSystem에서 서빙 완료 시 호출.
func receive_order(_order: Dictionary) -> void:
	if current_state != State.WAITING_FOR_ORDER:
		return
	var wait_ratio := _patience_timer / patience
	# 빨리 받을수록 만족도 보너스
	var speed_bonus := int((1.0 - wait_ratio) * 20.0)
	customer_satisfaction += speed_bonus
	_change_state(State.EATING)


## 강제 퇴장. BarManager 영업 종료 시 호출.
func leave() -> void:
	_change_state(State.LEAVING)


func _process_movement(delta: float) -> void:
	var direction := (_target_position - global_position)
	if direction.length() < 5.0:
		global_position = _target_position
		if current_state == State.ENTERING:
			# 입구 도착 → 좌석 이동은 assign_seat에서 트리거
			pass
		elif current_state == State.MOVING_TO_SEAT:
			_change_state(State.SEATED)
		return
	global_position += direction.normalized() * move_speed * delta


func _process_seated(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= order_delay:
		_change_state(State.ORDERING)


func _process_ordering() -> void:
	ordered_menu_id = _decide_menu()
	if ordered_menu_id == &"":
		# 메뉴가 없으면 그냥 떠남
		_change_state(State.LEAVING)
		return

	if _menu_system and _menu_system.has_method("place_order"):
		_menu_system.place_order(ordered_menu_id, self)

	order_decided.emit(ordered_menu_id)
	_change_state(State.WAITING_FOR_ORDER)


func _process_waiting(delta: float) -> void:
	_patience_timer += delta
	if _patience_timer >= patience:
		customer_satisfaction -= 20
		_change_state(State.LEAVING)


func _process_eating(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= eat_duration:
		# 기본 만족도 = 메뉴 satisfaction
		if _menu_system:
			var item: MenuItemData = _menu_system.get_menu_item(ordered_menu_id)
			if item:
				customer_satisfaction += item.satisfaction
		_change_state(State.LEAVING)


func _process_leaving(delta: float) -> void:
	# 화면 밖 퇴장 위치로 이동
	var exit_pos := Vector2(-100, global_position.y)
	var direction := (exit_pos - global_position)
	if direction.length() < 5.0:
		_on_left()
		return
	global_position += direction.normalized() * move_speed * delta


func _change_state(new_state: State) -> void:
	var old := current_state
	current_state = new_state
	_state_timer = 0.0

	if new_state == State.WAITING_FOR_ORDER:
		_patience_timer = 0.0

	state_changed.emit(old, new_state)


func _decide_menu() -> StringName:
	if _menu_system == null:
		return &""
	var menus := _menu_system.get_available_menus() as Array
	if menus.is_empty():
		return &""
	var chosen: MenuItemData = menus.pick_random()
	return chosen.id


func _on_left() -> void:
	satisfaction_calculated.emit(customer_satisfaction)

	if _bar_manager and _bar_manager.has_method("unregister_customer"):
		_bar_manager.unregister_customer(self)

	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.customer_left.emit(StringName(name))

	queue_free()


func _find_bar_manager() -> Node:
	var parent := get_parent()
	while parent:
		if parent is BarManager:
			return parent
		parent = parent.get_parent()
	return null


func _find_menu_system() -> Node:
	if _bar_manager and _bar_manager.has_method("get_node"):
		return _bar_manager.get_node_or_null("MenuSystem")
	return null
