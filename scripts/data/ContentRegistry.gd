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


# === 손님 등록 ===

func _register_customers() -> void:
	_register_amundsen()


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

	# 대화 데이터
	data.dialogue = _build_amundsen_dialogue()

	_customers[data.id] = data


func _build_amundsen_dialogue() -> DialogueData:
	var dlg := DialogueData.new()
	dlg.id = &"dlg_amundsen"

	# 인사
	dlg.add_entry(&"greeting", DialogueEntry.create(
		"...여기가 그 바인가. 나쁘지 않군.",
		[
			DialogueEntry.response("어서 오세요! 뭘 드릴까요?", &"patience_up", 5),
			DialogueEntry.response("탐험가시군요?", &"satisfaction_up", 3, &"explore_talk"),
		]
	))

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"추운 날이야. 따뜻한 곳을 찾고 있었지.",
		[
			DialogueEntry.response("따뜻하게 해드릴게요.", &"patience_up", 5),
			DialogueEntry.response("밖이 많이 춥나요?", &"none", 0, &"weather_talk"),
		]
	))

	# 탐험 대화 분기
	dlg.add_entry(&"explore_talk", DialogueEntry.create(
		"남극을 세 번 횡단했지. 혼자서.",
		[
			DialogueEntry.response("대단하시네요!", &"satisfaction_up", 5),
			DialogueEntry.response("외롭지 않았어요?", &"patience_up", 8, &"lonely_talk"),
		]
	))

	dlg.add_entry(&"lonely_talk", DialogueEntry.create(
		"...빙하는 좋은 대화 상대야. 아무 말도 안 하거든.",
		[
			DialogueEntry.response("(조용히 미소짓는다)", &"satisfaction_up", 8),
			DialogueEntry.response("여기선 제가 들어드릴게요.", &"patience_up", 10),
		]
	))

	# 날씨 대화 분기
	dlg.add_entry(&"weather_talk", DialogueEntry.create(
		"영하 40도에 비하면 여긴 열대지방이야.",
		[
			DialogueEntry.response("상상이 안 가네요...", &"patience_up", 5),
			DialogueEntry.response("그래서 차가운 음료를 좋아하시는 건가요?", &"satisfaction_up", 5),
		]
	))

	# 대기 중
	dlg.add_entry(&"waiting", DialogueEntry.create(
		"기다리는 건 익숙하지. 블리자드가 지나가길 기다린 적도 있으니까.",
		[
			DialogueEntry.response("곧 준비될 거예요!", &"patience_up", 10),
			DialogueEntry.response("블리자드요? 무서웠겠네요.", &"patience_up", 8, &"blizzard_talk"),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"...서두를 필요 없어. 천천히.",
		[
			DialogueEntry.response("감사합니다, 금방 가져다드릴게요.", &"patience_up", 12),
			DialogueEntry.response("(고개를 끄덕인다)", &"patience_up", 6),
		]
	))

	dlg.add_entry(&"blizzard_talk", DialogueEntry.create(
		"72시간. 텐트 안에서. 식량은 3일치뿐이었지.",
		[
			DialogueEntry.response("어떻게 버티신 거예요?", &"satisfaction_up", 5),
			DialogueEntry.response("음료로 보답할게요. 조금만 기다려주세요.", &"patience_up", 15),
		]
	))

	# IDLE 잡담
	dlg.add_entry(&"idle", DialogueEntry.create(
		"이 바의 분위기가 마음에 드는군. 조용해서 좋아.",
		[
			DialogueEntry.response("자주 오셔도 됩니다.", &"satisfaction_up", 5),
			DialogueEntry.response("더 드실 건 없으세요?", &"none", 0),
		]
	))

	dlg.add_entry(&"idle", DialogueEntry.create(
		"...한 잔 더 할까.",
		[
			DialogueEntry.response("추천 드릴까요?", &"patience_up", 8),
			DialogueEntry.response("폴라 프로스트 어떠세요?", &"satisfaction_up", 5),
		]
	))

	# 소비 중
	dlg.add_entry(&"eating", DialogueEntry.create(
		"...좋군. 이 차가움은 빙하를 떠올리게 해.",
		[
			DialogueEntry.response("마음에 드셨다니 다행이에요.", &"satisfaction_up", 3),
		]
	))

	# 퇴장
	dlg.add_entry(&"farewell", DialogueEntry.create(
		"좋은 시간이었어. ...또 오겠지.",
		[
			DialogueEntry.response("다음에 또 오세요!", &"satisfaction_up", 3),
		]
	))

	return dlg


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
