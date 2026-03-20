class_name BarManager
extends Node
## 바 경영 로직 총괄
##
## GameManager.BAR_OPEN 상태에서만 동작.
## 씬 트리 구성 (Bar.tscn):
##   Bar (BarManager)
##   ├── MenuSystem
##   ├── CustomerSpawner
##   └── Seats (Node2D) ← 좌석 위치 마커들

## 바 레벨에 따른 설정
const MAX_LEVEL: int = 10
const BASE_CUSTOMER_CAPACITY: int = 3
const CAPACITY_PER_LEVEL: int = 1

## 영업 시간 (초 단위, 게임 내 하루)
const DEFAULT_BUSINESS_DURATION: float = 120.0

signal business_started
signal business_ended(total_income: int)
signal customer_capacity_changed(new_capacity: int)

@export var business_duration: float = DEFAULT_BUSINESS_DURATION

var bar_level: int = 1
var unlocked_menus: Array[StringName] = []
var is_open: bool = false
var daily_income: int = 0

var _business_timer: float = 0.0
var _active_customers: Array[Node] = []

@onready var menu_system: Node = $MenuSystem
@onready var customer_spawner: Node = $CustomerSpawner


func _ready() -> void:
	_connect_signals()


func _process(delta: float) -> void:
	if not is_open:
		return
	_business_timer -= delta
	if _business_timer <= 0.0:
		end_business()


## 영업 시작. GameManager.BAR_OPEN 진입 시 호출.
func start_business() -> void:
	if is_open:
		return
	is_open = true
	daily_income = 0
	_business_timer = business_duration
	_active_customers.clear()

	if customer_spawner and customer_spawner.has_method("start_spawning"):
		customer_spawner.start_spawning()

	business_started.emit()


## 영업 종료. 타이머 만료 또는 수동 호출.
func end_business() -> void:
	if not is_open:
		return
	is_open = false

	if customer_spawner and customer_spawner.has_method("stop_spawning"):
		customer_spawner.stop_spawning()

	_dismiss_all_customers()
	business_ended.emit(daily_income)

	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.bar_closed.emit()


## 수입 기록. MenuSystem에서 서빙 완료 시 호출.
func record_income(amount: int) -> void:
	daily_income += amount
	var rm := get_node_or_null("/root/ResourceManager")
	if rm and rm.has_method("add_gold"):
		rm.add_gold(amount)


## 손님 등록. CustomerSpawner에서 호출.
func register_customer(customer: Node) -> bool:
	if _active_customers.size() >= get_max_customers():
		return false
	_active_customers.append(customer)
	return true


## 손님 퇴장 처리.
func unregister_customer(customer: Node) -> void:
	_active_customers.erase(customer)


## 현재 최대 손님 수.
func get_max_customers() -> int:
	return BASE_CUSTOMER_CAPACITY + (bar_level - 1) * CAPACITY_PER_LEVEL


## 현재 손님 수.
func get_customer_count() -> int:
	return _active_customers.size()


## 남은 영업 시간.
func get_remaining_time() -> float:
	return max(_business_timer, 0.0)


## 바 레벨업.
func upgrade_bar() -> bool:
	if bar_level >= MAX_LEVEL:
		return false
	bar_level += 1
	customer_capacity_changed.emit(get_max_customers())
	return true


## 메뉴 해금.
func unlock_menu(menu_id: StringName) -> void:
	if menu_id not in unlocked_menus:
		unlocked_menus.append(menu_id)


## 메뉴 해금 여부 확인.
func is_menu_unlocked(menu_id: StringName) -> bool:
	return menu_id in unlocked_menus


func _connect_signals() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.bar_opened.connect(_on_bar_opened)
		bus.game_state_changed.connect(_on_game_state_changed)


func _on_bar_opened() -> void:
	start_business()


func _on_game_state_changed(old_state: StringName, new_state: StringName) -> void:
	if old_state == &"BAR_OPEN" and new_state == &"BAR_CLOSING":
		end_business()


func _dismiss_all_customers() -> void:
	for customer in _active_customers.duplicate():
		if customer and customer.has_method("leave"):
			customer.leave()
	_active_customers.clear()
