## 虚拟摇杆 + 右下角触屏按钮（Autoload CanvasLayer）——为安卓端准备的触屏输入。
##
## 摇杆行为：
##   - 固定在屏幕左下角；手指（桌面用鼠标）按住底座区域内拖动即输出方向，
##     松开归位；支持模拟量（离圆心越远移得越快），带死区。
##   - 通过 Input.action_press / action_release 直接驱动 move_left/right/up/down
##     四个动作，Player.gd 的 Input.get_vector 无需任何改动。
##
## 触屏按钮（屏幕右下角三键）：
##   - "交互"按钮 → 注入 interact 动作事件，走 Player._unhandled_input 既有逻辑；
##   - "捏脸"按钮 → 注入 wake_up 动作事件：第一层触发 WakeUpComponent 醒来，
##     第二层起由场景给出"醒不过来"反馈（与 Q 键完全同路径）；
##   - "背包"按钮 → 注入 backpack 动作事件，走 BackpackUI._unhandled_input 开关背包；
##   - 注入 InputEventAction 而不是直接调方法：行为与物理按键完全一致，零侵入。
##
## 输入细节：
##   - 触摸与鼠标都能用；开启"触摸模拟鼠标"时也不会重复响应
##     （指针捕获互斥 + 按钮"已按下则忽略"防抖：一指在摇杆上时另一指仍可点按钮）。
##
## 显示规则（需求约定，改这里要同步 overview.md）：
##   - 主菜单 / 介绍页：不显示；
##   - 场景切换动画（SceneFader 转场）期间：不显示；
##   - 背包界面（BackpackUI 打开、场景树暂停）期间：不显示；
##   其余游戏场景常驻。
extends CanvasLayer

## 仅触屏设备显示（安卓发布时可改为 true；开发期 false 方便鼠标调试）。
const SHOW_ONLY_ON_TOUCH := false

# --- 摇杆 ---
const BASE_RADIUS := 130.0
const KNOB_RADIUS := 58.0
## 命中判定比底座大一圈，手指好按。
const GRAB_RADIUS := BASE_RADIUS * 1.4
const MAX_KNOB_TRAVEL := BASE_RADIUS - KNOB_RADIUS - 10.0
const DEADZONE := 0.12
## 摇杆离屏幕左下角的边距（宽/高）。
const STICK_MARGIN := Vector2(60.0, 60.0)

# --- 触屏按钮（右下角三键：交互 / 捏脸 / 背包；
#     位置全部相对"视口右下角"计算，屏幕拉伸时依然贴右缘） ---
const BUTTON_INTERACT := "interact"
const BUTTON_WAKE := "wake_up"
const BUTTON_BACKPACK := "backpack"
const BUTTON_INTERACT_RADIUS := 76.0
const BUTTON_WAKE_RADIUS := 64.0
const BUTTON_BACKPACK_RADIUS := 58.0
## 各按钮中心到视口右下角的偏移（1920x1080 设计分辨率下的布局）。
const BUTTON_OFFSET_INTERACT := Vector2(385.0, 190.0)
const BUTTON_OFFSET_WAKE := Vector2(218.0, 208.0)
const BUTTON_OFFSET_BACKPACK := Vector2(182.0, 360.0)
## 按钮命中判定放宽一圈，手指好按。
const BUTTON_HIT_MARGIN := 16.0

## 未捕获任何指针。
const _NO_POINTER := -2
## 鼠标在捕获状态下的伪 index（真触摸 index >= 0）。
const _MOUSE_POINTER := -1

const _COLOR_FILL := Color(0.05, 0.02, 0.06, 0.45)
const _COLOR_RING := Color(0.72, 0.28, 0.52, 0.85)
const _COLOR_KNOB := Color(0.10, 0.05, 0.12, 0.85)
const _COLOR_KNOB_RING := Color(0.90, 0.52, 0.72, 0.95)
const _COLOR_TEXT := Color(0.93, 0.82, 0.88, 0.95)

## 三条显示规则的当前状态。
var _scene_allowed: bool = true
var _transitioning: bool = false
var _touch_available: bool = false
## 当前视口尺寸（拉伸模式下会变化）：摇杆/按钮位置都相对它计算。
var _viewport_size: Vector2 = Vector2(1920.0, 1080.0)

