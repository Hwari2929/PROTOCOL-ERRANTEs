class_name MenuSystem
extends Node
## 메뉴 제작/서빙 시스템
##
## BarManager의 자식 노드로 동작.
## 주문 큐를 관리하고, 제작 시간 후 서빙 완료 처리.
## 의뢰(QUEST)도 동일한 파이프라인으로 처리 (craft_time = 수행 시간).

signal order_queued(order: Dictionary)
signal crafting_started(order: Dictionary)
signal crafting_completed(order: Dictionary)
signal order_served(order: Dictionary)
signal quest_completed(order: Dictionary)
signal recipe_crafting_requested(session: CraftingSession)

## 동시 제작 가능한 슬롯 수 (바 레벨/알바생으로 확장 가능)
@export var craft_slots: int = 1

## 등록된 메뉴 아이템 (id → MenuItemData)
var _menu_registry: Dictionary = {}

## 주문 대기열
var _order_queue: Array[Dictionary] = []

## 현재 제작 중인 주문 [{order, remaining_time}]
var _crafting: Array[Dictionary] = []

## 레시피 제조 대기 (플레이어 인터랙션 필요)
var _recipe_queue: Array[Dictionary] = []

## 현재 진행 중인 레시피 세션
var _active_session: CraftingSession = null


func _ready() -> void:
	_load_menu_registry()


func _process(delta: float) -> void:
	_process_crafting(delta)
	_try_start_next_craft()


## 메뉴 등록. 코드 또는 리소스 로더에서 호출.
func register_menu(item: MenuItemData) -> void:
	_menu_registry[item.id] = item


## 전체 등록된 메뉴 목록 반환.
func get_available_menus() -> Array[MenuItemData]:
	var result: Array[MenuItemData] = []
	for item in _menu_registry.values():
		result.append(item)
	return result


## 음식/음료 메뉴만 반환.
func get_consumable_menus() -> Array[MenuItemData]:
	var result: Array[MenuItemData] = []
	for item in _menu_registry.values():
		if item.is_consumable():
			result.append(item)
	return result


## 의뢰 메뉴만 반환.
func get_quest_menus() -> Array[MenuItemData]:
	var result: Array[MenuItemData] = []
	for item in _menu_registry.values():
		if item.is_quest():
			result.append(item)
	return result


## 특정 메뉴 데이터 조회.
func get_menu_item(menu_id: StringName) -> MenuItemData:
	return _menu_registry.get(menu_id, null)


## 손님의 메뉴 풀에서 주문 가능한 메뉴만 필터링.
func get_menus_for_customer(customer_data: CustomerData) -> Array[MenuItemData]:
	var result: Array[MenuItemData] = []
	if customer_data == null:
		return get_available_menus()
	for menu_id in customer_data.get_all_menu_ids():
		var item: MenuItemData = _menu_registry.get(menu_id, null)
		if item:
			result.append(item)
	return result


## 주문 접수. 큐에 추가.
func place_order(menu_id: StringName, customer: Node) -> bool:
	var item: MenuItemData = _menu_registry.get(menu_id, null)
	if item == null:
		push_warning("MenuSystem: 알 수 없는 메뉴 '%s'" % menu_id)
		return false

	var order := {
		"menu_id": menu_id,
		"item": item,
		"customer": customer,
		"status": "queued",
		"is_quest": item.is_quest(),
	}
	_order_queue.append(order)
	order_queued.emit(order)

	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.order_placed.emit(menu_id)

	return true


## 현재 대기 중인 주문 수.
func get_pending_count() -> int:
	return _order_queue.size()


## 현재 제작 중인 주문 수.
func get_crafting_count() -> int:
	return _crafting.size()


func _process_crafting(delta: float) -> void:
	var completed: Array[int] = []

	for i in range(_crafting.size()):
		_crafting[i]["remaining_time"] -= delta
		if _crafting[i]["remaining_time"] <= 0.0:
			completed.append(i)

	# 역순으로 제거하여 인덱스 유지
	completed.reverse()
	for idx in completed:
		var craft := _crafting[idx]
		_crafting.remove_at(idx)
		_complete_order(craft["order"])


