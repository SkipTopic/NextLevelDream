## 背包数据（Autoload）。
##
## 职责边界：
##   物品定义表 + "收集了什么 / 装备了什么"的运行时状态与增删改 API；
##   不含任何 UI（界面在 BackpackUI）与拾取逻辑（各场景脚本自己调用 add_item）。
## 持久化：背包没有自己的存档，是 GameState 日记存档的一部分——
##   每次变化即时同步进 GameState 字段，写日记时随之落盘；
##   读日记 / 新游戏时 GameState 通过信号通知这里回灌。
extends Node

## 背包格子总数（BackpackUI 的网格是 4x4）。
const MAX_SLOTS: int = 16
## 上一版曾把背包单独存到 user://backpack.save，现已并入日记存档。
const LEGACY_SAVE_PATH := "user://backpack.save"
## 物品逐层介绍覆盖表（物品 id × 梦层 → 介绍文本），可直接编辑，
## 背包每次打开都会热加载；缺的层回退到 ITEMS 里的基础 description。
const DESCRIPTIONS_PATH := "res://data/item_descriptions.json"

## 物品定义表：id -> {name, description, icon, equippable, usable}。
## icon 目前借用场景道具图占位，之后替换成专门的物品图标即可。
## 规则：所有道具全局唯一（不叠数量）、永不消耗——安眠药这类"钥匙"道具用后仍在。
## usable = true 的物品在背包里显示"使用"按钮（如手枪：回上一层梦境）。
const ITEMS: Dictionary = {
	"sleeping_pills": {
		"name": "安眠药",
		"description": "贴着'深梦'标签的小药瓶。在梦里的床上吞下它，就能坠入更深的梦境。",
		"icon": "res://assets/art/props/pills.png",
		"equippable": false,
	},
	"pistol": {
		"name": "手枪",
		"description": "保安抽屉里的手枪。梦里的枪声足以震醒自己——回到上一层入睡的地方。",
		"icon": "res://assets/art/props/pistol.png",
		"equippable": false,
		"usable": true,
	},
	"scooter": {
		"name": "电瓶车",
		"description": "大街上随手一停的电瓶车，钥匙还插在上面。装备之后走起路来轻快多了。",
		"icon": "res://assets/art/props/scooter.png",
		"equippable": true,
	},
	"anesthetic": {
		"name": "麻醉剂",
		"description": "救护车上的麻醉剂。在第二层梦里的床上使用，就能坠入第三层梦境。",
		"icon": "res://assets/art/props/anesthetic.png",
		"equippable": false,
	},
	"book_sleeve": {
		"name": "书籍保护套",
		"description": "钓鱼人送的防水书套。装备后，日记本泡在第四层的海水里也不会湿。",
		"icon": "res://assets/art/props/book_sleeve.png",
		"equippable": true,
	},
	"old_book": {
		"name": "《梦见乌鸦的少年》",
		"description": "从现实卧室的书架上抽出来的旧书。书页间还夹着一根乌鸦羽毛。",
		"icon": "res://assets/art/props/bookshelf.png",
		"equippable": true,
	},
	"old_lamp": {
		"name": "不会亮的台灯",
		"description": "床头柜上的旧台灯。无论按多少次开关，灯丝都没有一丝光。",
		"icon": "res://assets/art/props/nightstand.png",
		"equippable": true,
	},
	"wordless_book": {
		"name": "无字之书",
		"description": "梦里书架上的一本书。书脊上写满看不懂的字，翻开却是空白。",
		"icon": "res://assets/art/props/bookshelf.png",
		"equippable": true,
	},
}

## 收集到新物品。
signal item_added(id: String)
## 移除了物品。
signal item_removed(id: String)
## 装备发生变化；参数为当前装备的物品 id，空字符串表示卸下了装备。
signal equipped_changed(id: String)

## 已收集的物品 id，按拾取顺序排列。
var items: Array[String] = []
## 当前装备的物品 id；空字符串表示没有装备。
var equipped_id: String = ""
## 逐层介绍覆盖表：id -> {梦层字符串: 文本}；由 data/item_descriptions.json 热加载。
var _layer_descriptions: Dictionary = {}


