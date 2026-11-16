## 第一层梦境·流星世界：2880x1620，下落流星由 MeteorSpawner 持续生成。
##
## 导航与要点：
##   - 底部传送门 → 回到一层·主通道
##   - 陨石坑边的药瓶 → 捡到"安眠药"（唯一道具，不消耗），是一层→二层的钥匙
##   - Q → 捏脸醒来回现实（第一层专属）
extends Node2D

const DREAM1_NEXUS: = "res://scenes/dream1_nexus/Dream1Nexus.tscn"
const REALITY_BEDROOM: = "res://scenes/reality_bedroom/RealityBedroom.tscn"
const PORTAL_TEX: = preload("res://assets/art/props/portal.png")

const WORLD_SIZE: Vector2i = Vector2i(2880, 1620)

@onready var player: Player = $Player
@onready var portal: Interactable = $Props/Portal/Interactable
@onready var pills: Interactable = $Props/Pills/Interactable
@onready var pills_sprite: Sprite2D = $Props/Pills/Sprite2D
@onready var wake_up: WakeUpComponent = $WakeUp


func _ready() -> void:
	GameState.set_dream_layer(1)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	portal.interacted.connect(_on_portal)
	pills.interacted.connect(_on_pills_interacted)
	wake_up.wake_requested.connect(_on_wake_up)
	# 读档 / 重进场景时同步拾取状态：已收下药瓶就隐藏贴图并禁用交互区，
	# 否则会出现在隐形药瓶上冒出提示的 bug。
	_refresh_pills()


func _refresh_pills() -> void:
	var collected: bool = Backpack.has_item("sleeping_pills")
	pills_sprite.visible = not collected
	pills.enabled = not collected


func _on_portal(_source: Node2D) -> void:
	player.say("门里是主通道。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "梦在流动……"
	await SceneFader.change_scene(DREAM1_NEXUS, 0.85, 1.05, Vector2(1440, 800))


func _on_pills_interacted(_source: Node2D) -> void:
	if Backpack.add_item("sleeping_pills"):
		_refresh_pills()
		player.say("捡起一瓶安眠药。标签上写着：深梦。（按 B 打开背包）")
	else:
		# 道具不消耗，理论上只会在读档异常时走到这里。
		player.say("药瓶已经在背包里了。")


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
