class_name ResourceManager
extends Node
## 자원(골드/토큰) 관리 싱글톤
##
## 골드: 바 경영 자원 → 장비 가챠, 유물, 바 업그레이드
## 토큰: 전투 자원 → 캐릭터 가챠

signal gold_changed(new_amount: int)
signal tokens_changed(new_amount: int)

var gold: int = 0
var tokens: int = 0


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
	_get_event_bus_safe().gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	_get_event_bus_safe().gold_changed.emit(gold)
	return true


func has_gold(amount: int) -> bool:
	return gold >= amount


func add_tokens(amount: int) -> void:
	tokens += amount
	tokens_changed.emit(tokens)
	_get_event_bus_safe().tokens_changed.emit(tokens)


func spend_tokens(amount: int) -> bool:
	if tokens < amount:
		return false
	tokens -= amount
	tokens_changed.emit(tokens)
	_get_event_bus_safe().tokens_changed.emit(tokens)
	return true


func has_tokens(amount: int) -> bool:
	return tokens >= amount


func reset() -> void:
	gold = 0
	tokens = 0
	gold_changed.emit(gold)
	tokens_changed.emit(tokens)


func _get_event_bus_safe() -> Node:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		return bus
	# EventBus가 없으면 더미 반환하여 emit 호출 시 크래시 방지
	return self
