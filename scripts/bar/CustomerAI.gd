class_name CustomerAI
extends Node2D
## 손님 행동 AI (개별 손님에 부착)
##
## 상태 머신:
##   ENTERING → MOVING_TO_SEAT → SEATED → BROWSING → ORDERING →
##   WAITING_FOR_ORDER → CONSUMING → IDLE → (ORDERING | CHATTING | LEAVING)
##
## IDLE에서 추가 주문, 의뢰 제안, 대화가 가능.
## 대화(CHATTING)는 인내심 타이머를 회복시킨다.
## 의뢰는 MenuItemData.MenuType.QUEST 타입의 메뉴로 처리.
##
## 씬 구성 (CustomerNPC.tscn):
##   CustomerNPC (CustomerAI)
##   ├── Sprite2D
##   ├── NavigationAgent2D  (선택)
##   └── InteractionArea (Area2D)

enum State {
	ENTERING,
	MOVING_TO_SEAT,
	SEATED,
	BROWSING,
	ORDERING,
	WAITING_FOR_ORDER,
	CONSUMING,
	IDLE,
	CHATTING,
	LEAVING,
}

signal state_changed(old_state: State, new_state: State)
signal order_decided(menu_id: StringName)
signal chat_started
signal chat_ended(patience_gained: float)
signal quest_proposed(menu_id: StringName)
signal satisfaction_calculated(value: int)

## 이동 속도 (픽셀/초)
@export var move_speed: float = 80.0
## 대화 지속 시간 (초)
@export var chat_duration: float = 4.0

## 손님 유형 데이터. CustomerSpawner에서 주입.
var customer_data: CustomerData = null

var current_state: State = State.ENTERING
var assigned_seat: Node2D = null
var customer_satisfaction: int = 0

## 현재 주문한 메뉴 ID
var _current_order_id: StringName = &""
## 지금까지 주문한 횟수
var _orders_placed: int = 0
## 주문한 메뉴 이력
var _order_history: Array[StringName] = []

var _target_position: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
## 전체 체류 인내심 타이머 (감소형)
var _patience_remaining: float = 60.0
var _max_patience: float = 60.0
var _bar_manager: Node = null
var _menu_system: Node = null


func _ready() -> void:
	_bar_manager = _find_bar_manager()
	_menu_system = _find_menu_system()
	_apply_customer_data()


func _process(delta: float) -> void:
	# 인내심은 SEATED 이후 항상 감소 (CHATTING, CONSUMING 중엔 감소 안 함)
	if _should_drain_patience():
		_patience_remaining -= delta
		if _patience_remaining <= 0.0:
			customer_satisfaction -= 20
			_change_state(State.LEAVING)
			return

	match current_state:
		State.ENTERING, State.MOVING_TO_SEAT:
			_process_movement(delta)
		State.SEATED, State.BROWSING:
			_process_browsing(delta)
		State.ORDERING:
			_process_ordering()
		State.WAITING_FOR_ORDER:
			_process_waiting(delta)
		State.CONSUMING:
			_process_consuming(delta)
		State.IDLE:
			_process_idle(delta)
		State.CHATTING:
			_process_chatting(delta)
		State.LEAVING:
			_process_leaving(delta)


# === 공개 API ===

## 좌석 배정. CustomerSpawner에서 호출.
func assign_seat(seat: Node2D) -> void:
	assigned_seat = seat
	_target_position = seat.global_position
	_change_state(State.MOVING_TO_SEAT)


## 손님 유형 데이터 설정. CustomerSpawner에서 호출.
func setup(data: CustomerData) -> void:
	customer_data = data
	_apply_customer_data()


## 주문 수령. MenuSystem에서 서빙 완료 시 호출.
func receive_order(order: Dictionary) -> void:
	if current_state != State.WAITING_FOR_ORDER:
		return
	var item: MenuItemData = order.get("item")
	if item == null:
		return

	# 대기 시간 비례 만족도 보너스
	var waited := _max_patience - _patience_remaining
	var wait_ratio := waited / _max_patience if _max_patience > 0 else 0.0
	var speed_bonus := int((1.0 - clampf(wait_ratio, 0.0, 1.0)) * 20.0)
	customer_satisfaction += speed_bonus

	if item.is_quest():
		# 의뢰는 바로 IDLE로 (소비 과정 없음)
		customer_satisfaction += item.satisfaction
		_change_state(State.IDLE)
	else:
		_change_state(State.CONSUMING)


## 플레이어가 대화 시작. UI 또는 상호작용 트리거에서 호출.
func start_chat() -> void:
	if current_state not in [State.IDLE, State.WAITING_FOR_ORDER, State.BROWSING]:
		return
	_change_state(State.CHATTING)
	chat_started.emit()


## 강제 퇴장. BarManager 영업 종료 시 호출.
func leave() -> void:
	_change_state(State.LEAVING)


## 현재 인내심 비율 (0.0~1.0). UI 표시용.
func get_patience_ratio() -> float:
	return clampf(_patience_remaining / _max_patience, 0.0, 1.0) if _max_patience > 0 else 0.0


