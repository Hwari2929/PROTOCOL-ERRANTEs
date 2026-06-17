extends Node
## 의뢰(run) 진행 — 전투 노드 체인 + 런 종료.
## A quest = a chain of 3 combat nodes; on victory grant energy credits and advance
## (next wave + round_started), win after the last node, lose if the team is wiped.
## (Resonance/augment/inhesion now happen via the RESONATE action in prep_panel.)

@onready var _battle_field: Node = get_parent().get_node_or_null("BattleField")
@onready var _resonance: Node = get_parent().get_node_or_null("Resonance")
@onready var _augment_system: Node = get_parent().get_node_or_null("AugmentSystem")

var _node_count: int = 3
var _current_node: int = 1
var _run_result: int = 0
var _is_run_over: bool = false

func node_count() -> int:
	return _node_count

func current_node() -> int:
	return _current_node

func is_run_over() -> bool:
	return _is_run_over

func run_result() -> int:
	return _run_result

func _ready() -> void:
	EventBus.battle_session_started.emit()
	EventBus.round_started.emit(1)
	EventBus.round_ended.connect(_on_round_ended)

func _on_round_ended(round_number: int, victory: bool) -> void:
	if victory:
		advance_node()
	else:
		_is_run_over = true
		_run_result = -1
		SaveStore.record_run(_current_node - 1, false)
		EventBus.battle_session_ended.emit(false)

func advance_node() -> void:
	if _is_run_over:
		return

	var result: int = 0
	if _battle_field != null:
		result = _battle_field.result()

	if result == 1:
		# Combat reward: energy credits (spent later via RESONATE in prep).
		if _resonance != null:
			_resonance.gain_credits(12)

		if _current_node < _node_count:
			_current_node += 1
			if _battle_field != null:
				_battle_field.spawn_wave(_current_node)
			EventBus.round_started.emit(_current_node)
		else:
			_is_run_over = true
			_run_result = 1
			SaveStore.record_run(_node_count, true)
			EventBus.battle_session_ended.emit(true)
	elif result == -1:
		_is_run_over = true
		_run_result = -1
		SaveStore.record_run(_current_node - 1, false)
		EventBus.battle_session_ended.emit(false)