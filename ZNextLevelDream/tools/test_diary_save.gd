## 存档往返回归测试：验证"在哪写日记，读档就回到哪"。
##
## 这是手动回归测试，默认不运行。需要验证时：
##   1. 在 project.godot 的 [autoload] 里临时加一行：
##        _SaveTest="*res://tools/test_diary_save.gd"
##   2. 运行：Godot_v4.7.2-stable_win64_console.exe --headless --path .
##   3. 看到 "TEST RESULT: PASS" 后把那行 autoload 删掉，并确认
##      run/main_scene 仍为 res://scenes/main_menu/MainMenu.tscn。
##
## 必须挂成 Autoload 才能跑：脚本依赖 GameState / SceneFader 两个单例，
## 且用例会真实切换场景，普通场景节点在切场景时会被释放。
extends Node

## 每个用例：场景路径、目标坐标、切场景后允许的落地误差（像素）。
const CASES: Array = [
	["res://scenes/reality_bedroom/RealityBedroom.tscn", Vector2(960.0, 700.0), 2.0],
	["res://scenes/dream1_bedroom/Dream1Bedroom.tscn", Vector2(960.0, 700.0), 2.0],
	["res://scenes/dream1_nexus/Dream1Nexus.tscn", Vector2(1600.0, 380.0), 2.0],
	["res://scenes/dream1_meteor_world/Dream1MeteorWorld.tscn", Vector2(700.0, 600.0), 2.0],
	["res://scenes/dream1_deep_forest/Dream1DeepForest.tscn", Vector2(1500.0, 1150.0), 60.0],
	["res://scenes/dream2_rail_world/Dream2RailWorld.tscn", Vector2(2400.0, 1150.0), 2.0],
	["res://scenes/dream2_rail_world/SecurityRoom.tscn", Vector2(960.0, 700.0), 2.0],
	["res://scenes/dream2_street/Street.tscn", Vector2(1200.0, 1150.0), 2.0],
	["res://scenes/dream2_hospital_outside/HospitalOutside.tscn", Vector2(960.0, 800.0), 2.0],
	["res://scenes/dream2_hospital_inside/HospitalInside.tscn", Vector2(1440.0, 900.0), 40.0],
	["res://scenes/dream3_grass_world/Dream3GrassWorld.tscn", Vector2(1600.0, 900.0), 2.0],
	["res://scenes/dream3_grass_house/GrassHouse.tscn", Vector2(960.0, 800.0), 2.0],
	["res://scenes/dream4_ocean/Dream4Ocean.tscn", Vector2(1600.0, 900.0), 2.0],
]


func _ready() -> void:
	await get_tree().process_frame
	await _run_all()


func _run_all() -> void:
	var failed: int = 0
	for entry: Array in CASES:
		var scene_path: String = entry[0]
		var target: Vector2 = entry[1]
		var tolerance: float = entry[2]
		if not await _run_case(scene_path, target, tolerance):
			failed += 1
	print("TEST RESULT: %s（%d/%d 通过）" % [
		"PASS" if failed == 0 else "FAIL", CASES.size() - failed, CASES.size(),
	])
	get_tree().quit(0 if failed == 0 else 1)


func _run_case(scene_path: String, target: Vector2, tolerance: float) -> bool:
	var short_name: String = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Player = _find_player(get_tree().current_scene)
	if player == null:
		print("TEST [%s] FAIL: 场景里找不到 Player" % short_name)
		return false
	var entry_position: Vector2 = player.global_position

	# 走到目标点并等物理稳定，取稳定后的实时坐标作为期望值。
	player.global_position = target
	await get_tree().physics_frame
	await get_tree().physics_frame
	var expected: Vector2 = player.global_position

	if not GameState.save_diary():
		print("TEST [%s] FAIL: 存档写入失败" % short_name)
		return false
	var saved_scene: String = GameState.current_scene_path
	var saved_position: Vector2 = GameState.player_position

	# 模拟"读日记"：清空内存状态后从磁盘还原。
	GameState.current_scene_path = ""
	GameState.player_position = Vector2.ZERO
	if not GameState.read_diary():
		print("TEST [%s] FAIL: 读档失败" % short_name)
		return false

	var scene_ok: bool = GameState.current_scene_path == saved_scene
	var position_ok: bool = GameState.player_position.distance_to(expected) < 1.0

	# 真正切过去，看玩家落地位置。
	await SceneFader.change_scene(saved_scene, 0.02, 0.02, GameState.pending_player_position)
	var landed: Player = _find_player(get_tree().current_scene)
	if landed == null:
		print("TEST [%s] FAIL: 读档后场景里找不到 Player" % short_name)
		return false
	await get_tree().physics_frame
	var landed_error: float = landed.global_position.distance_to(expected)
	var landed_ok: bool = landed_error <= tolerance

	var passed: bool = scene_ok and position_ok and landed_ok
	print("TEST [%s] %s | 进入点%s → 写日记于%s → 读档落回%s（误差 %.1fpx，场景%s）" % [
		short_name, "PASS" if passed else "FAIL", entry_position, expected,
		landed.global_position, landed_error, "一致" if scene_ok else "不一致",
	])
	return passed


func _find_player(node: Node) -> Player:
	if node is Player:
		return node as Player
	for child: Node in node.get_children():
		var result: Player = _find_player(child)
		if result != null:
			return result
	return null
