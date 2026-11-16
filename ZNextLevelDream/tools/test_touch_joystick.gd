## 触屏输入回归测试：摇杆驱动玩家、松手归零、右下角按钮触发交互/背包、
## 多指同时操作（按住摇杆时点按钮）、三条隐藏规则。
##
## 运行（无需改 project.godot，直接跑本场景）：
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tools/test_touch_joystick.tscn
## 看到 "TEST RESULT: PASS" 即通过。非 headless 运行时会顺带截图到 tools/preview_touch.png。
extends Node

var _failures: Array[String] = []


func _ready() -> void:
	# 背包开合会暂停场景树，测试节点必须保持运转。
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 用第二层的保安室做测试世界：办公桌可触发交互，捏脸按钮有"醒不过来"反馈。
	var world: Node = (load("res://scenes/dream2_rail_world/SecurityRoom.tscn") as PackedScene).instantiate()
	# 测试节点自己是 ALWAYS，世界必须显式回到 PAUSABLE，暂停行为才与真实游戏一致。
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	await _frames(2)
	var joystick: CanvasLayer = get_node("/root/TouchJoystick") as CanvasLayer
	var player: Player = _find_player(self)
	var snap_items: Array[String] = Backpack.items.duplicate()

	# --- 显示规则 0：普通游戏场景应显示 ---
	_check(joystick.visible, true, "普通场景显示摇杆")

	# --- 摇杆驱动玩家 ---
	player.global_position = Vector2(1100.0, 860.0)
	var start: Vector2 = player.global_position
	_touch(7, Vector2(190.0, 890.0), true)
	_drag(7, Vector2(120.0, 840.0))   # 向左上拖
	await _physics_frames(10)
	var moved: Vector2 = player.global_position - start
	_check(moved.x < -10.0, true, "摇杆向左拖 → 玩家向左移动")
	_check(moved.y < -10.0, true, "摇杆向上拖 → 玩家向上移动")
	_touch(7, Vector2(120.0, 840.0), false)
	await _physics_frames(5)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_check(direction, Vector2.ZERO, "松开后移动输入归零")

	# --- 交互按钮：站到办公桌前按下 → 真实触发交互（台词气泡出现）---
	player.global_position = Vector2(1560.0, 800.0)
	player._facing = "up"
	await _physics_frames(3)
	_touch(8, TouchJoystick.BUTTON_INTERACT_CENTER, true)
	await _frames(3)
	_check(Input.is_action_pressed("interact"), true, "按住交互按钮 → interact 动作按下")
	_check(player.speech_label.text != "", true, "交互按钮触发办公桌交互（出现台词）")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		(get_viewport().get_texture().get_image() as Image).save_png("res://tools/preview_touch.png")
	_touch(8, TouchJoystick.BUTTON_INTERACT_CENTER, false)
	await _frames(2)
	_check(Input.is_action_pressed("interact"), false, "松开交互按钮 → interact 动作释放")

	# --- 捏脸按钮：在第二层场景里按下 → 与 Q 同路径的"醒不过来"反馈 ---
	player.say("")
	_touch(8, TouchJoystick.BUTTON_WAKE_CENTER, true)
	await _frames(3)
	_check(player.speech_label.text.contains("醒不过来"), true, "捏脸按钮在第二层给出失效反馈")
	_touch(8, TouchJoystick.BUTTON_WAKE_CENTER, false)
	await _frames(2)

	# --- 多指：按住摇杆移动中，另一指点背包按钮 → 背包打开 ---
	_touch(7, Vector2(190.0, 890.0), true)
	_drag(7, Vector2(130.0, 870.0))
	await _physics_frames(5)
	var x_before: float = player.global_position.x
	await _physics_frames(6)
	_check(player.global_position.x < x_before - 10.0, true, "按住摇杆期间持续向左移动")
	_touch(8, TouchJoystick.BUTTON_BACKPACK_CENTER, true)
	await _frames(3)
	_check(BackpackUI.visible, true, "按住摇杆时点背包按钮 → 背包打开")
	_check(joystick.visible, false, "背包打开时触屏控件整体隐藏")
	_touch(8, TouchJoystick.BUTTON_BACKPACK_CENTER, false)
	BackpackUI._close()
	_touch(7, Vector2(130.0, 870.0), false)
	await _frames(3)
	_check(joystick.visible, true, "关闭背包后触屏控件恢复")
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_check(direction, Vector2.ZERO, "收尾后移动输入归零")

	# --- 显示规则：转场期间隐藏 ---
	SceneFader.transition_started.emit()
	await _frames(2)
	_check(joystick.visible, false, "转场期间触屏控件隐藏")
	SceneFader.transition_finished.emit()
	await _frames(2)
	_check(joystick.visible, true, "转场结束后恢复")

	# --- 显示规则：主菜单场景不显示 ---
	GameEvents.scene_entered.emit("res://scenes/main_menu/MainMenu.tscn")
	await _frames(2)
	_check(joystick.visible, false, "主菜单场景触屏控件隐藏")
	GameEvents.scene_entered.emit("res://scenes/reality_bedroom/RealityBedroom.tscn")
	await _frames(2)
	_check(joystick.visible, true, "回到游戏场景恢复")

	# 恢复测试前的背包状态（测试中可能收集了物品）。
	Backpack.items = snap_items
	Backpack.push_to_state()

	print("TEST RESULT: %s" % ["PASS" if _failures.is_empty() else "FAIL"])
	for failure in _failures:
		print("  - " + failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _touch(pointer: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = pointer
	event.position = position
	event.pressed = pressed
	# 直接以视口坐标注入（parse_input_event 会被窗口拉伸变换再映射一次）。
	get_tree().root.push_input(event, true)


func _drag(pointer: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = pointer
	event.position = position
	get_tree().root.push_input(event, true)


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _physics_frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func _find_player(node: Node) -> Player:
	if node is Player:
		return node
	for child: Node in node.get_children():
		var found: Player = _find_player(child)
		if found != null:
			return found
	return null


func _check(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures.append("%s（实际 %s，期望 %s）" % [label, actual, expected])
