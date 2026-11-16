## 第二层梦境·医院内部：大厅 + 1/2/3号通道 + 两扇门 + 随机走动的 NPC。
##
## 占位内容（还没想好）：通道与门都可以互动，但只给占位台词；
## 接诊台/长椅是氛围物件；NPC 随机走动、有碰撞、没有任何效果。
## 底部医院入口 → 回到医院外。Q 捏脸在第二层无效。
extends Node2D

const HOSPITAL_OUTSIDE: = "res://scenes/dream2_hospital_outside/HospitalOutside.tscn"
const WORLD_SIZE: Vector2i = Vector2i(2880, 1620)
const NPC_TEX: = preload("res://assets/art/props/npc.png")
## 随机走动 NPC 的出生点。
const NPC_SPAWNS: Array[Vector2] = [Vector2(800.0, 1150.0), Vector2(1900.0, 1250.0), Vector2(2300.0, 780.0)]

@onready var player: Player = $Player
@onready var exit_door: Interactable = $Props/ExitDoor/Interactable
@onready var reception: Interactable = $Props/Reception/Interactable
@onready var passage1: Interactable = $Props/Passage1/Interactable
@onready var passage2: Interactable = $Props/Passage2/Interactable
@onready var passage3: Interactable = $Props/Passage3/Interactable
@onready var door_a: Interactable = $Props/DoorA/Interactable
@onready var door_b: Interactable = $Props/DoorB/Interactable


func _ready() -> void:
	GameState.set_dream_layer(2)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	exit_door.interacted.connect(_on_exit_door)
	reception.interacted.connect(_on_reception)
	passage1.interacted.connect(_on_passage.bind("1"))
	passage2.interacted.connect(_on_passage.bind("2"))
	passage3.interacted.connect(_on_passage.bind("3"))
	door_a.interacted.connect(_on_door)
	door_b.interacted.connect(_on_door)
	for pos: Vector2 in NPC_SPAWNS:
		_spawn_npc(pos)


func _unhandled_input(event: InputEvent) -> void:
	# 第二层起捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()


func _on_exit_door(_source: Node2D) -> void:
	player.say("走出自动门，外面是救护车和夜风。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走出医院……"
	await SceneFader.change_scene(HOSPITAL_OUTSIDE, 0.85, 1.05, Vector2(960.0, 700.0))


func _on_reception(_source: Node2D) -> void:
	player.say("接待台后面空无一人，叫号屏还在滚动。")


func _on_passage(number: String) -> void:
	# 占位：通道内容还没想好。
	player.say("%s号通道里一片漆黑，什么也看不清。" % number)


func _on_door(_source: Node2D) -> void:
	# 占位：门后的内容还没想好。
	player.say("门锁着。门后暂时什么都没有。")


## 生成一个随机走动的 NPC：有碰撞、无交互、纯氛围。
func _spawn_npc(pos: Vector2) -> void:
	var npc: WanderingNPC = WanderingNPC.new()
	npc.position = pos
	npc.collision_layer = 1
	npc.collision_mask = 1
	var sprite := Sprite2D.new()
	sprite.texture = NPC_TEX
	npc.add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64.0, 110.0)
	shape.shape = rect
	npc.add_child(shape)
	add_child(npc)
