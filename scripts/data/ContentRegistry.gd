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
	data.dialogue = _build_velvet_dialogue()
	_customers[data.id] = data


func _build_velvet_dialogue() -> DialogueData:
	var dlg := DialogueData.new()
	dlg.id = &"dlg_velvet"

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"...좋은 밤이야. 별이 보이는 자리가 있을까?",
		[
			DialogueEntry.response("창가 자리 어때요?", &"satisfaction_up", 5),
			DialogueEntry.response("시인이신가요?", &"patience_up", 5, &"poet_talk"),
		]
	))

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"여긴 조용하군. 글을 쓰기 좋겠어.",
		[
			DialogueEntry.response("편하게 계세요.", &"patience_up", 5),
			DialogueEntry.response("무슨 글을 쓰시나요?", &"satisfaction_up", 3, &"writing_talk"),
		]
	))

	dlg.add_entry(&"poet_talk", DialogueEntry.create(
		"시인이라기보단... 밤을 기록하는 사람이랄까.",
		[
			DialogueEntry.response("멋진 표현이네요.", &"satisfaction_up", 8),
			DialogueEntry.response("오늘 밤은 뭘 기록하실 건가요?", &"patience_up", 5),
		]
	))

	dlg.add_entry(&"writing_talk", DialogueEntry.create(
		"물방울이 잔에 맺히는 순간에 대해서. 그 짧은 영원에 대해서.",
		[
			DialogueEntry.response("(조용히 듣는다)", &"satisfaction_up", 8),
			DialogueEntry.response("영감이 되는 음료를 가져다드릴게요.", &"patience_up", 10),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"기다림도 시의 일부야. 서두르지 않아도 돼.",
		[
			DialogueEntry.response("감사합니다. 곧 가져다드릴게요.", &"patience_up", 12),
			DialogueEntry.response("기다리는 동안 뭘 쓰고 계세요?", &"patience_up", 8),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"잔이 비어 있어도 괜찮아. 빈 잔에도 의미가 있으니까.",
		[
			DialogueEntry.response("곧 채워드릴게요.", &"patience_up", 10),
			DialogueEntry.response("깊은 말씀이시네요.", &"satisfaction_up", 5),
		]
	))

	dlg.add_entry(&"idle", DialogueEntry.create(
		"이 바의 조명이 좋아. 어둡지만 외롭지 않은.",
		[
			DialogueEntry.response("자주 와주세요.", &"satisfaction_up", 5),
			DialogueEntry.response("더 드실 건요?", &"none", 0),
		]
	))

	dlg.add_entry(&"eating", DialogueEntry.create(
		"...한 모금에 밤 하나가 녹아드는 기분이야.",
		[
			DialogueEntry.response("마음에 드셨나 봐요.", &"satisfaction_up", 3),
		]
	))

	dlg.add_entry(&"farewell", DialogueEntry.create(
		"오늘 밤의 시는 여기서 끝. ...고마웠어.",
		[
			DialogueEntry.response("좋은 밤 되세요!", &"satisfaction_up", 3),
		]
	))

	return dlg


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
	data.dialogue = _build_doran_dialogue()
	_customers[data.id] = data


func _build_doran_dialogue() -> DialogueData:
	var dlg := DialogueData.new()
	dlg.id = &"dlg_doran"

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"...여기 괜찮군. 따뜻해.",
		[
			DialogueEntry.response("어서 오세요, 편히 앉으세요.", &"patience_up", 5),
			DialogueEntry.response("대장장이셨다고요?", &"satisfaction_up", 3, &"smith_talk"),
		]
	))

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"오랜만에 나왔어. 집에만 있으니 뼈가 굳더라고.",
		[
			DialogueEntry.response("잘 오셨어요!", &"patience_up", 5),
			DialogueEntry.response("따뜻한 거 준비해드릴까요?", &"satisfaction_up", 5),
		]
	))

	dlg.add_entry(&"smith_talk", DialogueEntry.create(
		"40년. 매일 쇠를 두드렸지. 좋은 시절이었어.",
		[
			DialogueEntry.response("대단하시네요.", &"satisfaction_up", 5),
			DialogueEntry.response("그리우시겠어요.", &"patience_up", 8, &"retire_talk"),
		]
	))

	dlg.add_entry(&"retire_talk", DialogueEntry.create(
		"...그립다기보단. 이 손이 기억하고 있어. 그걸로 충분해.",
		[
			DialogueEntry.response("(손을 바라본다)", &"satisfaction_up", 8),
			DialogueEntry.response("여기서 편히 쉬세요.", &"patience_up", 10),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"급할 것 없어. 좋은 건 천천히 만들어지는 법이지.",
		[
			DialogueEntry.response("감사합니다, 정성껏 만들게요.", &"patience_up", 15),
			DialogueEntry.response("대장간에서도 그러셨나요?", &"patience_up", 8),
		]
	))

	dlg.add_entry(&"idle", DialogueEntry.create(
		"...이 자리가 마음에 들어. 좀 더 있겠어.",
		[
			DialogueEntry.response("천천히 계세요.", &"satisfaction_up", 5),
			DialogueEntry.response("더 드릴 거 있을까요?", &"none", 0),
		]
	))

	dlg.add_entry(&"eating", DialogueEntry.create(
		"...좋아. 뼛속까지 따뜻해지는군.",
		[
			DialogueEntry.response("다행이에요.", &"satisfaction_up", 3),
		]
	))

	dlg.add_entry(&"farewell", DialogueEntry.create(
		"잘 쉬었어. ...또 올게.",
		[
			DialogueEntry.response("언제든 오세요!", &"satisfaction_up", 3),
		]
	))

	return dlg


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
	data.dialogue = _build_haze_dialogue()
	_customers[data.id] = data


func _build_haze_dialogue() -> DialogueData:
	var dlg := DialogueData.new()
	dlg.id = &"dlg_haze"

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"안녕! 여기 처음인데, 뭐가 맛있어?",
		[
			DialogueEntry.response("얼음물이 기본이에요!", &"patience_up", 5),
			DialogueEntry.response("약초사라고 들었는데요?", &"satisfaction_up", 5, &"herb_talk"),
		]
	))

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"우와, 이 바 분위기 좋다! 허브 화분 놓으면 더 좋을 텐데!",
		[
			DialogueEntry.response("좋은 아이디어네요!", &"satisfaction_up", 5),
			DialogueEntry.response("뭘 드릴까요?", &"patience_up", 3),
		]
	))

	dlg.add_entry(&"herb_talk", DialogueEntry.create(
		"맞아! 숲이랑 들판을 돌아다니면서 약초를 모으고 있어. 오늘은 30종이나 찾았어!",
		[
			DialogueEntry.response("30종이나요?!", &"satisfaction_up", 5),
			DialogueEntry.response("어떤 약초를 찾으시나요?", &"patience_up", 8, &"herb_detail"),
		]
	))

	dlg.add_entry(&"herb_detail", DialogueEntry.create(
		"지금은 이슬풀을 찾고 있어. 새벽에만 피는데, 물을 정화하는 효능이 있거든!",
		[
			DialogueEntry.response("신기하네요!", &"satisfaction_up", 8),
			DialogueEntry.response("그래서 모닝 미스트를 좋아하시는 거군요.", &"patience_up", 10),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"기다리는 동안 이 테이블 냄새 좀 맡아봐도 돼? ...나무 향이 좋다!",
		[
			DialogueEntry.response("편하게 하세요!", &"patience_up", 10),
			DialogueEntry.response("곧 가져다드릴게요!", &"patience_up", 8),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"아 참, 아까 숲에서 본 버섯이 있는데! 듣고 싶어?",
		[
			DialogueEntry.response("네, 들려주세요!", &"patience_up", 15),
			DialogueEntry.response("잠깐만요, 음료부터 가져올게요.", &"patience_up", 5),
		]
	))

	dlg.add_entry(&"idle", DialogueEntry.create(
		"한 잔 더 마시면서 이야기 더 해도 돼? 할 말이 너무 많아!",
		[
			DialogueEntry.response("물론이죠!", &"satisfaction_up", 5),
			DialogueEntry.response("뭘 더 드릴까요?", &"none", 0),
		]
	))

	dlg.add_entry(&"eating", DialogueEntry.create(
		"음~ 이 물 깨끗하다! 어디서 가져온 거야?",
		[
			DialogueEntry.response("비밀이에요.", &"satisfaction_up", 5),
		]
	))

	dlg.add_entry(&"farewell", DialogueEntry.create(
		"아 벌써 가야 해! 다음엔 약초 선물 가져올게! 안녕!",
		[
			DialogueEntry.response("기대할게요! 또 오세요!", &"satisfaction_up", 5),
		]
	))

	return dlg


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
	data.dialogue = _build_pike_dialogue()
	_customers[data.id] = data


func _build_pike_dialogue() -> DialogueData:
	var dlg := DialogueData.new()
	dlg.id = &"dlg_pike"

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"...한 잔.",
		[
			DialogueEntry.response("네, 바로 준비할게요.", &"satisfaction_up", 5),
			DialogueEntry.response("용병이셨다면서요?", &"patience_up", 3, &"merc_talk"),
		]
	))

	dlg.add_entry(&"greeting", DialogueEntry.create(
		"복잡한 건 됐고. 차가운 거 하나.",
		[
			DialogueEntry.response("글레이셔 샷 어떠세요?", &"satisfaction_up", 5),
			DialogueEntry.response("얼음물 바로 가져올게요.", &"patience_up", 5),
		]
	))

	dlg.add_entry(&"merc_talk", DialogueEntry.create(
		"...그건 옛날 얘기야. 지금은 마시러 왔을 뿐이야.",
		[
			DialogueEntry.response("알겠습니다.", &"patience_up", 5),
			DialogueEntry.response("그래도 대단한 분이시네요.", &"satisfaction_up", 3, &"past_talk"),
		]
	))

	dlg.add_entry(&"past_talk", DialogueEntry.create(
		"...대단할 것 없어. 살아남았을 뿐이야.",
		[
			DialogueEntry.response("(조용히 끄덕인다)", &"satisfaction_up", 8),
			DialogueEntry.response("여기선 편히 쉬세요.", &"patience_up", 8),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"...늦어지면 간다.",
		[
			DialogueEntry.response("바로 가져갈게요!", &"patience_up", 10),
			DialogueEntry.response("조금만 기다려주세요.", &"patience_up", 5),
		]
	))

	dlg.add_entry(&"waiting", DialogueEntry.create(
		"전장에선 3초 안에 물을 마셔야 했어.",
		[
			DialogueEntry.response("여긴 전장이 아니니까 천천히요.", &"patience_up", 8),
			DialogueEntry.response("거의 다 됐어요!", &"patience_up", 6),
		]
	))

	dlg.add_entry(&"idle", DialogueEntry.create(
		"...나쁘지 않았어.",
		[
			DialogueEntry.response("더 드실 건요?", &"none", 0),
			DialogueEntry.response("감사합니다.", &"satisfaction_up", 3),
		]
	))

	dlg.add_entry(&"eating", DialogueEntry.create(
		"...깔끔하군.",
		[
			DialogueEntry.response("다행이에요.", &"satisfaction_up", 3),
		]
	))

	dlg.add_entry(&"farewell", DialogueEntry.create(
		"...또 온다.",
		[
			DialogueEntry.response("기다리고 있을게요.", &"satisfaction_up", 5),
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
