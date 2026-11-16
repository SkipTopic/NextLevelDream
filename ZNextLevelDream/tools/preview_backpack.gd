## 背包界面预览：在真实卧室场景上打开背包并截图，便于调布局 / 配色。
##
## 运行（会短暂弹出游戏窗口，截完两张图后自动退出）：
##   Godot_v4.7.2-stable_win64_console.exe --path . res://tools/preview_backpack.tscn
## 输出：tools/preview_empty.png（空背包）、tools/preview_items.png（3 件物品 + 已装备）。
## 截图前会快照背包数据，结束时原样恢复，不污染真实存档。
extends Node

const BEDROOM: = "res://scenes/reality_bedroom/RealityBedroom.tscn"

var _snapshot_items: Array[String] = []
var _snapshot_equipped: String = ""


func _ready() -> void:
	add_child((load(BEDROOM) as PackedScene).instantiate())
	_snapshot_items = Backpack.items.duplicate()
	_snapshot_equipped = Backpack.equipped_id
	var ui: CanvasLayer = get_node("/root/BackpackUI")
	await get_tree().process_frame
	ui._open()
	await _capture("res://tools/preview_empty.png")
	Backpack.add_item("old_book")
	Backpack.add_item("old_lamp")
	Backpack.add_item("wordless_book")
	Backpack.equip("wordless_book")
	# 选中第三格（无字之书），模拟玩家点选后的详情展示。
	ui._selected_index = 2
	ui._refresh_all()
	await _capture("res://tools/preview_items.png")
	Backpack.items = _snapshot_items
	Backpack.equipped_id = _snapshot_equipped
	Backpack.push_to_state()
	get_tree().quit(0)


func _capture(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(path)
	print("已保存截图：%s" % path)
