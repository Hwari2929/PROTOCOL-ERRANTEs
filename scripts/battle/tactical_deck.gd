extends Node
## 전술 카드 덱 — deck(draw) / hand / graveyard + 전술 포인트(TP).
##
## Per combat node (on EventBus.round_started): TP += 1, unused hand -> graveyard,
## draw 3. Drawing from an empty deck reshuffles the graveyard back into the deck.
## The deck rebuilds (adding Commander cards) when the team changes (EventBus.team_changed).

signal hand_changed(hand: Array)
signal tp_changed(tp: int)

const HAND_SIZE: int = 3

var deck: Array = []
var hand: Array = []
var graveyard: Array = []
var tp: int = 0

var _has_commander: bool = false
var _built: bool = false
var _bonus_draw: int = 0


func _ready() -> void:
	EventBus.round_started.connect(_on_round_started)
	if EventBus.has_signal("team_changed"):
		EventBus.team_changed.connect(_on_team_changed)


func _on_round_started(_round_number: int) -> void:
	tp += 1
	tp_changed.emit(tp)
	refresh_for_team(_current_team_ids())


func _on_team_changed(ids: Array) -> void:
	refresh_for_team(ids)


func _current_team_ids() -> Array:
	var bf: Node = get_parent().get_node_or_null("BattleField")
	var ids: Array = []
	if bf != null and bf.has_method("units_of"):
		for u in bf.units_of(0):
			ids.append(String(u.get("sprite_id")))
	return ids


## Ensure the deck matches the team (commander cards) and deal a fresh hand of 3.
func refresh_for_team(ids: Array) -> void:
	var has_minor: bool = false
	for id in ids:
		if ClassData.tactical_of(id) == "마이너":
			has_minor = true
			break
	_bonus_draw = 1 if has_minor else 0

	var has_cmd: bool = ids.has("commander")
	if not _built or has_cmd != _has_commander:
		_has_commander = has_cmd
		deck = CardData.build(has_cmd)
		if has_minor:
			deck.append({"id": "minor_tactic", "label": "고유 전술", "cost": 1, "desc": "카드 1장 드로우", "effect": {"draw": 1}})
		deck.shuffle()
		graveyard = []
		hand = []
		_built = true
	else:
		for c in hand:
			graveyard.append(c)
		hand = []
	_draw(HAND_SIZE + _bonus_draw)
	hand_changed.emit(hand)


func _draw(n: int) -> void:
	for _i in n:
		if deck.is_empty():
			if graveyard.is_empty():
				break
			deck = graveyard.duplicate()
			deck.shuffle()
			graveyard = []
		hand.append(deck.pop_back())


## Play a card from the hand (spend TP, apply effect to player team, discard).
func play_card(index: int) -> bool:
	if index < 0 or index >= hand.size():
		return false
	var card: Dictionary = hand[index]
	var cost: int = int(card.get("cost", 1))
	if tp < cost:
		return false
	tp -= cost
	tp_changed.emit(tp)
	var effect: Dictionary = card.get("effect", {})
	var bf: Node = get_parent().get_node_or_null("BattleField")
	if bf != null and bf.has_method("units_of"):
		for u in bf.units_of(0):
			ClassData.apply_mods(u, effect)
	hand.remove_at(index)
	graveyard.append(card)
	if effect.has("draw"):
		_draw(int(effect["draw"]))
	hand_changed.emit(hand)
	return true


func get_tp() -> int:
	return tp


func get_hand() -> Array:
	return hand


func deck_count() -> int:
	return deck.size()


func graveyard_count() -> int:
	return graveyard.size()