var _stick: Control
var _buttons_pad: Control
var _knob_offset := Vector2.ZERO
## 当前捕获的指针；_NO_POINTER 表示没有。
var _pointer_id: int = _NO_POINTER
## 按钮按下状态与占用指针（支持多指同时按不同按钮）。
var _button_pressed := {BUTTON_INTERACT: false, BUTTON_WAKE: false, BUTTON_BACKPACK: false}
var _button_owner := {BUTTON_INTERACT: _NO_POINTER, BUTTON_WAKE: _NO_POINTER, BUTTON_BACKPACK: _NO_POINTER}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	visible = false
	_touch_available = DisplayServer.is_touchscreen_available()
	_build_stick()
	_build_buttons()
	GameEvents.scene_entered.connect(_on_scene_entered)
	SceneFader.transition_started.connect(_on_transition_started)
	SceneFader.transition_finished.connect(_on_transition_finished)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	# 自动加载先于主场景就绪，延迟一帧再判断初始场景。
	call_deferred("_check_initial_scene")


func _process(_delta: float) -> void:
	var desired: bool = _scene_allowed and not _transitioning \
			and not BackpackUI.visible and _touch_allowed()
	if visible != desired:
		visible = desired
		if not visible:
			# 隐藏时必须全部松开，否则玩家会一直走 / 动作卡住。
			_reset_all()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if not (_pointer_id == _NO_POINTER and _try_joystick_capture(touch.index, touch.position)):
				_try_button_press(touch.index, touch.position)
		else:
			if _pointer_id == touch.index:
				_release()
			else:
				_button_release(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _pointer_id == drag.index:
			_update_drag(drag.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if not (_pointer_id == _NO_POINTER and _try_joystick_capture(_MOUSE_POINTER, mb.position)):
				_try_button_press(_MOUSE_POINTER, mb.position)
		else:
			if _pointer_id == _MOUSE_POINTER:
				_release()
			else:
				_button_release(_MOUSE_POINTER)
	elif event is InputEventMouseMotion:
		if _pointer_id == _MOUSE_POINTER \
				and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
			_update_drag((event as InputEventMouseMotion).position)


# --- 显示规则 ------------------------------------------------------------

func _on_scene_entered(scene_path: String) -> void:
	_scene_allowed = not (scene_path.contains("main_menu") or scene_path.contains("intro"))


func _on_transition_started() -> void:
	_transitioning = true
	# 转场一开始就松手，避免淡出时玩家还在走。
	_reset_all()


func _on_transition_finished() -> void:
	_transitioning = false


func _check_initial_scene() -> void:
	var current: Node = get_tree().current_scene
	if current != null and not current.scene_file_path.is_empty():
		_on_scene_entered(current.scene_file_path)


func _touch_allowed() -> bool:
	return not SHOW_ONLY_ON_TOUCH or _touch_available


# --- 摇杆逻辑 -------------------------------------------------------------

func _try_joystick_capture(id: int, position: Vector2) -> bool:
	# 已有指针在拖动摇杆时，忽略其他指针。
	if _pointer_id != _NO_POINTER:
		return false
	if position.distance_to(_stick_center()) > GRAB_RADIUS:
		return false
	_pointer_id = id
	_update_drag(position)
	return true


func _update_drag(position: Vector2) -> void:
	_knob_offset = (position - _stick_center()).limit_length(MAX_KNOB_TRAVEL)
	_apply_move_vector(_knob_offset / MAX_KNOB_TRAVEL)
	_stick.queue_redraw()


func _release() -> void:
	if _pointer_id == _NO_POINTER and _knob_offset == Vector2.ZERO:
		return
	_pointer_id = _NO_POINTER
	_knob_offset = Vector2.ZERO
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	_stick.queue_redraw()


## 摇杆偏移 → 四个移动动作的按键力度（Player 的 get_vector 直接消费）。
func _apply_move_vector(vec: Vector2) -> void:
	if vec.length() < DEADZONE:
		vec = Vector2.ZERO
	Input.action_press("move_left", clampf(-vec.x, 0.0, 1.0))
	Input.action_press("move_right", clampf(vec.x, 0.0, 1.0))
	Input.action_press("move_up", clampf(-vec.y, 0.0, 1.0))
	Input.action_press("move_down", clampf(vec.y, 0.0, 1.0))


# --- 触屏按钮逻辑 ----------------------------------------------------------

# --- 布局（全部相对视口边缘，拉伸时贴边） ---------------------------------

func _on_viewport_resized() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	if _stick == null:
		return
	_stick.position = _stick_center() - Vector2(BASE_RADIUS, BASE_RADIUS)


func _stick_center() -> Vector2:
	return Vector2(
		STICK_MARGIN.x + BASE_RADIUS,
		_viewport_size.y - STICK_MARGIN.y - BASE_RADIUS)


func _button_center(button: String) -> Vector2:
	var offset: Vector2
	match button:
		BUTTON_INTERACT:
			offset = BUTTON_OFFSET_INTERACT
		BUTTON_WAKE:
			offset = BUTTON_OFFSET_WAKE
		_:
			offset = BUTTON_OFFSET_BACKPACK
	return _viewport_size - offset


func _button_radius(button: String) -> float:
	match button:
		BUTTON_INTERACT:
			return BUTTON_INTERACT_RADIUS
		BUTTON_WAKE:
			return BUTTON_WAKE_RADIUS
	return BUTTON_BACKPACK_RADIUS


func _button_label(button: String) -> String:
	match button:
		BUTTON_INTERACT:
			return "交互"
		BUTTON_WAKE:
			return "捏脸"
	return "背包"


func _try_button_press(id: int, position: Vector2) -> void:
	for button: String in [BUTTON_INTERACT, BUTTON_WAKE, BUTTON_BACKPACK]:
		# "已按下则忽略"：真机上触摸还会合成一次鼠标事件，这里防二次触发。
		if _button_pressed[button]:
			continue
		if position.distance_to(_button_center(button)) > _button_radius(button) + BUTTON_HIT_MARGIN:
			continue
		_button_pressed[button] = true
		_button_owner[button] = id
		_fire_action(button, true)
		_buttons_pad.queue_redraw()
		return


func _button_release(id: int) -> void:
	for button: String in _button_pressed:
		if _button_pressed[button] and _button_owner[button] == id:
			_button_pressed[button] = false
			_button_owner[button] = _NO_POINTER
			_fire_action(button, false)
			_buttons_pad.queue_redraw()


## 注入动作事件：交互 / 背包都由各自的 _unhandled_input 既有逻辑消费。
func _fire_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


## 隐藏 / 转场时把摇杆与所有按钮全部松开。
func _reset_all() -> void:
	_release()
	for button: String in _button_pressed:
		if _button_pressed[button]:
			_button_pressed[button] = false
			_button_owner[button] = _NO_POINTER
			_fire_action(button, false)
	_buttons_pad.queue_redraw()


# --- 绘制 -----------------------------------------------------------------

func _build_stick() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_stick = Control.new()
	_stick.name = "Stick"
	_stick.position = _stick_center() - Vector2(BASE_RADIUS, BASE_RADIUS)
	_stick.size = Vector2(BASE_RADIUS, BASE_RADIUS) * 2.0
	_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick.draw.connect(_on_stick_draw)
	root.add_child(_stick)


func _build_buttons() -> void:
	var root := get_node("Root") as Control
	_buttons_pad = Control.new()
	_buttons_pad.name = "Buttons"
	_buttons_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_buttons_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buttons_pad.draw.connect(_on_buttons_draw)
	root.add_child(_buttons_pad)


func _on_stick_draw() -> void:
	var center := Vector2(BASE_RADIUS, BASE_RADIUS)
	_stick.draw_circle(center, BASE_RADIUS, _COLOR_FILL)
	_stick.draw_arc(center, BASE_RADIUS, 0.0, TAU, 96, _COLOR_RING, 6.0, true)
	# 四个方向的短刻度，提示这是摇杆。
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var inner := center + direction * (BASE_RADIUS - 26.0)
		var outer := center + direction * (BASE_RADIUS - 12.0)
		_stick.draw_line(inner, outer, _COLOR_RING, 4.0, true)
	var knob := center + _knob_offset
	_stick.draw_circle(knob, KNOB_RADIUS, _COLOR_KNOB)
	_stick.draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 64, _COLOR_KNOB_RING, 5.0, true)


func _on_buttons_draw() -> void:
	for button: String in [BUTTON_INTERACT, BUTTON_WAKE, BUTTON_BACKPACK]:
		_draw_button(_buttons_pad, _button_center(button), _button_radius(button),
				_button_label(button), _button_pressed[button])


func _draw_button(pad: Control, center: Vector2, radius: float, label: String, pressed: bool) -> void:
	var fill := Color(_COLOR_KNOB.r, _COLOR_KNOB.g, _COLOR_KNOB.b, 0.75 if pressed else 0.5)
	var ring := _COLOR_KNOB_RING if pressed else _COLOR_RING
	pad.draw_circle(center, radius, fill)
	pad.draw_arc(center, radius, 0.0, TAU, 64, ring, 6.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 34 if radius > 70.0 else 28
	pad.draw_string(font, Vector2(center.x - radius, center.y + font_size * 0.36), label,
			HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, _COLOR_TEXT)
