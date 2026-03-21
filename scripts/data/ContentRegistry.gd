class_name ContentRegistry
extends Node
## 콘텐츠 레지스트리 — 코드 기반 데이터 정의
##
## .tres 에디터 편집이 불가능한 환경에서 사용.
## 손님, 메뉴, 레시피를 코드로 생성하여 각 시스템에 등록.
## Autoload 또는 BarManager._ready()에서 호출.

## 등록된 레시피 (recipe_id → RecipeData)
var _recipes: Dictionary = {}
## 등록된 손님 데이터 (customer_id → CustomerData)
var _customers: Dictionary = {}


func _ready() -> void:
	_register_recipes()
	_register_menus()
	_register_customers()


# === 레시피 조회 ===

func get_recipe(recipe_id: StringName) -> RecipeData:
	return _recipes.get(recipe_id, null)


func get_customer_data(customer_id: StringName) -> CustomerData:
	return _customers.get(customer_id, null)


func get_all_customer_data() -> Array[CustomerData]:
	var result: Array[CustomerData] = []
	for v in _customers.values():
		result.append(v)
	return result


# === 레시피 등록 ===

func _register_recipes() -> void:
	_register_ice_water_recipe()


func _register_ice_water_recipe() -> void:
	var recipe := RecipeData.new()
	recipe.id = &"recipe_ice_water"
	recipe.display_name = "얼음물 제조"

	# --- Step 1: 컵 선택 ---
	var step_cup := RecipeStep.new()
	step_cup.prompt_text = "컵을 선택하세요"

	var cup_small := RecipeChoice.new()
	cup_small.id = &"small_cup"
	cup_small.display_name = "작은 컵"
	cup_small.price_modifier = -2
	cup_small.satisfaction_modifier = -3

	var cup_medium := RecipeChoice.new()
	cup_medium.id = &"medium_cup"
	cup_medium.display_name = "중간 컵"
	cup_medium.price_modifier = 0
	cup_medium.satisfaction_modifier = 0

	step_cup.choices = [cup_small, cup_medium]

	# --- Step 2: 음료 선택 ---
	var step_drink := RecipeStep.new()
	step_drink.prompt_text = "음료를 선택하세요"

	var drink_water := RecipeChoice.new()
	drink_water.id = &"water"
	drink_water.display_name = "물"
	drink_water.price_modifier = 0
	drink_water.satisfaction_modifier = 0

	var drink_juice := RecipeChoice.new()
	drink_juice.id = &"juice"
	drink_juice.display_name = "주스"
	drink_juice.price_modifier = 5
	drink_juice.satisfaction_modifier = 5

	step_drink.choices = [drink_water, drink_juice]

	# --- Step 3: 얼음 양 선택 ---
	var step_ice := RecipeStep.new()
	step_ice.prompt_text = "얼음을 선택하세요"

	var ice_none := RecipeChoice.new()
	ice_none.id = &"no_ice"
	ice_none.display_name = "없음"
	ice_none.satisfaction_modifier = -5

	var ice_crushed := RecipeChoice.new()
	ice_crushed.id = &"crushed_ice"
	ice_crushed.display_name = "잔얼음"
	ice_crushed.satisfaction_modifier = 2

	var ice_cubed := RecipeChoice.new()
	ice_cubed.id = &"cubed_ice"
	ice_cubed.display_name = "각얼음"
	ice_cubed.satisfaction_modifier = 3

	step_ice.choices = [ice_none, ice_crushed, ice_cubed]

	recipe.steps = [step_cup, step_drink, step_ice]
	# 정답 조합: 중간 컵 + 물 + 각얼음
	recipe.ideal_combination = {0: &"medium_cup", 1: &"water", 2: &"cubed_ice"}
	recipe.finish_time = 0.5

	_recipes[recipe.id] = recipe


# === 메뉴 등록 ===

func _register_menus() -> void:
	_register_menu_ice_water()
	_register_menu_juice()
	_register_menu_hot_water()
	_register_menu_simple_cocktail()
	_register_menu_amundsen_signature()
	_register_menu_velvet_signature()
	_register_menu_doran_signature()
	_register_menu_haze_signature()
	_register_menu_pike_signature()


func _register_menu_ice_water() -> void:
	var item := MenuItemData.new()
	item.id = &"ice_water"
	item.display_name = "얼음물"
	item.description = "시원한 얼음물. 가장 기본적인 메뉴."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 5
	item.craft_time = 1.0
	item.satisfaction = 8
	item.unlock_level = 1
	item.recipe_id = &"recipe_ice_water"
	_register_to_menu_system(item)


func _register_menu_juice() -> void:
	var item := MenuItemData.new()
	item.id = &"juice"
	item.display_name = "주스"
	item.description = "과일 주스. 달콤하고 시원하다."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 12
	item.craft_time = 2.0
	item.satisfaction = 12
	item.unlock_level = 1
	_register_to_menu_system(item)


