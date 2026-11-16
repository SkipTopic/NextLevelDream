## 第二层梦境·轨道世界：5760x1620 的横向铁轨尽头世界。
##
## 规则变化（梦越深，醒来越难）：
##   - Q 捏脸在这里无效——只给台词反馈，不会醒。
##   - 左端悬崖：站到崖边按交互键"跳下去"，用坠落的刺激把自己 Kick 回第一层，
##     落在一层睡着时那张床边（锚点 1），类似《盗梦空间》的穿越。
##   - 右端尽头是保安室：白门 → 进入保安室内部（SecurityRoom，房间里有办公桌和床）。
extends Node2D

const DREAM1_BEDROOM: = "res://scenes/dream1_bedroom/Dream1Bedroom.tscn"
const SECURITY_ROOM: = "res://scenes/dream2_rail_world/SecurityRoom.tscn"
const STREET: = "res://scenes/dream2_street/Street.tscn"
const WORLD_SIZE: Vector2i = Vector2i(5760, 1620)

@onready var player: Player = $Player
@onready var booth_door: Interactable = $Props/Booth/Door/Interactable
@onready var street_entrance: Interactable = $Props/StreetEntrance/Interactable
@onready var cliff: Interactable = $Props/CliffEdge/Interactable


func _ready() -> void:
	GameState.set_dream_layer(2)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	booth_door.interacted.connect(_on_booth_door)
	street_entrance.interacted.connect(_on_street_entrance)
	cliff.interacted.connect(_on_cliff_jump)


func _unhandled_input(event: InputEvent) -> void:
	# 第二层起捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()


func _on_booth_door(_source: Node2D) -> void:
	player.say("推开白色的门，里面亮着灯。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走进保安室……"
	await SceneFader.change_scene(SECURITY_ROOM, 0.85, 1.05, Vector2(1230.0, 560.0))


func _on_street_entrance(_source: Node2D) -> void:
	player.say("护栏外就是大街，路灯一盏接一盏。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走到大街上……"
	await SceneFader.change_scene(STREET, 0.85, 1.05, Vector2(400.0, 1150.0))


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
