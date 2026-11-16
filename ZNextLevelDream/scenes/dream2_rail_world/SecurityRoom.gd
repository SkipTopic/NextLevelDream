## 第二层梦境·保安室内部：从轨道世界的白门进来后的单屏房间。
##
## 布局：白门（北墙，出口回轨道世界）+ 办公桌（东侧）+ 床（西侧）。
## 床 → 第三层梦境的入口（第三层尚未建成，先给占位台词；
## 建成后在同一处按"记录锚点 → change_scene"的模式接入）。
## Q 捏脸在第二层无效（与轨道世界一致的反馈）。
extends Node2D

const DREAM2_RAIL_WORLD: = "res://scenes/dream2_rail_world/Dream2RailWorld.tscn"
const DREAM3_GRASS_WORLD: = "res://scenes/dream3_grass_world/Dream3GrassWorld.tscn"
## 从轨道世界推门进来的落点（白门内侧）。
const SPAWN_FROM_RAIL: = Vector2(1230.0, 560.0)
## 出门回到轨道世界的落点（保安室白门外）。
const EXIT_LANDING: = Vector2(5000.0, 1150.0)
## 床精灵中心到"下床站位"的偏移（与现实/一层卧室一致）。
const BED_EXIT_OFFSET: = Vector2(60.0, 220.0)
## 第三层草地世界的醒来落点（背靠大树）。
const GRASS_SPAWN: = Vector2(1440.0, 950.0)

@onready var player: Player = $Player
@onready var door: Interactable = $Furniture/Door/Interactable
@onready var desk: Interactable = $Furniture/Desk/Interactable
@onready var bed: Interactable = $Furniture/Bed/Interactable
@onready var pistol: Interactable = $Furniture/Pistol/Interactable
@onready var pistol_sprite: Sprite2D = $Furniture/Pistol/Sprite2D


func _ready() -> void:
	GameState.set_dream_layer(2)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, Vector2i(1920, 1080))
	door.interacted.connect(_on_door_interacted)
	desk.interacted.connect(_on_desk_interacted)
	bed.interacted.connect(_on_bed_interacted)
	pistol.interacted.connect(_on_pistol_interacted)
	# 读档 / 重进场景时同步拾取状态（隐藏贴图并禁用交互区，避免隐形道具冒提示）。
	_refresh_pistol()


func _refresh_pistol() -> void:
	var collected: bool = Backpack.has_item("pistol")
	pistol_sprite.visible = not collected
	pistol.enabled = not collected


func _unhandled_input(event: InputEvent) -> void:
	# 第二层起捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()


func _on_door_interacted(_source: Node2D) -> void:
	player.say("门外是铁轨和风声。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走出保安室……"
	await SceneFader.change_scene(DREAM2_RAIL_WORLD, 0.85, 1.05, EXIT_LANDING)


func _on_desk_interacted(_source: Node2D) -> void:
	player.say("值班记录写满了看不懂的符号。")


func _on_bed_interacted(_source: Node2D) -> void:
	if not Backpack.has_item("anesthetic"):
		player.say("床铺得整整齐齐。不麻醉一下，怎么也睡不进更深的梦。")
		return
	player.say("麻醉剂推进血管，梦一层一层塌了下去。")
	player.lock()
	# 记录二层床边落点：从第三层回来（手枪/坠落）时回到这张床边。
	GameState.record_bed_anchor(2, scene_file_path, bed.global_position + BED_EXIT_OFFSET)
	GameState.set_dream_layer(3)
	GameState.dream_count += 1
	GameState.record_position(scene_file_path, player.global_position)
	# 梦层跃迁（2→3）：马赛克转场。麻醉下沉。
	await DreamTransition.change_scene(DREAM3_GRASS_WORLD, GRASS_SPAWN)


func _on_pistol_interacted(_source: Node2D) -> void:
	if Backpack.add_item("pistol"):
		_refresh_pistol()
		player.say("把抽屉里的手枪揣进了兜里。（按 B 打开背包）")
	else:
		player.say("枪已经在身上了。")
