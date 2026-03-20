class_name CustomerData
extends Resource
## 손님 유형 데이터 리소스
##
## 각 손님 유형은 고유한 메뉴 풀을 가진다:
##   - signature_menu: 이 유형만 주문하는 시그니처 메뉴 1종
##   - common_menus: 일반 메뉴 4종
##
## 의뢰(QUEST)도 메뉴 풀에 포함 가능. MenuItemData.menu_type == QUEST
##
## .tres 파일로 저장: resources/customers/regular_worker.tres

@export_group("기본 정보")
@export var id: StringName
@export var display_name: String
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames

@export_group("메뉴 풀")
## 이 손님 유형 고유의 시그니처 메뉴 (1종)
@export var signature_menu: StringName
## 일반적으로 주문 가능한 메뉴 (4종)
@export var common_menus: Array[StringName] = []

@export_group("행동 파라미터")
## 기본 인내심 (초). 전체 체류 시간의 기반.
@export var base_patience: float = 60.0
## 대화 1회당 인내심 회복량 (초)
@export var chat_patience_bonus: float = 10.0
## 최대 주문 횟수 (시그니처 포함)
@export var max_orders: int = 2
## 추가 주문 확률 (0.0~1.0)
@export var reorder_chance: float = 0.4
## 의뢰 제안 확률 (0.0~1.0). 의뢰 메뉴가 풀에 있을 때만 유효.
@export var quest_chance: float = 0.2
## 주문 결정까지 대기 시간 (초)
@export var order_delay: float = 2.0
## 식사/음료 소비 시간 (초)
@export var consume_duration: float = 5.0
## IDLE 상태에서 다음 행동까지 대기 시간 (초)
@export var idle_duration: float = 8.0

@export_group("대화")
## AI 대화용 성격 프롬프트
@export var personality_prompt: String = ""
## 오프라인 폴백 대사 목록
@export var fallback_lines: Array[String] = []

@export_group("시그니처 주문 가중치")
## 시그니처 메뉴 선택 확률 가중치 (vs 일반 메뉴)
@export var signature_weight: float = 0.3


## 이 손님의 전체 주문 가능 메뉴 ID 목록 반환.
func get_all_menu_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if signature_menu != &"":
		result.append(signature_menu)
	result.append_array(common_menus)
	return result


## 메뉴 풀에서 하나를 가중치 기반으로 선택.
## quest_only가 true면 QUEST 타입만 반환 (MenuSystem 참조 필요).
func pick_menu(menu_system: Node = null) -> StringName:
	var pool := get_all_menu_ids()
	if pool.is_empty():
		return &""

	# 시그니처 가중치 적용
	if signature_menu != &"" and randf() < signature_weight:
		return signature_menu

	# 일반 메뉴에서 랜덤
	if common_menus.is_empty():
		return signature_menu
	return common_menus.pick_random()


## 의뢰 메뉴만 필터링하여 반환.
func get_quest_menus(menu_system: Node) -> Array[StringName]:
	var result: Array[StringName] = []
	for menu_id in get_all_menu_ids():
		if menu_system and menu_system.has_method("get_menu_item"):
			var item: MenuItemData = menu_system.get_menu_item(menu_id)
			if item and item.menu_type == MenuItemData.MenuType.QUEST:
				result.append(menu_id)
	return result


## 음식/음료 메뉴만 필터링하여 반환.
func get_consumable_menus() -> Array[StringName]:
	var result: Array[StringName] = []
	# 시그니처 + 일반 중 의뢰가 아닌 것을 반환
	# (MenuType 확인은 MenuSystem에서, 여기선 전체 반환)
	return get_all_menu_ids()
