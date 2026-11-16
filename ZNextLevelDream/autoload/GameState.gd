## 全局存档状态（"日记"）。
##
## 职责边界：
##   仅保存跨场景持久化的数据（场景路径、坐标、剩余日记页、做梦次数、
##   梦层与床锚点、背包物品）。
##   不含任何玩法逻辑；UI、交互、场景切换都不在此脚本里。
## 存档格式：JSON 写入 user://diary.save，附带版本号便于未来迁移。
##
## 梦层模型（《梦日记》×《盗梦空间》）：
##   0 = 现实；1~4 = 第 N 层梦境，越深醒来越难。
##   床锚点：在某层"睡进更深一层"时，把那层床边的落点记下来；
##   之后从更深处醒来 / 坠落回这一层时，直接落回锚点，
##   而不是场景默认出生点——一层多张床时也不会"起来发现自己在别的地方"。
extends Node

const SAVE_PATH := "user://diary.save"
const SAVE_VERSION: int = 4
## 仍能读取的旧版本；v2 没有背包字段，v3 没有梦层字段，缺的按默认处理。
const READABLE_VERSIONS: Array = [2, 3, 4]

## 现实世界的梦层编号。
const LAYER_REALITY: int = 0
## 梦境最深层（第三、四层尚未实装场景）。
const LAYER_MAX: int = 4
const MAX_DIARY_PAGES: int = 15

## 存档写入完成。
signal diary_written
## 存档读取完成。
signal diary_read
## 日记页数变化。
signal diary_changed(remaining: int)
## 日记被填满。
signal diary_refilled
## 新游戏：所有持久化字段已回到初始值（背包、做梦次数、日记页等）。
signal run_reset

## 是否处于梦境中。
var is_dreaming: bool = false
## 当前梦层：0 = 现实，1~4 = 第 N 层梦境。
var dream_layer: int = LAYER_REALITY
## 梦层锚点：layer -> {"scene": String, "x": float, "y": float}。
## 记录的是"该层床边的落点"，用于从更深处醒来 / 坠落时落位。
var bed_anchors: Dictionary = {}
## 玩家当前所在场景文件路径。
var current_scene_path: String = "res://scenes/bedroom/Bedroom.tscn"
## 玩家在 current_scene_path 中的坐标。
var player_position: Vector2 = Vector2(960.0, 860.0)
## 场景切换时希望玩家落地的位置；Vector2.INF 表示使用场景默认位置。
var pending_player_position: Vector2 = Vector2.INF
## 累计做梦次数。
var dream_count: int = 0
## 剩余日记页数（"弹药"）；为 0 时不可存档。
var diary_pages: int = MAX_DIARY_PAGES
## 背包：已收集的物品 id 与当前装备；由 Backpack 维护，随日记存档落盘。
var backpack_items: Array[String] = []
var backpack_equipped: String = ""


## 新游戏：把一次新周目的所有持久化字段回到初始值（含背包）。
##
## 存档文件不动——"阅读日记"仍能读到上一次写的日记，
## 直到新周目里再次写日记把它覆盖。
func new_game() -> void:
	set_dreaming(false)
	dream_layer = LAYER_REALITY
	bed_anchors = {}
	current_scene_path = "res://scenes/reality_bedroom/RealityBedroom.tscn"
	player_position = Vector2(960.0, 860.0)
	pending_player_position = Vector2.INF
	dream_count = 0
	diary_pages = MAX_DIARY_PAGES
	backpack_items = []
	backpack_equipped = ""
	run_reset.emit()
	diary_changed.emit(diary_pages)


## 切换梦层（0 = 现实，1~4 = 第 N 层梦境）；is_dreaming 随之联动。
func set_dream_layer(value: int) -> void:
	if dream_layer == value:
		return
	dream_layer = value
	set_dreaming(value >= 1)


## 在第 for_layer 层的床上睡进更深层之前，记下这张床边的落点。
func record_bed_anchor(for_layer: int, scene_path: String, position: Vector2) -> void:
	bed_anchors[for_layer] = {"scene": scene_path, "x": position.x, "y": position.y}


## 回到第 layer 层时应落的位置：{"scene": String, "position": Vector2}；没有锚点返回空字典。
func bed_anchor(layer: int) -> Dictionary:
	if not bed_anchors.has(layer):
		return {}
	var entry: Dictionary = bed_anchors[layer]
	return {
		"scene": String(entry.get("scene", "")),
		"position": Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))),
	}


