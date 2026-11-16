## 第一层梦境·主通道：一层卧室门后的多门走廊，类似《梦日记》的 8 扇门世界。
##
## 当前已开：
##   - 红色门 → 一层·流星世界（可捡安眠药）
##   - 绿色门 → 一层·深林世界
## 其余蓝色 / 黄色门目前用 "门后什么都没有" 锁定（占位，后续可逐个接入新世界）。
##
## 玩家从一层卧室的门进入这里（spawn = (1440, 800)）。
## Q → 捏脸醒来回到现实的床边（第一层专属）。
extends Node2D

const DREAM1_METEOR_WORLD: = "res://scenes/dream1_meteor_world/Dream1MeteorWorld.tscn"
const DREAM1_DEEP_FOREST: = "res://scenes/dream1_deep_forest/Dream1DeepForest.tscn"
const DREAM1_BEDROOM: = "res://scenes/dream1_bedroom/Dream1Bedroom.tscn"
const REALITY_BEDROOM: = "res://scenes/reality_bedroom/RealityBedroom.tscn"

const WORLD_SIZE: Vector2i = Vector2i(2880, 1620)

@onready var player: Player = $Player
@onready var wake_up: WakeUpComponent = $WakeUp
@onready var door_meteor: Interactable = $Doors/Meteor/Interactable
@onready var door_forest: Interactable = $Doors/Forest/Interactable
@onready var door_locked_a: Interactable = $Doors/LockedA/Interactable
@onready var door_locked_b: Interactable = $Doors/LockedB/Interactable
@onready var portal: Interactable = $Portal/Interactable


func _ready() -> void:
	GameState.set_dream_layer(1)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	door_meteor.interacted.connect(_on_door_meteor)
	door_forest.interacted.connect(_on_door_forest)
	door_locked_a.interacted.connect(_on_door_locked.bind(player))
	door_locked_b.interacted.connect(_on_door_locked.bind(player))
	portal.interacted.connect(_on_portal)
	wake_up.wake_requested.connect(_on_wake_up)


func _on_door_meteor(_source: Node2D) -> void:
	player.say("门外是流星。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "流星正在落下……"
	await SceneFader.change_scene(DREAM1_METEOR_WORLD, 0.85, 1.05, Vector2(1440.0, 1100.0))


func _on_door_forest(_source: Node2D) -> void:
	player.say("门外是深林。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "树影正在摇晃……"
	await SceneFader.change_scene(DREAM1_DEEP_FOREST, 0.85, 1.05, Vector2(1440.0, 1100.0))


func _on_door_locked(player_ref: Node2D) -> void:
	player_ref.say("门后什么都没有。")


func _on_portal(_source: Node2D) -> void:
	player.say("光里是那间卧室。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "回到房间……"
	await SceneFader.change_scene(DREAM1_BEDROOM, 0.85, 1.05, Vector2(1230.0, 420.0))


func _on_wake_up() -> void:
	player.lock()
	# 捏脸醒来：落回现实里睡着的那张床边（锚点 0）。
	GameState.set_dream_layer(GameState.LAYER_REALITY)
	var target: String = REALITY_BEDROOM
	var landing: Vector2 = Vector2(440.0, 780.0)
	var anchor: Dictionary = GameState.bed_anchor(GameState.LAYER_REALITY)
	if not anchor.is_empty():
		target = anchor["scene"]
		landing = anchor["position"]
	GameState.record_position(target, landing)
	# 梦层跃迁（1→0）：马赛克转场。
	await DreamTransition.change_scene(target, landing)
