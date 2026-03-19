class_name EventBus
extends Node
## 글로벌 시그널 버스 — 노드 간 직접 참조 없이 이벤트 전달

# === 게임 상태 ===
signal game_state_changed(old_state: StringName, new_state: StringName)

# === 바 경영 ===
signal bar_opened
signal bar_closed
signal business_started
signal business_ended(total_income: int)
signal customer_entered(customer_id: StringName)
signal customer_left(customer_id: StringName)
signal customer_seated(customer_id: StringName)
signal order_placed(menu_id: StringName)
signal order_served(menu_id: StringName)
signal gold_changed(new_amount: int)
signal menu_unlocked(menu_id: StringName)
signal bar_upgraded(new_level: int)

# === 전투 ===
signal battle_session_started
signal battle_session_ended(victory: bool)
signal battle_phase_changed(new_phase: StringName)
signal round_started(round_number: int)
signal round_ended(round_number: int, victory: bool)
signal tokens_changed(new_amount: int)

# === 캐릭터 ===
signal character_obtained(character_id: StringName)
signal affection_changed(character_id: StringName, new_value: int)

# === UI ===
signal scene_transition_requested(scene_name: String)
signal notification_requested(message: String)
