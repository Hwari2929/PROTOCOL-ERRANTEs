class_name RecipeChoice
extends Resource
## 레시피 단계의 개별 선택지
##
## 예: "작은 컵" — 가격 할인, 만족도 약간 낮음

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
## 이 선택이 만족도에 주는 보정 (-10 ~ +10 등)
@export var satisfaction_modifier: int = 0
## 이 선택이 가격에 주는 보정 (골드)
@export var price_modifier: int = 0
