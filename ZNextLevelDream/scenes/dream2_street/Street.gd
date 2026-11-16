## 第二层梦境·大街：沿街楼群 + 斑马线 + 右端悬崖 + 医院入口。
##
## 导航：
##   - 从轨道世界保安室旁过来（落点在左端）
##   - 电瓶车停在路边 → 拾取后装备可提速
##   - 右端悬崖：与轨道世界一样，跳下去 Kick 回第一层床边（锚点 1）
##   - 下方医院入口 → 医院外场景
##   - Q 捏脸在第二层无效
extends Node2D

const DREAM1_BEDROOM: = "res://scenes/dream1_bedroom/Dream1Bedroom.tscn"
const HOSPITAL_OUTSIDE: = "res://scenes/dream2_hospital_outside/HospitalOutside.tscn"
const RAIL_WORLD: = "res://scenes/dream2_rail_world/Dream2RailWorld.tscn"
## 回铁轨的落点：轨道世界保安室旁街道入口旁边。
const RAIL_LANDING: = Vector2(4750.0, 1150.0)
const WORLD_SIZE: Vector2i = Vector2i(3840, 1620)

@onready var player: Player = $Player
@onready var cliff: Interactable = $Props/CliffEdge/Interactable
@onready var scooter: Interactable = $Props/Scooter/Interactable
@onready var scooter_sprite: Sprite2D = $Props/Scooter/Sprite2D
@onready var hospital_door: Interactable = $Props/HospitalDoor/Interactable
@onready var rail_entrance: Interactable = $Props/RailEntrance/Interactable


func _ready() -> void:
	GameState.set_dream_layer(2)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	cliff.interacted.connect(_on_cliff_jump)
	scooter.interacted.connect(_on_scooter_interacted)
	hospital_door.interacted.connect(_on_hospital_door)
	rail_entrance.interacted.connect(_on_rail_entrance)
	_refresh_scooter()


func _refresh_scooter() -> void:
	var collected: bool = Backpack.has_item("scooter")
	scooter_sprite.visible = not collected
	scooter.enabled = not collected


func _unhandled_input(event: InputEvent) -> void:
	# 第二层起捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()


func _on_scooter_interacted(_source: Node2D) -> void:
	if Backpack.add_item("scooter"):
		_refresh_scooter()
		player.say("骑了一下觉得太慢，干脆推着走。（按 B 装备电瓶车）")
	else:
		player.say("电瓶车已经在背包里了。")


func _on_hospital_door(_source: Node2D) -> void:
	player.say("医院的自动门缓缓打开。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走进医院……"
	await SceneFader.change_scene(HOSPITAL_OUTSIDE, 0.85, 1.05, Vector2(300.0, 860.0))


func _on_rail_entrance(_source: Node2D) -> void:
	player.say("回到铁轨旁边。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "梦在流动……"
	await SceneFader.change_scene(RAIL_WORLD, 0.85, 1.05, RAIL_LANDING)


func _on_cliff_jump(_source: Node2D) -> void:
	player.say("——！")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	# 坠落 Kick：从第二层跌回第一层，落在睡着时那张床边（锚点 1）。
	GameState.set_dream_layer(1)
	var target: String = DREAM1_BEDROOM
	var landing: Vector2 = Vector2(440.0, 780.0)
	var anchor: Dictionary = GameState.bed_anchor(1)
	if not anchor.is_empty():
		target = anchor["scene"]
		landing = anchor["position"]
	GameState.record_position(target, landing)
	# 梦层跃迁（2→1）：马赛克转场。坠落 Kick。
	await DreamTransition.change_scene(target, landing)
