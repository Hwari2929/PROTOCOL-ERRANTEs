class_name MenuItemData
extends Resource
## 바 메뉴 아이템 데이터 리소스
##
## .tres 파일로 저장하여 에디터에서 편집.
## 예: resources/menus/espresso.tres

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var base_price: int = 10          ## 판매 가격 (골드)
@export var craft_time: float = 2.0       ## 제작 시간 (초)
@export var ingredients: Dictionary = {}  ## {"재료ID": 수량}
@export var satisfaction: int = 10        ## 손님 만족도 기여
@export var unlock_level: int = 1         ## 해금에 필요한 바 레벨