## 남은 주문 가능 횟수.
func get_remaining_orders() -> int:
	var max_orders := customer_data.max_orders if customer_data else 1
	return max(max_orders - _orders_placed, 0)


# === 상태별 처리 ===

func _process_movement(delta: float) -> void:
	var direction := (_target_position - global_position)
	if direction.length() < 5.0:
		global_position = _target_position
		if current_state == State.MOVING_TO_SEAT:
			_change_state(State.BROWSING)
		return
	global_position += direction.normalized() * move_speed * delta


func _process_browsing(delta: float) -> void:
	_state_timer += delta
	var delay := customer_data.order_delay if customer_data else 2.0
	if _state_timer >= delay:
		_change_state(State.ORDERING)


func _process_ordering() -> void:
	_current_order_id = _decide_menu()
	if _current_order_id == &"":
		_change_state(State.LEAVING)
		return

	if _menu_system and _menu_system.has_method("place_order"):
		_menu_system.place_order(_current_order_id, self)

	_orders_placed += 1
	_order_history.append(_current_order_id)
	order_decided.emit(_current_order_id)

	# 의뢰 메뉴인지 확인하여 시그널 발신
	if _menu_system:
		var item: MenuItemData = _menu_system.get_menu_item(_current_order_id)
		if item and item.is_quest():
			quest_proposed.emit(_current_order_id)

	_change_state(State.WAITING_FOR_ORDER)


func _process_waiting(_delta: float) -> void:
	# 인내심 감소는 _process()에서 전역 처리
	pass


func _process_consuming(delta: float) -> void:
	_state_timer += delta
	var duration := customer_data.consume_duration if customer_data else 5.0
	if _state_timer >= duration:
		# 만족도 추가
		if _menu_system:
			var item: MenuItemData = _menu_system.get_menu_item(_current_order_id)
			if item:
				customer_satisfaction += item.satisfaction
		_change_state(State.IDLE)


func _process_idle(delta: float) -> void:
	_state_timer += delta
	var idle_dur := customer_data.idle_duration if customer_data else 8.0
	if _state_timer >= idle_dur:
		_decide_next_action()


func _process_chatting(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= chat_duration:
		# 대화 완료 → 인내심 회복
		var bonus := customer_data.chat_patience_bonus if customer_data else 10.0
		_patience_remaining = minf(_patience_remaining + bonus, _max_patience)
		customer_satisfaction += 5
		chat_ended.emit(bonus)
		_change_state(State.IDLE)


func _process_leaving(delta: float) -> void:
	var exit_pos := Vector2(-100, global_position.y)
	var direction := (exit_pos - global_position)
	if direction.length() < 5.0:
		_on_left()
		return
	global_position += direction.normalized() * move_speed * delta


# === 의사결정 ===

## IDLE 상태에서 다음 행동 결정.
func _decide_next_action() -> void:
	var max_orders := customer_data.max_orders if customer_data else 1

	# 추가 주문 가능 여부
	if _orders_placed < max_orders:
		var reorder := customer_data.reorder_chance if customer_data else 0.0
		if randf() < reorder:
			_change_state(State.BROWSING)
			return

	# 더 이상 주문할 게 없으면 퇴장
	_change_state(State.LEAVING)


## 메뉴 풀에서 주문할 메뉴 선택.
func _decide_menu() -> StringName:
	if customer_data:
		# 의뢰 확률 체크 (의뢰 메뉴가 풀에 있을 때)
		if _menu_system and randf() < customer_data.quest_chance:
			var quest_menus := customer_data.get_quest_menus(_menu_system)
			# 이미 주문한 의뢰는 제외
			var available_quests: Array[StringName] = []
			for qm in quest_menus:
				if qm not in _order_history:
					available_quests.append(qm)
			if not available_quests.is_empty():
				return available_quests.pick_random()

		# 일반 메뉴 선택 (CustomerData의 가중치 기반)
		return customer_data.pick_menu(_menu_system)

	# customer_data가 없으면 MenuSystem 전체에서 랜덤
	if _menu_system == null:
		return &""
	var menus := _menu_system.get_available_menus() as Array
	if menus.is_empty():
		return &""
	var chosen: MenuItemData = menus.pick_random()
	return chosen.id


# === 내부 유틸 ===

## 인내심이 감소해야 하는 상태인지 확인.
func _should_drain_patience() -> bool:
	return current_state in [
		State.BROWSING, State.ORDERING, State.WAITING_FOR_ORDER, State.IDLE
	]


func _apply_customer_data() -> void:
	if customer_data == null:
		return
	_patience_remaining = customer_data.base_patience
	_max_patience = customer_data.base_patience


func _change_state(new_state: State) -> void:
	var old := current_state
	current_state = new_state
	_state_timer = 0.0
	state_changed.emit(old, new_state)


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
	if _bar_manager:
		return _bar_manager.get_node_or_null("MenuSystem")
	return null
