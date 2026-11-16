## 轨道世界预览：加载第二层场景并截图，便于调布局 / 配色。
##
## 运行（会短暂弹出游戏窗口，截完图自动退出）：
##   Godot_v4.7.2-stable_win64_console.exe --path . res://tools/preview_rail_world.tscn
## 输出：tools/preview_rail_left.png（出生点，可见悬崖）、
##       tools/preview_rail_booth.png（保安室与床）。
extends Node

const RAIL_WORLD: = "res://scenes/dream2_rail_world/Dream2RailWorld.tscn"

@onready var _player: Player


func _ready() -> void:
	add_child((load(RAIL_WORLD) as PackedScene).instantiate())
	await get_tree().process_frame
	_player = _find_player(get_tree().current_scene if get_tree().current_scene != self else get_child(0))
	if _player == null:
		_player = _find_player(self)
	await _capture("res://tools/preview_rail_left.png")
	if _player != null:
		_player.global_position = Vector2(4900.0, 1150.0)
	await _capture("res://tools/preview_rail_booth.png")
	get_tree().quit(0)


func _capture(path: String) -> void:
	# 相机开了平滑跟随，传送后多等一会让它滑到位再拍。
	for _i in 70:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(path)
	print("已保存截图：%s" % path)


func _find_player(node: Node) -> Player:
	if node is Player:
		return node
	for child: Node in node.get_children():
		var found: Player = _find_player(child)
		if found != null:
			return found
	return null
