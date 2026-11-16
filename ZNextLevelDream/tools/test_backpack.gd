## 背包回归测试：收集 → 去重 → 并入日记存档往返 → 新游戏清空 → UI 开关。
##
## 运行（无需改 project.godot，直接跑本场景）：
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tools/test_backpack.tscn
## 看到 "TEST RESULT: PASS" 即通过。
##
## 测试会真实写一次日记存档来验证背包随之落盘，但结束前会按字节还原
## 存档文件与所有内存状态，不影响真实存档。
extends Node

var _failures: Array[String] = []
var _snap_items: Array[String] = []
var _snap_equipped: String = ""
var _snap_scene_path: String
var _snap_player_pos: Vector2
var _snap_pending: Vector2
var _snap_dreaming: bool
var _snap_dream_count: int
var _snap_pages: int
var _had_diary_file: bool = false
var _snap_diary_file: String = ""


func _ready() -> void:
	await get_tree().process_frame
	_take_snapshot()
	_run_checks()
	_restore_snapshot()
	print("TEST RESULT: %s" % ["PASS" if _failures.is_empty() else "FAIL"])
	for failure in _failures:
		print("  - " + failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _take_snapshot() -> void:
	_snap_items = Backpack.items.duplicate()
	_snap_equipped = Backpack.equipped_id
	_snap_scene_path = GameState.current_scene_path
	_snap_player_pos = GameState.player_position
	_snap_pending = GameState.pending_player_position
	_snap_dreaming = GameState.is_dreaming
	_snap_dream_count = GameState.dream_count
	_snap_pages = GameState.diary_pages
	_had_diary_file = FileAccess.file_exists(GameState.SAVE_PATH)
	if _had_diary_file:
		_snap_diary_file = FileAccess.get_file_as_string(GameState.SAVE_PATH)


func _restore_snapshot() -> void:
	Backpack.items = _snap_items
	Backpack.equipped_id = _snap_equipped
	Backpack.push_to_state()
	GameState.current_scene_path = _snap_scene_path
	GameState.player_position = _snap_player_pos
	GameState.pending_player_position = _snap_pending
	GameState.is_dreaming = _snap_dreaming
	GameState.dream_count = _snap_dream_count
	GameState.diary_pages = _snap_pages
	if _had_diary_file:
		var file: FileAccess = FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		file.store_string(_snap_diary_file)
		file.close()
	else:
		DirAccess.remove_absolute(GameState.SAVE_PATH)


func _run_checks() -> void:
	# --- 从干净的空背包开始（测试前的状态在结束时恢复）---
	Backpack.items.clear()
	Backpack.equipped_id = ""
	Backpack.push_to_state()

	# --- 收集与去重 ---
	_check(Backpack.add_item("old_book"), true, "收集 old_book")
	_check(Backpack.add_item("old_book"), false, "重复收集被拒绝")
	_check(Backpack.add_item("not_exist"), false, "未定义的 id 被拒绝")
	_check(Backpack.add_item("old_lamp"), true, "收集 old_lamp")
	_check(Backpack.items.size(), 2, "背包里共有 2 件物品")
	_check(GameState.backpack_items.size(), 2, "收集即时同步进 GameState")

	# --- 装备 / 卸下 ---
	Backpack.equip("old_book")
	_check(Backpack.is_equipped("old_book"), true, "装备 old_book")
	_check(GameState.backpack_equipped, "old_book", "装备状态同步进 GameState")
	Backpack.equip("old_book")
	_check(Backpack.is_equipped("old_book"), true, "重复装备无副作用")

	# --- 并入日记存档：写日记 → 清空内存 → 读日记，物品和装备应当回来 ---
	_check(GameState._write_diary(), true, "写日记存档")
	Backpack.items.clear()
	Backpack.equipped_id = ""
	Backpack.push_to_state()
	_check(GameState.read_diary(), true, "读日记存档")
	_check(Backpack.items.size(), 2, "读档后背包物品恢复")
	_check(Backpack.is_equipped("old_book"), true, "读档后装备恢复")

	# --- 新游戏：背包必须清空（本次修复的回归点）---
	GameState.new_game()
	_check(Backpack.items.is_empty(), true, "新游戏后背包清空")
	_check(Backpack.is_equipped("old_book"), false, "新游戏后装备清空")
	_check(GameState.backpack_items.is_empty(), true, "新游戏后 GameState 背包字段清空")

	# --- 逐层介绍（data/item_descriptions.json 覆盖 + 基础介绍回退）---
	Backpack.reload_item_descriptions()
	# 约定：每个新物品都必须在 JSON 里加一条（5 层 0~4，未定的层用相同占位话）。
	for item_id: String in Backpack.ITEMS:
		_check(Backpack.has_description_entry(item_id), true, "物品 %s 在逐层介绍 JSON 里有条目" % item_id)
	GameState.set_dream_layer(0)
	_check(Backpack.get_item_description("sleeping_pills"), "只是一瓶安眠药而已。", "现实层的药瓶介绍")
	GameState.set_dream_layer(1)
	_check(Backpack.get_item_description("sleeping_pills"), "安眠药，或许有用。", "第一层的药瓶介绍")
	GameState.set_dream_layer(2)
	_check(Backpack.get_item_description("sleeping_pills"), "有用，但是也没什么太大的用处。", "第二层的药瓶介绍")
	GameState.set_dream_layer(3)
	_check(
		Backpack.get_item_description("sleeping_pills"),
		"贴着'深梦'标签的小药瓶。在梦里的床上吞下它，就能坠入更深的梦境。",
		"第三层为占位介绍（与基础介绍相同）"
	)
	# --- 手枪（可用道具）---
	_check(bool(Backpack.get_item_info("pistol").get("usable", false)), true, "手枪是可用道具")
	_check(Backpack.add_item("pistol"), true, "手枪可以拾取")
	GameState.set_dream_layer(0)
	_check(Backpack.get_item_description("pistol"), "现实里绝对不能碰它。", "手枪现实层介绍")
	Backpack.remove_item("pistol")
	GameState.set_dream_layer(0)

	# --- UI 开关（BackpackUI 是自动加载的 CanvasLayer）---
	var ui: CanvasLayer = get_node_or_null("/root/BackpackUI") as CanvasLayer
	_check(ui != null, true, "BackpackUI 已自动加载")
	if ui == null:
		return
	ui._open()
	_check(ui.visible, true, "打开背包")
	_check(get_tree().paused, true, "打开时场景树暂停")
	# 打开状态下再收集，计数标签应通过信号自动刷新。
	Backpack.add_item("wordless_book")
	var counter: Label = ui.get_node("Window/GridPanel/CounterLabel") as Label
	_check(counter.text, "收集 1 / 16", "打开时收集会自动刷新计数")
	ui._close()
	_check(ui.visible, false, "关闭背包")
	_check(get_tree().paused, false, "关闭后场景树恢复")


func _check(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures.append("%s（实际 %s，期望 %s）" % [label, actual, expected])
