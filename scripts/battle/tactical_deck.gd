extends Node
## 전술 카드 덱 — deck(draw) / hand / graveyard + 전술 포인트(TP).
##
## Per combat node (on EventBus.round_started): TP += 1, unused hand -> graveyard,
## draw 3. Drawing from an empty deck reshuffles the graveyard back into the deck.
## The deck rebuilds (adding Commander cards) when the team changes (EventBus.team_changed).

signal hand_changed(hand: Array)
signal tp_changed(tp: int)
signal assets_changed(assets: int)

const HAND_SIZE: int = 3

var deck: Array = []
var hand: Array = []
var graveyard: Array = []
var tp: int = 0

# 사이퍼 자산(assets) economy: each node grants +1 per 사이퍼 on the team.
# 고유 '가려진 흉계': every asset SPENT raises 전술 위력(tactical power) by 2%p this quest.
var assets: int = 0
var tactical_power_mult: float = 1.0
var _pinned: Array = []   # card ids kept in hand across nodes (고정 / pin)

# 파일럿 제공권(air superiority) economy: +1 per 파일럿 each node.
# 고유 '하늘의 공포': every point SPENT raises 전술 위력 by 3%p this quest.
var air_sup: int = 0

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
	# 사이퍼 자산 / 파일럿 제공권 income: +1 per matching class on the team, each node.
	var ciphers: int = _count_class("cipher")
	if ciphers > 0:
		assets += ciphers
		assets_changed.emit(assets)
	var pilots: int = _count_class("pilot")
	if pilots > 0:
		air_sup += pilots
	refresh_for_team(_current_team_ids())


func _count_class(class_id: String) -> int:
	var n: int = 0
	for id in _current_team_ids():
		if id == class_id:
			n += 1
	return n


func _cipher_count() -> int:
	return _count_class("cipher")


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
		# 고정(pin)된 카드는 다음 노드 패에 잔류하고 고정이 해제된다; 나머지는 묘지로.
		var kept: Array = []
		for c in hand:
			if c.get("pinned", false):
				c["pinned"] = false
				kept.append(c)
			else:
				graveyard.append(c)
		hand = kept
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


## 사이퍼 자산 spend: returns false if insufficient. Each point spent raises
## 전술 위력 by 2%p (고유 가려진 흉계).
func spend_assets(n: int) -> bool:
	if n <= 0 or assets < n:
		return false
	assets -= n
	tactical_power_mult += 0.02 * float(n)
	assets_changed.emit(assets)
	return true


func gain_assets(n: int) -> void:
	if n <= 0:
		return
	assets += n
	assets_changed.emit(assets)


## 고정(pin): spend 1 asset to keep a hand card across the next node.
func pin_card(index: int) -> bool:
	if index < 0 or index >= hand.size():
		return false
	if not spend_assets(1):
		return false
	hand[index]["pinned"] = true
	hand_changed.emit(hand)
	return true


func current_assets() -> int:
	return assets


## 파일럿 제공권 spend: each point raises 전술 위력 by 3%p (고유 하늘의 공포).
func spend_air_sup(n: int) -> bool:
	if n <= 0 or air_sup < n:
		return false
	air_sup -= n
	tactical_power_mult += 0.03 * float(n)
	return true


func gain_air_sup(n: int) -> void:
	if n > 0:
		air_sup += n


func air_superiority() -> int:
	return air_sup


func tactical_power() -> float:
	return tactical_power_mult


func get_tp() -> int:
	return tp


func get_hand() -> Array:
	return hand


func deck_count() -> int:
	return deck.size()


func graveyard_count() -> int:
	return graveyard.size()