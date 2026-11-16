## 现实卧室（第 0 层）。
##
## 床 → 入睡进入第一层梦境（一层卧室）；
## 书桌 → 弹出选项对话框（保存游戏 / 补充日记本）；
## 门在现实里打不开。
##
## 睡觉时会记下"床边落点"锚点：之后从第一层捏脸醒来（Q）就落回这里。
extends Node2D

const DREAM1_BEDROOM: = "res://scenes/dream1_bedroom/Dream1Bedroom.tscn"
const ChoiceDialogScene: = preload("res://scenes/ui/ChoiceDialog.tscn")
## 床精灵中心到"下床站位"的偏移，各卧室床的布局一致。
const BED_EXIT_OFFSET: = Vector2(60.0, 220.0)

@onready var player: Player = $Player
@onready var bed: Interactable = $Furniture/Bed/Interactable
@onready var nightstand: Interactable = $Furniture/Nightstand/Interactable
@onready var desk: Interactable = $Furniture/Desk/Interactable
@onready var bookshelf: Interactable = $Furniture/Bookshelf/Interactable
@onready var door: Interactable = $Furniture/Door/Interactable


func _ready() -> void:
	GameState.set_dream_layer(GameState.LAYER_REALITY)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, Vector2i(1920, 1080))
	bed.interacted.connect(_on_bed_interacted)
	nightstand.interacted.connect(_on_nightstand_interacted)
	desk.interacted.connect(_on_desk_interacted)
	bookshelf.interacted.connect(_on_bookshelf_interacted)
	door.interacted.connect(_on_door_interacted)


func _on_bed_interacted(_source: Node2D) -> void:
	player.say("把脸埋进枕头，沉沉睡去。")
	player.lock()
	# 记录现实床边落点：从梦里捏脸醒来（Q）时回到这里。
	GameState.record_bed_anchor(GameState.LAYER_REALITY, scene_file_path,
			bed.global_position + BED_EXIT_OFFSET)
	GameState.set_dream_layer(1)
	GameState.dream_count += 1
	GameState.record_position(scene_file_path, player.global_position)
	# 梦层跃迁（0→1）：马赛克转场。
	# 一层多张床时按锚点落位：还没在别的床上睡过，就用一层卧室默认出生点。
	var landing: Vector2 = Vector2(440.0, 780.0)
	var anchor: Dictionary = GameState.bed_anchor(1)
	if not anchor.is_empty():
		landing = anchor["position"]
	await DreamTransition.change_scene(DREAM1_BEDROOM, landing)


func _on_nightstand_interacted(_source: Node2D) -> void:
	# 示例拾取：之后想换别的掉落，改 add_item 的 id 即可。
	if Backpack.add_item("old_lamp"):
		player.say("把床头那盏不亮的旧台灯收进了背包。（按 B 打开背包）")
	else:
		player.say("台灯没开。")


func _on_desk_interacted(_source: Node2D) -> void:
	var dialog: Node = ChoiceDialogScene.instantiate()
	add_child(dialog)
	dialog.open("书桌上摆着日记本和笔。", "保存游戏", "补充日记本", "返回")
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
	if Backpack.add_item("old_book"):
		player.say("从书堆里抽出一本旧书，收进了背包。（按 B 打开背包）")
	else:
		player.say("书架上摆着几本旧书。")


func _on_door_interacted(_source: Node2D) -> void:
	player.say("门打不开。外面很冷。")