func _try_start_next_craft() -> void:
	while _crafting.size() < craft_slots and _order_queue.size() > 0:
		var order := _order_queue.pop_front() as Dictionary
		var item: MenuItemData = order["item"]

		# 레시피가 있는 메뉴 → 레시피 큐로 이동
		if item.has_recipe() and _active_session == null:
			order["status"] = "recipe_pending"
			_start_recipe_session(order)
			continue
		elif item.has_recipe():
			# 이미 레시피 세션 진행 중이면 다시 큐에 넣지 않고 대기
			_recipe_queue.append(order)
			continue

		order["status"] = "crafting"
		var craft := {
			"order": order,
			"remaining_time": item.craft_time,
		}
		_crafting.append(craft)
		crafting_started.emit(order)


## 레시피 세션 시작. CraftingPanel(UI)로 전달.
func _start_recipe_session(order: Dictionary) -> void:
	var item: MenuItemData = order["item"]
	var registry := _find_content_registry()
	if registry == null:
		# 레지스트리 없으면 자동 제작으로 폴백
		_fallback_auto_craft(order)
		return

	var recipe: RecipeData = registry.get_recipe(item.recipe_id)
	if recipe == null:
		_fallback_auto_craft(order)
		return

	_active_session = CraftingSession.new(recipe, order)
	_active_session.session_completed.connect(_on_recipe_completed.bind(order))
	recipe_crafting_requested.emit(_active_session)


## 레시피 제조 완료 콜백.
func _on_recipe_completed(quality: float, choices: Dictionary, order: Dictionary) -> void:
	var item: MenuItemData = order["item"]

	# 품질에 따른 만족도/가격 보정
	order["quality"] = quality
	order["recipe_choices"] = choices
	order["satisfaction_bonus"] = _active_session.total_satisfaction_modifier
	order["price_bonus"] = _active_session.total_price_modifier

	_active_session = null

	# 마무리 시간 후 서빙
	order["status"] = "crafting"
	var recipe: RecipeData = _find_content_registry().get_recipe(item.recipe_id) if _find_content_registry() else null
	var finish := recipe.finish_time if recipe else 0.5
	var craft := {
		"order": order,
		"remaining_time": finish,
	}
	_crafting.append(craft)
	crafting_completed.emit(order)

	# 레시피 대기열에서 다음 세션 시작
	if not _recipe_queue.is_empty():
		var next_order := _recipe_queue.pop_front() as Dictionary
		_start_recipe_session(next_order)


func _fallback_auto_craft(order: Dictionary) -> void:
	order["status"] = "crafting"
	var craft := {
		"order": order,
		"remaining_time": order["item"].craft_time,
	}
	_crafting.append(craft)
	crafting_started.emit(order)


func _complete_order(order: Dictionary) -> void:
	order["status"] = "completed"
	crafting_completed.emit(order)

	if order.get("is_quest", false):
		_complete_quest(order)
	else:
		_serve_order(order)


func _serve_order(order: Dictionary) -> void:
	var item: MenuItemData = order["item"]
	var customer: Node = order.get("customer")

	# 골드 수입 처리 (레시피 보정 포함)
	var final_price := item.base_price + order.get("price_bonus", 0)
	var bar_manager := get_parent()
	if bar_manager and bar_manager.has_method("record_income"):
		bar_manager.record_income(final_price)

	# 손님에게 서빙 알림
	if customer and is_instance_valid(customer) and customer.has_method("receive_order"):
		customer.receive_order(order)

	order["status"] = "served"
	order_served.emit(order)

	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.order_served.emit(item.id)


func _complete_quest(order: Dictionary) -> void:
	var item: MenuItemData = order["item"]
	var customer: Node = order.get("customer")

	# 의뢰 보수 지급
	var bar_manager := get_parent()
	if bar_manager and bar_manager.has_method("record_income"):
		bar_manager.record_income(item.base_price)

	# 손님에게 완료 알림
	if customer and is_instance_valid(customer) and customer.has_method("receive_order"):
		customer.receive_order(order)

	order["status"] = "quest_completed"
	quest_completed.emit(order)
	order_served.emit(order)

	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.order_served.emit(item.id)
		bus.quest_completed.emit(item.id)


## 현재 레시피 세션 반환 (UI 연결용).
func get_active_session() -> CraftingSession:
	return _active_session


func _find_content_registry() -> Node:
	return get_node_or_null("/root/ContentRegistry")


## resources/menus/ 폴더에서 메뉴 리소스를 자동 로드.
func _load_menu_registry() -> void:
	var dir_path := "res://resources/menus/"
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(dir_path + file_name)
			if res is MenuItemData:
				register_menu(res)
		file_name = dir.get_next()
	dir.list_dir_end()