func _ready() -> void:
	# 读日记 / 新游戏后，GameState 的背包字段落定，这里跟着回灌运行时状态。
	GameState.diary_read.connect(pull_from_state)
	GameState.run_reset.connect(pull_from_state)
	pull_from_state()
	reload_item_descriptions()
	# 清掉上一版遗留的独立存档，避免误以为它还有效。
	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(LEGACY_SAVE_PATH)


# --- 公共 API ------------------------------------------------------------

## 收集一个物品。首次收集且背包未满时返回 true；重复收集返回 false。
func add_item(id: String) -> bool:
	if not ITEMS.has(id):
		push_warning("Backpack: 未定义的物品 id：%s" % id)
		return false
	if has_item(id):
		return false
	if items.size() >= MAX_SLOTS:
		push_warning("Backpack: 背包已满，%s 没有被收下。" % id)
		return false
	items.append(id)
	push_to_state()
	item_added.emit(id)
	return true


func has_item(id: String) -> bool:
	return items.has(id)


## 移除一个物品；若它正被装备则一并卸下。
func remove_item(id: String) -> void:
	if not has_item(id):
		return
	items.erase(id)
	if equipped_id == id:
		equipped_id = ""
		equipped_changed.emit(equipped_id)
	push_to_state()
	item_removed.emit(id)


## 物品信息表条目；未定义的 id 返回空字典。
func get_item_info(id: String) -> Dictionary:
	return ITEMS.get(id, {})


## 物品在当前梦层的介绍：先查 data/item_descriptions.json 的覆盖表，
## 该层没写就回退到 ITEMS 里的基础 description。
func get_item_description(id: String) -> String:
	var base: String = String(get_item_info(id).get("description", ""))
	if not _layer_descriptions.has(id):
		return base
	var per_layer: Dictionary = _layer_descriptions[id]
	var key := str(GameState.dream_layer)
	return String(per_layer.get(key, base))


## 重新读取逐层介绍文件；背包每次打开都会调用，改完 JSON 立即生效。
func reload_item_descriptions() -> void:
	_layer_descriptions = {}
	if not FileAccess.file_exists(DESCRIPTIONS_PATH):
		return
	var file: FileAccess = FileAccess.open(DESCRIPTIONS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Backpack: 逐层介绍文件无法读取 %s" % DESCRIPTIONS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Backpack: 逐层介绍文件格式不对（应为 JSON 对象），已忽略。")
		return
	_layer_descriptions = parsed


## 物品在逐层介绍文件里是否有条目（约定：每个新物品都必须加一条，回归测试守护）。
func has_description_entry(id: String) -> bool:
	return _layer_descriptions.has(id)


func is_equipped(id: String) -> bool:
	return not id.is_empty() and equipped_id == id


## 装备一个已收集、可装备的物品。
func equip(id: String) -> void:
	if not has_item(id):
		return
	if not bool(get_item_info(id).get("equippable", false)):
		return
	if equipped_id == id:
		return
	equipped_id = id
	push_to_state()
	equipped_changed.emit(equipped_id)


## 卸下当前装备。
func unequip() -> void:
	if equipped_id.is_empty():
		return
	equipped_id = ""
	push_to_state()
	equipped_changed.emit(equipped_id)


# --- 与 GameState 的双向同步 ---------------------------------------------

## 把运行时背包写进 GameState 字段（每次增删 / 装备后调用），
## 真正落盘发生在下一次写日记（GameState.save_diary）时。
func push_to_state() -> void:
	GameState.backpack_items.assign(items)
	GameState.backpack_equipped = equipped_id


## 从 GameState 字段读回运行时背包；读日记 / 新游戏后由信号触发。
func pull_from_state() -> void:
	items.assign(GameState.backpack_items)
	# 存档里装备的物品必须仍在背包中，否则视为未装备。
	var equipped: String = GameState.backpack_equipped
	equipped_id = equipped if has_item(equipped) else ""
