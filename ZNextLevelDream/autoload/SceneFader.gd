## 全屏淡入淡出 + 场景切换（Autoload）。
##
## 转场是三段式的，节奏刻意做得"慢"，让每一次切换都有沉入/浮出梦境的仪式感：
##
##   1. 淡出（fade_out）     画面用 SINE + EASE_IN_OUT 慢慢变黑，越到后段越沉
##   2. 全黑保持（hold）     屏幕全黑，中央显示载入指示器 + 文案；
##                           场景加载就发生在这段，至少保持 MIN_BLACK_HOLD 秒，
##                           避免"一闪而过"让人看不清发生了什么
##   3. 淡入（fade_in）      新场景从全黑里慢慢浮现；指示器跟着黑幕一起淡出
##
## 职责边界：只负责"黑幕过渡"与场景切换；不持有场景节点引用，不参与玩法。
## 生命周期：常驻；layer=128 覆盖所有游戏 UI，初始完全透明。
##
## 用法：
##   SceneFader.loading_text = "沉入梦中……"        # 可选，不设就用默认文案
##   await SceneFader.change_scene(path, out, in, landing, hold)
extends CanvasLayer

## 默认淡出时长（秒）—— 慢慢变黑。
const DEFAULT_FADE_OUT: float = 0.85
## 默认淡入时长（秒）—— 比淡出略长，"浮出梦境"更从容。
const DEFAULT_FADE_IN: float = 1.05
## 全黑至少保持多久（秒）—— 保证载入指示器能被看见。
const MIN_BLACK_HOLD: float = 0.60
## 切完场景后等几帧再淡入，避免看到未初始化完的画面。
const SETTLE_FRAMES: int = 3

const LoadingSpinnerScript: GDScript = preload("res://scripts/LoadingSpinner.gd")

signal transition_started
## 屏幕已经全黑（此时正在加载新场景）。
signal black_screen_reached
signal transition_finished

## 全黑时中央显示的文案；各场景可在调用 change_scene 前改掉它。
var loading_text: String = "梦在流动……"

var _rect: ColorRect
var _spinner: LoadingSpinner
var _label: Label
## 转场互斥锁：上一次转场没跑完时，新的 change_scene 请求直接丢弃。
var _transitioning: bool = false


func _ready() -> void:
	layer = 128

	_rect = ColorRect.new()
	_rect.name = "FadeRect"
	_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 直接给 viewport 尺寸而不是依赖 PRESET_FULL_RECT：
	# Control 挂在 CanvasLayer 下面时，PRESET_FULL_RECT 不一定立刻生效，
	# 会让 FadeRect 变成 0x0、根本不覆盖屏幕。
	_rect.size = get_viewport().get_visible_rect().size
	_rect.position = Vector2.ZERO
	add_child(_rect)
	_rect.modulate.a = 0.0

	# 载入指示器挂在 FadeRect 下面：父级的 modulate 会传给子节点，
	# 所以它会自动跟着黑幕一起淡入淡出，不需要额外做动画。
	_build_loading_ui()


func _build_loading_ui() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "LoadingUI"
	# 在父节点（FadeRect）坐标系内居中；用锚点 + 偏移表达"屏幕中心 ± 尺寸/2"。
	column.anchor_left = 0.5
	column.anchor_top = 0.5
	column.anchor_right = 0.5
	column.anchor_bottom = 0.5
	column.offset_left = -180.0
	column.offset_top = -110.0
	column.offset_right = 180.0
	column.offset_bottom = 110.0
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 26)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.add_child(column)

	_spinner = LoadingSpinnerScript.new() as LoadingSpinner
	_spinner.name = "Spinner"
	_spinner.custom_minimum_size = Vector2(96.0, 96.0)
	_spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_spinner)

	_label = Label.new()
	_label.name = "LoadingLabel"
	_label.text = loading_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_label)

	column.visible = false
	# 让 _rect 的尺寸在视口变化时同步增长——保险起见。
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	if _rect == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_rect.size = viewport_size
	_rect.position = Vector2.ZERO


# --- 公开 API ------------------------------------------------------------

## 当前是否正在转场中；场景脚本可用它来屏蔽重复触发。
func is_transitioning() -> bool:
	return _transitioning

## 当前黑幕的不透明度（0 = 完全透明，1 = 全黑）。调试与自动化截图时用。
func get_fade_alpha() -> float:
	if _rect == null:
		return 0.0
	return _rect.modulate.a


## 慢慢把画面变黑（SINE + EASE_IN_OUT，两头都柔）。
func fade_out(duration: float = DEFAULT_FADE_OUT) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_rect.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


## 从全黑慢慢把画面显回来（SINE + EASE_IN_OUT）。
func fade_in(duration: float = DEFAULT_FADE_IN) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	# 黑幕已经透明，此时才彻底收掉指示器与输入拦截。
	_set_loading_visible(false)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 三段式转场：淡出 → 全黑保持（期间切场景） → 淡入。
## hold 是全黑至少持续的秒数；场景加载如果更慢，就以实际加载时间为准。
## 调用前可以先写 GameState.pending_player_position / SceneFader.loading_text。
func change_scene(path: String, out_duration: float = DEFAULT_FADE_OUT,
		in_duration: float = DEFAULT_FADE_IN, landing: Vector2 = Vector2.INF,
		hold: float = MIN_BLACK_HOLD) -> void:
	if _transitioning:
		push_warning("SceneFader: 上一次转场还没结束，已忽略切换到 %s 的请求。" % path)
		return
	_transitioning = true
	transition_started.emit()
	GameState.pending_player_position = landing

	# --- 第 1 段：慢慢变黑 ---
	await fade_out(out_duration)

	# --- 第 2 段：全黑保持，期间完成加载 ---
	_label.text = loading_text
	_set_loading_visible(true)
	black_screen_reached.emit()

	# 提前开一个计时器，用来保证"全黑"至少停留 hold 秒。
	var hold_timer: SceneTreeTimer = get_tree().create_timer(hold)
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneFader: 场景切换失败 %s" % path)
		if hold_timer.time_left > 0.0:
			await hold_timer.timeout
		_set_loading_visible(false)
		await fade_in(in_duration)
		_transitioning = false
		transition_finished.emit()
		return

	# 给新场景几帧时间把 _ready、物理、相机限位都跑完再显形。
	for _i in SETTLE_FRAMES:
		await get_tree().process_frame
	await get_tree().physics_frame

	# 如果加载比 hold 还快，就补等到 hold 结束，让黑屏有存在感。
	if hold_timer.time_left > 0.0:
		await hold_timer.timeout

	# --- 第 3 段：新场景慢慢浮现 ---
	# 指示器先留着，它会跟着 _rect 的 modulate 一起淡出。
	await fade_in(in_duration)
	loading_text = "梦在流动……"
	_transitioning = false
	transition_finished.emit()


# --- 内部 ---------------------------------------------------------------

func _set_loading_visible(value: bool) -> void:
	var column: Control = _rect.get_node_or_null("LoadingUI") as Control
	if column == null:
		return
	column.visible = value