func _register_menu_hot_water() -> void:
	var item := MenuItemData.new()
	item.id = &"hot_water"
	item.display_name = "따뜻한 물"
	item.description = "몸을 녹여주는 따뜻한 물."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 3
	item.craft_time = 1.5
	item.satisfaction = 6
	item.unlock_level = 1
	_register_to_menu_system(item)


func _register_menu_simple_cocktail() -> void:
	var item := MenuItemData.new()
	item.id = &"simple_cocktail"
	item.display_name = "심플 칵테일"
	item.description = "간단한 칵테일. 분위기를 띄운다."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 20
	item.craft_time = 3.0
	item.satisfaction = 18
	item.unlock_level = 1
	_register_to_menu_system(item)


func _register_menu_amundsen_signature() -> void:
	var item := MenuItemData.new()
	item.id = &"polar_frost"
	item.display_name = "폴라 프로스트"
	item.description = "Amundsen 전용 시그니처. 극지방의 냉기를 담은 특제 음료."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 30
	item.craft_time = 4.0
	item.satisfaction = 25
	item.unlock_level = 1
	_register_to_menu_system(item)


func _register_menu_velvet_signature() -> void:
	var item := MenuItemData.new()
	item.id = &"midnight_dew"
	item.display_name = "미드나잇 듀"
	item.description = "Velvet 전용 시그니처. 한밤의 이슬을 닮은 차가운 정수."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 25
	item.craft_time = 3.5
	item.satisfaction = 22
	item.unlock_level = 1
	_register_to_menu_system(item)


func _register_menu_doran_signature() -> void:
	var item := MenuItemData.new()
	item.id = &"boiling_spring"
	item.display_name = "보일링 스프링"
	item.description = "Doran 전용 시그니처. 지열로 끓인 천연 온천수."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 28
	item.craft_time = 3.0
	item.satisfaction = 23
	item.unlock_level = 1
	_register_to_menu_system(item)


func _register_menu_haze_signature() -> void:
	var item := MenuItemData.new()
	item.id = &"morning_mist"
	item.display_name = "모닝 미스트"
	item.description = "Haze 전용 시그니처. 새벽 안개를 머금은 듯한 미지근한 물."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 22
	item.craft_time = 2.5
	item.satisfaction = 20
	item.unlock_level = 1
	_register_to_menu_system(item)


func _register_menu_pike_signature() -> void:
	var item := MenuItemData.new()
	item.id = &"glacier_shot"
	item.display_name = "글레이셔 샷"
	item.description = "Pike 전용 시그니처. 빙하수를 한 잔에 응축한 샷."
	item.menu_type = MenuItemData.MenuType.DRINK
	item.base_price = 18
	item.craft_time = 1.5
	item.satisfaction = 18
	item.unlock_level = 1
	_register_to_menu_system(item)


# === 손님 등록 ===

func _register_customers() -> void:
	_register_amundsen()
	_register_velvet()
	_register_doran()
	_register_haze()
	_register_pike()


func _register_amundsen() -> void:
	var data := CustomerData.new()
	data.id = &"amundsen"
	data.display_name = "Amundsen"

	# 메뉴 풀: 시그니처 1종 + 일반 4종
	data.signature_menu = &"polar_frost"
	data.common_menus = [&"ice_water", &"juice", &"hot_water", &"simple_cocktail"]

	# 행동 파라미터
	data.base_patience = 75.0
	data.chat_patience_bonus = 12.0
	data.max_orders = 3
	data.reorder_chance = 0.5
	data.quest_chance = 0.0  # MVP에서는 의뢰 없음
	data.order_delay = 2.5
	data.consume_duration = 4.0
	data.idle_duration = 10.0
	data.signature_weight = 0.25

	# 대화
	data.personality_prompt = "You are Amundsen, a stoic polar explorer who speaks in short, measured sentences. You appreciate cold drinks and quiet moments."
	data.fallback_lines = [
		"...극지의 바람이 그립군.",
		"조용한 바가 좋아. 빙하 위만큼은 아니지만.",
		"차가운 음료를 부탁하지.",
		"탐험이란 결국 인내의 문제야.",
	]

	# 대화 데이터 (JSON에서 로드)
	data.dialogue = DialogueLoader.load_for_customer(&"amundsen")

	_customers[data.id] = data


# --- Velvet: 야행성 시인, 말이 많고 감성적 ---

