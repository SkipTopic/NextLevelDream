## 第二层梦境·医院外：门诊楼 + 入口雨棚 + 救护车。
##
## 导航：
##   - 从大街下方进来（落点在左侧）
##   - 大门 → 进入医院内部
##   - 救护车 → 拾取麻醉剂（第二层床上用，进入第三层的钥匙）
##   - Q 捏脸在第二层无效
extends Node2D

const DREAM1_BEDROOM: = "res://scenes/dream1_bedroom/Dream1Bedroom.tscn"
const HOSPITAL_INSIDE: = "res://scenes/dream2_hospital_inside/HospitalInside.tscn"
const STREET: = "res://scenes/dream2_street/Street.tscn"
## 回大街的落点：大街下方医院入口旁边。
const STREET_LANDING: = Vector2(1970.0, 1250.0)

@onready var player: Player = $Player
@onready var entrance: Interactable = $Props/Entrance/Interactable
@onready var ambulance: Interactable = $Props/Ambulance/Interactable
@onready var ambulance_sprite: Sprite2D = $Props/Ambulance/Sprite2D
@onready var street_exit: Interactable = $Props/StreetExit/Interactable


func _ready() -> void:
	GameState.set_dream_layer(2)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, Vector2i(1920, 1080))
	entrance.interacted.connect(_on_entrance)
	ambulance.interacted.connect(_on_ambulance_interacted)
	street_exit.interacted.connect(_on_street_exit)
	_refresh_ambulance()


func _refresh_ambulance() -> void:
	var collected: bool = Backpack.has_item("anesthetic")
	ambulance_sprite.visible = not collected
	ambulance.enabled = not collected


func _unhandled_input(event: InputEvent) -> void:
	# 第二层起捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()


func _on_entrance(_source: Node2D) -> void:
	player.say("消毒水的味道扑面而来。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走进医院……"
	await SceneFader.change_scene(HOSPITAL_INSIDE, 0.85, 1.05, Vector2(1440.0, 1250.0))


func _on_ambulance_interacted(_source: Node2D) -> void:
	if Backpack.add_item("anesthetic"):
		_refresh_ambulance()
		player.say("从救护车里翻出一支麻醉剂。（按 B 打开背包）")
	else:
		player.say("救护车里已经翻过了。")


func _on_street_exit(_source: Node2D) -> void:
	player.say("沿着马路走回大街。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "回到大街……"
	await SceneFader.change_scene(STREET, 0.85, 1.05, STREET_LANDING)
