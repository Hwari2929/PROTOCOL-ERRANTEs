class_name CustomerSpawner
extends Node
## 손님 생성/관리
##
## BarManager의 자식 노드로 동작.
## 영업 중 일정 간격으로 손님을 생성하여 바에 배치.
##
## 씬 트리에서 좌석(Seat) 노드들을 참조하여 빈 좌석에 손님 배정.
## 좌석 노드는 Bar.tscn의 Seats 그룹 아래 Node2D로 배치.

signal customer_spawned(customer: Node)

## 손님 생성 간격 (초)
@export var spawn_interval: float = 8.0
## 생성 간격 랜덤 편차 (±초)
@export var spawn_variance: float = 3.0
## 손님 씬 경로
@export var customer_scene_path: String = "res://scenes/characters/CustomerNPC.tscn"
## 손님 입장 위치 (씬에서 Marker2D로 지정)
@export var entrance_position: Vector2 = Vector2(-50, 200)
## 생성 가능한 손님 유형 풀 (CustomerData 리소스)
@export var customer_pool: Array[CustomerData] = []

var is_spawning: bool = false

var _spawn_timer: float = 0.0
var _customer_scene: PackedScene = null
var _bar_manager: Node = null


func _ready() -> void:
	_bar_manager = get_parent()
	_preload_customer_scene()
	_load_customer_pool()


func _process(delta: float) -> void:
	if not is_spawning:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_try_spawn_customer()
		_reset_spawn_timer()


## 생성 시작. BarManager에서 영업 시작 시 호출.
func start_spawning() -> void:
	is_spawning = true
	_reset_spawn_timer()


## 생성 중지. BarManager에서 영업 종료 시 호출.
func stop_spawning() -> void:
	is_spawning = false


func _try_spawn_customer() -> void:
	if _customer_scene == null:
		return
	if _bar_manager == null:
		return

	# 좌석 확인
	var seat := _find_empty_seat()
	if seat == null:
		return

	# 최대 인원 확인
	if _bar_manager.has_method("get_max_customers") and _bar_manager.has_method("get_customer_count"):
		if _bar_manager.get_customer_count() >= _bar_manager.get_max_customers():
			return

	# 손님 인스턴스 생성
	var customer: Node2D = _customer_scene.instantiate()
	customer.global_position = entrance_position

	# CustomerData 주입
	var data := _pick_customer_data()
	if customer.has_method("setup") and data:
		customer.setup(data)

	# BarManager에 등록
	if _bar_manager.has_method("register_customer"):
		if not _bar_manager.register_customer(customer):
			customer.queue_free()
			return

	# 씬 트리에 추가
	_bar_manager.add_child(customer)

	# 좌석 배정
	if customer.has_method("assign_seat"):
		customer.assign_seat(seat)
		seat.set_meta("occupied", true)
		customer.tree_exiting.connect(_on_customer_leaving.bind(seat))

	# EventBus 알림
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.customer_entered.emit(StringName(customer.name))

	customer_spawned.emit(customer)


func _find_empty_seat() -> Node2D:
	var seats_parent := _bar_manager.get_node_or_null("Seats")
	if seats_parent == null:
		return null

	var seats: Array[Node] = []
	for child in seats_parent.get_children():
		if child is Node2D and not child.get_meta("occupied", false):
			seats.append(child)

	if seats.is_empty():
		return null

	return seats.pick_random() as Node2D


func _on_customer_leaving(seat: Node2D) -> void:
	if is_instance_valid(seat):
		seat.set_meta("occupied", false)


func _reset_spawn_timer() -> void:
	_spawn_timer = spawn_interval + randf_range(-spawn_variance, spawn_variance)
	_spawn_timer = max(_spawn_timer, 1.0)


func _pick_customer_data() -> CustomerData:
	if customer_pool.is_empty():
		return null
	return customer_pool.pick_random()


func _preload_customer_scene() -> void:
	if ResourceLoader.exists(customer_scene_path):
		_customer_scene = load(customer_scene_path)


## resources/customers/ 폴더에서 손님 유형 리소스를 자동 로드.
func _load_customer_pool() -> void:
	if not customer_pool.is_empty():
		return
	var dir_path := "res://resources/customers/"
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(dir_path + file_name)
			if res is CustomerData:
				customer_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
