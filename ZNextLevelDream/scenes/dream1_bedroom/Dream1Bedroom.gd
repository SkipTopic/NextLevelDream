## 第一层梦境·卧室：与现实卧室同布局。
##
## 床 → 检查背包里有没有安眠药：有则坠入第二层（轨道世界），没有则睡不更深；
## 书桌 → 保存游戏 / 补充日记本；
## 门 → 进入主通道（一层·多门世界）；
## Q → 捏脸醒来回现实（第一层专属；从这一层往更深走之前记得这是唯一的轻醒出口）。
extends Node2D

const DREAM1_NEXUS: = "res://scenes/dream1_nexus/Dream1Nexus.tscn"
const DREAM2_RAIL_WORLD: = "res://scenes/dream2_rail_world/Dream2RailWorld.tscn"
const REALITY_BEDROOM: = "res://scenes/reality_bedroom/RealityBedroom.tscn"
const ChoiceDialogScene: = preload("res://scenes/ui/ChoiceDialog.tscn")
## 床精灵中心到"下床站位"的偏移，与现实卧室一致。
const BED_EXIT_OFFSET: = Vector2(60.0, 220.0)
## 第二层轨道世界的默认出生点（首次坠入时还没有锚点）。
const RAIL_WORLD_SPAWN: = Vector2(900.0, 1150.0)

@onready var player: Player = $Player
@onready var bed: Interactable = $Furniture/Bed/Interactable
@onready var nightstand: Interactable = $Furniture/Nightstand/Interactable
@onready var desk: Interactable = $Furniture/Desk/Interactable
@onready var bookshelf: Interactable = $Furniture/Bookshelf/Interactable
@onready var door: Interactable = $Furniture/Door/Interactable
@onready var wake_up: WakeUpComponent = $WakeUp


func _ready() -> void:
	GameState.set_dream_layer(1)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, Vector2i(1920, 1080))
	bed.interacted.connect(_on_bed_interacted)
	nightstand.interacted.connect(_on_nightstand_interacted)
	desk.interacted.connect(_on_desk_interacted)
	bookshelf.interacted.connect(_on_bookshelf_interacted)
	door.interacted.connect(_on_door_interacted)
	wake_up.wake_requested.connect(_on_wake_up)


func _on_bed_interacted(_source: Node2D) -> void:
	if not Backpack.has_item("sleeping_pills"):
		player.say("翻来覆去睡不着。总觉得得吃点什么，才能睡得比梦更深。")
		return
	player.say("就着安眠药躺下，梦一下子沉了下去。")
	player.lock()
	# 记录一层床边落点：从第二层跳崖坠落时回到这张床边。
	GameState.record_bed_anchor(1, scene_file_path, bed.global_position + BED_EXIT_OFFSET)
	GameState.set_dream_layer(2)
	GameState.dream_count += 1
	GameState.record_position(scene_file_path, player.global_position)
	# 梦层跃迁（1→2）：马赛克转场。药力下沉的拖拽感靠马赛克渐变节奏。
	SceneFader.loading_text = "药力把梦压向更深处……"
	await DreamTransition.change_scene(DREAM2_RAIL_WORLD, RAIL_WORLD_SPAWN)


func _on_nightstand_interacted(_source: Node2D) -> void:
	player.say("灯是冷的。")


func _on_desk_interacted(_source: Node2D) -> void:
	var dialog: Node = ChoiceDialogScene.instantiate()
	add_child(dialog)
	dialog.open("梦里的书桌也能写日记。", "保存游戏", "补充日记本", "返回")
	dialog.choice_made.connect(_on_desk_choice.bind(dialog))


func _on_desk_choice(index: int, dialog: Node) -> void:
	if index == 0:
		# 坐标由 GameState.save_diary() 内部实时抓取，这里不需要手动 record_position。
		if GameState.save_diary():
			player.say("用笔把这一刻写进了日记。")
		else:
			player.say("日记已经写满了。先补充吧。")
	else:
		GameState.refill_diary()
		player.say("日记纸填满了。")


func _on_bookshelf_interacted(_source: Node2D) -> void:
	if Backpack.add_item("wordless_book"):
		player.say("抽下那本无字之书，收进了背包。（按 B 打开背包）")
	else:
		player.say("书脊上写满了我看不懂的字。")


func _on_door_interacted(_source: Node2D) -> void:
	player.say("门把一转，背后就是主通道。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "梦在流动……"
	await SceneFader.change_scene(DREAM1_NEXUS, 0.85, 1.05, Vector2(1440, 1300))


func _on_wake_up() -> void:
	player.lock()
	# 捏脸醒来：落回现实里睡着的那张床边（锚点 0），而不是固定出生点。
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