func _register_velvet() -> void:
	var data := CustomerData.new()
	data.id = &"velvet"
	data.display_name = "Velvet"
	data.signature_menu = &"midnight_dew"
	data.common_menus = [&"ice_water", &"juice", &"hot_water", &"simple_cocktail"]
	data.base_patience = 90.0
	data.chat_patience_bonus = 15.0
	data.max_orders = 2
	data.reorder_chance = 0.3
	data.quest_chance = 0.0
	data.order_delay = 3.0
	data.consume_duration = 6.0
	data.idle_duration = 12.0
	data.signature_weight = 0.35
	data.personality_prompt = "You are Velvet, a nocturnal poet who speaks in flowery, melancholic phrases. You love the quiet hours and express everything through metaphor."
	data.fallback_lines = [
		"달이 뜨면 영감이 찾아오지.",
		"이 잔에 담긴 건 물이 아니라 고독이야.",
		"...좋은 바는 시 한 편과 같아.",
		"오늘 밤은 유난히 길군.",
	]
	data.dialogue = DialogueLoader.load_for_customer(&"velvet")
	_customers[data.id] = data


# --- Doran: 은퇴한 대장장이, 과묵하지만 따뜻한 ---

func _register_doran() -> void:
	var data := CustomerData.new()
	data.id = &"doran"
	data.display_name = "Doran"
	data.signature_menu = &"boiling_spring"
	data.common_menus = [&"ice_water", &"juice", &"hot_water", &"simple_cocktail"]
	data.base_patience = 100.0
	data.chat_patience_bonus = 8.0
	data.max_orders = 2
	data.reorder_chance = 0.25
	data.quest_chance = 0.0
	data.order_delay = 4.0
	data.consume_duration = 7.0
	data.idle_duration = 15.0
	data.signature_weight = 0.4
	data.personality_prompt = "You are Doran, a retired blacksmith. You speak slowly with few words but each one carries weight. You appreciate warmth and honest work."
	data.fallback_lines = [
		"...따뜻한 게 좋아.",
		"이 손으로 천 자루는 만들었지.",
		"은퇴한 뒤로는 이런 곳이 대장간 대신이야.",
		"급할 것 없어. 쇠도 천천히 달궈야 하는 법이지.",
	]
	data.dialogue = DialogueLoader.load_for_customer(&"doran")
	_customers[data.id] = data


# --- Haze: 방랑하는 약초사, 호기심 많고 수다스러움 ---

func _register_haze() -> void:
	var data := CustomerData.new()
	data.id = &"haze"
	data.display_name = "Haze"
	data.signature_menu = &"morning_mist"
	data.common_menus = [&"ice_water", &"juice", &"hot_water", &"simple_cocktail"]
	data.base_patience = 55.0
	data.chat_patience_bonus = 18.0
	data.max_orders = 3
	data.reorder_chance = 0.6
	data.quest_chance = 0.0
	data.order_delay = 1.5
	data.consume_duration = 3.0
	data.idle_duration = 6.0
	data.signature_weight = 0.3
	data.personality_prompt = "You are Haze, a wandering herbalist. You're curious, talkative, and always sniffing things. You speak quickly and jump between topics."
	data.fallback_lines = [
		"이 물에서 약초 향이 나는 것 같은데...?",
		"아, 여기 공기가 좋다! 허브 키우기 딱이야.",
		"방금 숲에서 왔거든. 이끼가 엄청 예뻤어!",
		"혹시 민트 있어? 아, 없어도 괜찮아!",
	]
	data.dialogue = DialogueLoader.load_for_customer(&"haze")
	_customers[data.id] = data


# --- Pike: 전직 용병, 무뚝뚝하지만 의리 있음 ---

func _register_pike() -> void:
	var data := CustomerData.new()
	data.id = &"pike"
	data.display_name = "Pike"
	data.signature_menu = &"glacier_shot"
	data.common_menus = [&"ice_water", &"juice", &"hot_water", &"simple_cocktail"]
	data.base_patience = 45.0
	data.chat_patience_bonus = 6.0
	data.max_orders = 2
	data.reorder_chance = 0.2
	data.quest_chance = 0.0
	data.order_delay = 1.0
	data.consume_duration = 2.0
	data.idle_duration = 5.0
	data.signature_weight = 0.5
	data.personality_prompt = "You are Pike, a retired mercenary. You're blunt, impatient, but secretly kind. You order fast and drink fast. You respect efficiency."
	data.fallback_lines = [
		"빨리 줘.",
		"...나쁘지 않군.",
		"전장에선 물 한 모금이 생사를 갈랐지.",
		"떠들 시간에 한 잔 더 마시는 게 낫지 않나.",
	]
	data.dialogue = DialogueLoader.load_for_customer(&"pike")
	_customers[data.id] = data


# === 유틸 ===

func _register_to_menu_system(item: MenuItemData) -> void:
	# 트리에 MenuSystem이 있으면 직접 등록, 없으면 대기
	var menu_system := _find_menu_system()
	if menu_system:
		menu_system.register_menu(item)


func _find_menu_system() -> Node:
	var bar := get_parent()
	if bar:
		return bar.get_node_or_null("MenuSystem")
	return null
