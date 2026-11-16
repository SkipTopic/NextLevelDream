## 第三层梦境·草原小屋内部：白床 + 各种仪器。
##
## 床 → 弹出确认框："要进入更深一层的梦境吗？"
##   确定 → 记录锚点后进入第四层（海洋）；拒绝 → 什么都不会发生。
## 门 → 走出房子回草原。Q 捏脸在第三层无效。
extends Node2D

const DREAM3_GRASS_WORLD: = "res://scenes/dream3_grass_world/Dream3GrassWorld.tscn"
const DREAM4_OCEAN: = "res://scenes/dream4_ocean/Dream4Ocean.tscn"
const ChoiceDialogScene: = preload("res://scenes/ui/ChoiceDialog.tscn")
## 床精灵中心到"下床站位"的偏移。
const BED_EXIT_OFFSET: = Vector2(60.0, 220.0)
## 第四层海洋的醒来落点。
const OCEAN_SPAWN: = Vector2(1440.0, 900.0)
## 走出房子回到草原的落点（小屋门前）。
const GRASS_LANDING: = Vector2(450.0, 990.0)

@onready var player: Player = $Player
@onready var bed: Interactable = $Furniture/Bed/Interactable
@onready var exit_door: Interactable = $Furniture/Door/Interactable


func _ready() -> void:
	GameState.set_dream_layer(3)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, Vector2i(1920, 1080))
	bed.interacted.connect(_on_bed_interacted)
	exit_door.interacted.connect(_on_exit_door)


func _unhandled_input(event: InputEvent) -> void:
	# 第三层捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()


func _on_bed_interacted(_source: Node2D) -> void:
	var dialog: Node = ChoiceDialogScene.instantiate()
	add_child(dialog)
	dialog.open("白色的床连着几台仪器，导管还在轻微地起伏。要进入更深一层的梦境吗？",
			"确定", "拒绝")
	dialog.choice_made.connect(_on_bed_choice.bind(dialog))


## 确定 → 沉入第四层；拒绝 → 什么都不会发生（对话框自己关闭）。
func _on_bed_choice(index: int, dialog: Node) -> void:
	if index != 0:
		return
	player.lock()
	# 记录三层床边落点：从第四层回来（手枪）时回到这张床边。
	GameState.record_bed_anchor(3, scene_file_path, bed.global_position + BED_EXIT_OFFSET)
	GameState.set_dream_layer(4)
	GameState.dream_count += 1
	GameState.record_position(scene_file_path, player.global_position)
	# 梦层跃迁（3→4）：马赛克转场。沉入无边的大海。
	await DreamTransition.change_scene(DREAM4_OCEAN, OCEAN_SPAWN)


func _on_exit_door(_source: Node2D) -> void:
	player.say("门外是草原的风。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走出房子……"
	await SceneFader.change_scene(DREAM3_GRASS_WORLD, 0.85, 1.05, GRASS_LANDING)
