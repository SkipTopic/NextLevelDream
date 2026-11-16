## 梦层跃迁（马赛克转场）回归测试：按临时 Autoload 方式运行（见文件尾说明）。
##
## 运行方式：在 project.godot 的 [autoload] 里临时加一行
##   _MosaicTest="*res://tools/test_mosaic.gd"
## 然后 headless 运行游戏，看到 "TEST RESULT: PASS" 后删除该行。
## 必须挂成 Autoload：转场会释放当前场景，普通场景节点活不到断言那一步。
extends Node


func _ready() -> void:
	await get_tree().process_frame
	# 起点：现实卧室（第 0 层）。
	get_tree().change_scene_to_file("res://scenes/reality_bedroom/RealityBedroom.tscn")
	for _i in 10:
		await get_tree().process_frame

	var dt: Node = get_node("/root/DreamTransition")
	# 与真实流程一致：先切梦层再跃迁（现实卧室床上 0→1）。
	GameState.set_dream_layer(1)
	# 梦层跃迁（0→1）：马赛克转场。等待其完整结束再断言。
	await dt.change_scene("res://scenes/dream1_bedroom/Dream1Bedroom.tscn", Vector2(440.0, 780.0))

	var ok_scene: bool = get_tree().current_scene.scene_file_path == "res://scenes/dream1_bedroom/Dream1Bedroom.tscn"
	var ok_layer: bool = GameState.dream_layer == 1
	var player: Player = _find_player(get_tree().current_scene)
	var ok_pos: bool = player != null and player.global_position.distance_to(Vector2(440.0, 780.0)) < 2.0
	var ok_busy: bool = not dt.is_busy()

	print("MOSAIC scene=%s layer=%s pos=%s busy_clear=%s" % [ok_scene, ok_layer, ok_pos, ok_busy])
	print("TEST RESULT: %s" % [
		"PASS" if (ok_scene and ok_layer and ok_pos and ok_busy) else "FAIL",
	])
	get_tree().quit(0 if (ok_scene and ok_layer and ok_pos and ok_busy) else 1)


func _find_player(node: Node) -> Player:
	if node is Player:
		return node
	for child: Node in node.get_children():
		var found: Player = _find_player(child)
		if found != null:
			return found
	return null