func has_diary_entry() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 在玩家当前实时坐标写入日记，消耗 1 页；页用尽或写入失败时返回 false。
##
## 关键点：写入前一定会调用 capture_player_position() 重新抓取玩家实时坐标，
## 避免存下的是"进入该场景时的落点"而不是"按下存档键时站的位置"。
func save_diary() -> bool:
	if diary_pages <= 0:
		return false
	if not capture_player_position():
		push_warning("GameState: 场景树中没找到玩家，沿用上一次记录的坐标。")
	diary_pages -= 1
	if _write_diary():
		diary_written.emit()
		diary_changed.emit(diary_pages)
		return true
	# 写入失败则回退页数。
	diary_pages += 1
	return false


## 直接消耗 1 页（不写档、不回退）——第四层海水的浸页规则用。
## 页数到 0 时，死亡结算层（GameOver）会通过 diary_changed 监听到并触发游戏结束。
func consume_page() -> bool:
	if diary_pages <= 0:
		return false
	diary_pages -= 1
	diary_changed.emit(diary_pages)
	return true


## 在当前坐标写入日记，不消耗页数。
func _write_diary() -> bool:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"is_dreaming": is_dreaming,
		"scene_path": current_scene_path,
		"player_x": player_position.x,
		"player_y": player_position.y,
		"dream_count": dream_count,
		"diary_pages": diary_pages,
		"backpack_items": backpack_items,
		"backpack_equipped": backpack_equipped,
		"dream_layer": dream_layer,
		"bed_anchors": bed_anchors,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: 无法写入日记 %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return true


## 从磁盘读取日记；不存在或损坏时返回 false。
func read_diary() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GameState: 日记文件已损坏。")
		return false
	var payload: Dictionary = parsed
	if not READABLE_VERSIONS.has(int(payload.get("version", 0))):
		push_warning("GameState: 日记版本不匹配，已忽略。")
		return false
	is_dreaming = bool(payload.get("is_dreaming", false))
	# v2/v3 旧档没有梦层字段：按 is_dreaming 推断（睡过觉就视为在第 1 层）。
	dream_layer = int(payload.get("dream_layer", -1))
	if dream_layer < 0:
		dream_layer = 1 if is_dreaming else LAYER_REALITY
	bed_anchors.clear()
	var raw_anchors: Variant = payload.get("bed_anchors", {})
	if typeof(raw_anchors) == TYPE_DICTIONARY:
		# JSON 的对象键都是字符串，转回 int 键。
		for key: Variant in raw_anchors:
			bed_anchors[int(key)] = raw_anchors[key]
	current_scene_path = String(payload.get("scene_path", current_scene_path))
	player_position = Vector2(
		float(payload.get("player_x", player_position.x)),
		float(payload.get("player_y", player_position.y)),
	)
	dream_count = int(payload.get("dream_count", 0))
	diary_pages = int(payload.get("diary_pages", MAX_DIARY_PAGES))
	backpack_items.assign(payload.get("backpack_items", []))
	backpack_equipped = String(payload.get("backpack_equipped", ""))
	pending_player_position = player_position
	diary_read.emit()
	diary_changed.emit(diary_pages)
	return true


## 回到主世界后给日记本补满页数。
func refill_diary() -> void:
	diary_pages = MAX_DIARY_PAGES
	diary_refilled.emit()
	diary_changed.emit(diary_pages)


## 由场景脚本调用，记录玩家当前所处的场景与坐标。
func record_position(scene_path: String, position: Vector2) -> void:
	current_scene_path = scene_path
	player_position = position


## 从场景树里抓取玩家的实时 global_position 与当前场景路径，刷新上面两个字段。
##
## 这是"读档回到写日记那一刻"的关键：场景脚本只在 _ready() 里记录过一次落点，
## 玩家走动后必须重新抓取，否则存档里永远是进场景时的坐标。
## 找到玩家并返回 true；找不到时保留旧值并返回 false。
func capture_player_position() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var current: Node = tree.current_scene
	if current == null or current.scene_file_path.is_empty():
		return false
	var found: Node2D = _find_player(current)
	if found == null:
		return false
	current_scene_path = current.scene_file_path
	player_position = found.global_position
	return true


## 深度优先在当前场景里找 Player 节点。
func _find_player(node: Node) -> Node2D:
	if node is Player:
		return node as Node2D
	for child: Node in node.get_children():
		var result: Node2D = _find_player(child)
		if result != null:
			return result
	return null


## 切换梦境状态，并广播给所有监听者。
func set_dreaming(value: bool) -> void:
	if is_dreaming == value:
		return
	is_dreaming = value
	GameEvents.dream_state_changed.emit(value)
