extends Node
## 전역 게임 상태 머신 (Autoload "GameManager" — class_name 미사용: 동명 autoload 충돌 방지)
##
## 상태 흐름:
##   TITLE → MENU → BAR_OPEN ⇄ BAR_CLOSING → BATTLE → BATTLE_END → BAR_OPENING → BAR_OPEN
##
## Autoload 싱글톤으로 등록하여 사용.

# === 상태 정의 ===
enum State {
	NONE,
	TITLE,
	MENU,
	BAR_OPEN,
	BAR_CLOSING,
	BATTLE,
	BATTLE_END,
	BAR_OPENING,
}

# === 시그널 ===
signal state_changed(old_state: State, new_state: State)

# === 상태 변수 ===
var current_state: State = State.NONE
var previous_state: State = State.NONE
var total_days: int = 0

# === 허용된 전이 테이블 ===
## 각 상태에서 전이 가능한 다음 상태 목록
var _transitions: Dictionary = {
	State.NONE: [State.TITLE],
	State.TITLE: [State.MENU],
	State.MENU: [State.BAR_OPEN, State.TITLE],
	State.BAR_OPEN: [State.BAR_CLOSING, State.MENU],
	State.BAR_CLOSING: [State.BATTLE],
	State.BATTLE: [State.BATTLE_END],
	State.BATTLE_END: [State.BAR_OPENING],
	State.BAR_OPENING: [State.BAR_OPEN],
}


func _ready() -> void:
	transition_to(State.TITLE)


# === 공개 API ===

## 지정한 상태로 전이. 유효하지 않은 전이는 무시하고 경고 출력.
func transition_to(new_state: State) -> bool:
	if new_state == current_state:
		push_warning("GameManager: 이미 %s 상태입니다." % State.keys()[new_state])
		return false

	if not _is_valid_transition(new_state):
		push_warning(
			"GameManager: %s → %s 전이는 허용되지 않습니다."
			% [State.keys()[current_state], State.keys()[new_state]]
		)
		return false

	var old_state := current_state
	previous_state = old_state
	current_state = new_state

	_on_exit_state(old_state)
	_on_enter_state(new_state)

	state_changed.emit(old_state, new_state)
	_emit_event_bus(old_state, new_state)

	return true


## 현재 상태를 문자열로 반환.
func get_state_name() -> String:
	return State.keys()[current_state]


## 특정 상태인지 확인.
func is_state(state: State) -> bool:
	return current_state == state


# === 편의 전이 함수 ===

func start_game() -> bool:
	return transition_to(State.MENU)


func open_bar() -> bool:
	var success := transition_to(State.BAR_OPEN)
	if success and previous_state == State.BAR_OPENING:
		total_days += 1
	return success


func close_bar() -> bool:
	return transition_to(State.BAR_CLOSING)


func start_battle() -> bool:
	return transition_to(State.BATTLE)


func end_battle() -> bool:
	return transition_to(State.BATTLE_END)


func return_to_bar() -> bool:
	return transition_to(State.BAR_OPENING)


func finish_transition_to_bar() -> bool:
	return transition_to(State.BAR_OPEN)


func return_to_title() -> bool:
	if current_state == State.MENU:
		return transition_to(State.TITLE)
	return false


func return_to_menu() -> bool:
	if current_state == State.BAR_OPEN:
		return transition_to(State.MENU)
	return false


# === 내부 로직 ===

func _is_valid_transition(new_state: State) -> bool:
	if current_state not in _transitions:
		return false
	return new_state in _transitions[current_state]


## 상태 진입 시 실행할 로직. 확장 포인트.
func _on_enter_state(state: State) -> void:
	match state:
		State.TITLE:
			pass
		State.MENU:
			pass
		State.BAR_OPEN:
			pass
		State.BAR_CLOSING:
			# 전환 연출 완료 후 자동으로 BATTLE 진입
			_start_transition_timer(State.BATTLE)
		State.BATTLE:
			pass
		State.BATTLE_END:
			pass
		State.BAR_OPENING:
			# 전환 연출 완료 후 자동으로 BAR_OPEN 진입
			_start_transition_timer(State.BAR_OPEN)


## 상태 퇴장 시 실행할 로직. 확장 포인트.
func _on_exit_state(state: State) -> void:
	match state:
		State.BAR_OPEN:
			pass
		State.BATTLE:
			pass
		_:
			pass


## EventBus로 상태 변경 전파.
func _emit_event_bus(old_state: State, new_state: State) -> void:
	var bus := _get_event_bus()
	if bus == null:
		return

	bus.game_state_changed.emit(
		StringName(State.keys()[old_state]),
		StringName(State.keys()[new_state])
	)

	match new_state:
		State.BAR_OPEN:
			bus.bar_opened.emit()
		State.BAR_CLOSING:
			bus.bar_closed.emit()
		State.BATTLE:
			bus.battle_session_started.emit()
		State.BATTLE_END:
			bus.battle_session_ended.emit(true)


## 전환 연출용 타이머. 연출이 구현되면 실제 애니메이션 시간으로 교체.
func _start_transition_timer(next_state: State) -> void:
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(transition_to.bind(next_state))


## EventBus 싱글톤 참조. Autoload 등록 전에도 안전하게 동작.
func _get_event_bus() -> Node:
	if Engine.has_singleton("EventBus"):
		return Engine.get_singleton("EventBus")
	return get_node_or_null("/root/EventBus")
