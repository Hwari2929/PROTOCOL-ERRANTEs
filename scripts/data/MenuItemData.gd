class_name MenuItemData
extends Resource
## 바 메뉴 아이템 데이터 리소스
##
## 메뉴 타입:
##   DRINK  — 음료 (커피, 칵테일 등)
##   FOOD   — 음식 (안주, 디저트 등)
##   QUEST  — 의뢰 (손님이 맡기는 퀘스트, 제작=수행 시간)
##
## .tres 파일로 저장하여 에디터에서 편집.
## 예: resources/menus/espresso.tres

enum MenuType {
	DRINK,
	FOOD,
	QUEST,
}

@export var id: StringName
@export var display_name: String
@export var description: String = ""
@export var icon: Texture2D
@export var menu_type: MenuType = MenuType.DRINK
@export var base_price: int = 10          ## 판매 가격 (골드). QUEST의 경우 보수.
@export var craft_time: float = 2.0       ## 제작 시간 (초). QUEST의 경우 수행 시간.
@export var ingredients: Dictionary = {}  ## {"재료ID": 수량}. QUEST는 비워둠.
@export var satisfaction: int = 10        ## 손님 만족도 기여
@export var unlock_level: int = 1         ## 해금에 필요한 바 레벨

@export_group("의뢰 전용")
## 의뢰 보상 아이템 (아이템ID → 수량). QUEST 타입에서만 사용.
@export var quest_rewards: Dictionary = {}
## 의뢰 설명 텍스트
@export var quest_description: String = ""


## 음식/음료인지 확인.
func is_consumable() -> bool:
	return menu_type == MenuType.DRINK or menu_type == MenuType.FOOD


## 의뢰인지 확인.
func is_quest() -> bool:
	return menu_type == MenuType.QUEST
