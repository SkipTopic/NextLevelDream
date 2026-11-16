## 梦层与床锚点回归测试：梦层切换、锚点记录、存档往返、旧档兼容、新游戏归零。
##
## 运行（无需改 project.godot，直接跑本场景）：
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tools/test_dream_layers.tscn
## 看到 "TEST RESULT: PASS" 即通过。
## 测试会真实写一次日记存档来验证梦层随之落盘，但结束前会按字节还原。
extends Node

var _failures: Array[String] = []
var _snap_scene_path: String
var _snap_player_pos: Vector2
var _snap_pending: Vector2
var _snap_dreaming: bool
var _snap_dream_layer: int
var _snap_dream_count: int
var _snap_pages: int
var _snap_backpack_items: Array[String]
var _snap_backpack_equipped: String
var _snap_bed_anchors: Dictionary
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
	_snap_scene_path = GameState.current_scene_path
	_snap_player_pos = GameState.player_position
	_snap_pending = GameState.pending_player_position
	_snap_dreaming = GameState.is_dreaming
	_snap_dream_layer = GameState.dream_layer
	_snap_dream_count = GameState.dream_count
	_snap_pages = GameState.diary_pages
	_snap_backpack_items = Backpack.items.duplicate()
	_snap_backpack_equipped = Backpack.equipped_id
	_snap_bed_anchors = GameState.bed_anchors.duplicate()
	_had_diary_file = FileAccess.file_exists(GameState.SAVE_PATH)
	if _had_diary_file:
		_snap_diary_file = FileAccess.get_file_as_string(GameState.SAVE_PATH)


func _restore_snapshot() -> void:
	GameState.current_scene_path = _snap_scene_path
	GameState.player_position = _snap_player_pos
	GameState.pending_player_position = _snap_pending
	GameState.is_dreaming = _snap_dreaming
	GameState.dream_layer = _snap_dream_layer
	GameState.dream_count = _snap_dream_count
	GameState.diary_pages = _snap_pages
	GameState.bed_anchors = _snap_bed_anchors
	Backpack.items = _snap_backpack_items
	Backpack.equipped_id = _snap_backpack_equipped
	if _had_diary_file:
		var file: FileAccess = FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		file.store_string(_snap_diary_file)
		file.close()
	else:
		DirAccess.remove_absolute(GameState.SAVE_PATH)


func _run_checks() -> void:
	# --- 梦层切换与 is_dreaming 联动 ---
	GameState.set_dream_layer(0)
	_check(GameState.is_dreaming, false, "第 0 层 = 现实（is_dreaming=false）")
	GameState.set_dream_layer(2)
	_check(GameState.is_dreaming, true, "第 2 层 = 梦中（is_dreaming=true）")
	_check(GameState.dream_layer, 2, "梦层记录为 2")

	# --- 床锚点：记录与读取 ---
	GameState.bed_anchors.clear()
	GameState.record_bed_anchor(1, "res://scenes/dream1_bedroom/Dream1Bedroom.tscn", Vector2(440.0, 780.0))
	GameState.record_bed_anchor(0, "res://scenes/reality_bedroom/RealityBedroom.tscn", Vector2(500.0, 800.0))
	var anchor1: Dictionary = GameState.bed_anchor(1)
	_check(anchor1.get("scene", ""), "res://scenes/dream1_bedroom/Dream1Bedroom.tscn", "锚点 1 的场景")
	_check(anchor1.get("position", Vector2.ZERO), Vector2(440.0, 780.0), "锚点 1 的坐标")
	_check(GameState.bed_anchor(3).is_empty(), true, "未记录的层返回空锚点")

	# --- 存档往返：写日记 → 破坏内存状态 → 读日记，梦层与锚点应当回来 ---
	_check(GameState._write_diary(), true, "写日记存档（v4）")
	GameState.set_dream_layer(4)
	GameState.bed_anchors.clear()
	_check(GameState.read_diary(), true, "读日记存档")
	_check(GameState.dream_layer, 2, "读档后梦层恢复")
	_check(GameState.bed_anchors.size(), 2, "读档后锚点恢复")
	_check(GameState.bed_anchor(0).get("position", Vector2.ZERO), Vector2(500.0, 800.0), "读档后锚点 0 坐标")

	# --- 旧档兼容：v3 没有梦层/锚点字段，按 is_dreaming 推断 ---
	var file: FileAccess = FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"version": 3,
		"is_dreaming": true,
		"scene_path": "res://scenes/dream1_nexus/Dream1Nexus.tscn",
		"player_x": 100.0,
		"player_y": 200.0,
		"dream_count": 3,
		"diary_pages": 9,
	}))
	file.close()
	_check(GameState.read_diary(), true, "读取 v3 旧档")
	_check(GameState.dream_layer, 1, "v3 旧档按 is_dreaming 推断为第 1 层")
	_check(GameState.bed_anchors.is_empty(), true, "v3 旧档没有锚点")

	# --- 新游戏：梦层与锚点全部归零（本次修复的回归点）---
	GameState.set_dream_layer(3)
	GameState.record_bed_anchor(2, "res://scenes/dream2_rail_world/Dream2RailWorld.tscn", Vector2(5400.0, 980.0))
	GameState.new_game()
	_check(GameState.dream_layer, 0, "新游戏后梦层归 0")
	_check(GameState.is_dreaming, false, "新游戏后 is_dreaming=false")
	_check(GameState.bed_anchors.is_empty(), true, "新游戏后锚点清空")


func _check(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures.append("%s（实际 %s，期望 %s）" % [label, actual, expected])
