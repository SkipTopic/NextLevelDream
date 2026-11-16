## 梦层跃迁转场（Autoload CanvasLayer）：全屏马赛克。
##
## 只用于"梦层数发生变化"的跨层移动（睡觉入梦 / 捏脸醒来 / 跳崖 Kick / 手枪 / 麻醉剂下潜）；
## 同一层内的移动继续用 SceneFader 的淡入淡出。
##
## 流程（对应马赛克转场的表现）：
##   1. 截取当前画面 → 全屏 TextureRect 覆盖
##   2. 马赛克块逐渐变大，直到整屏打码（旧画面马赛克化）
##   3. 趁全屏马赛克时在后台切换场景
##   4. 截取新画面 → 马赛克块逐渐还原 → 露出新场景
## 动画期间暂停场景树；无头模式拿不到画面时自动退回 SceneFader 淡入淡出。
extends CanvasLayer

const MOSAIC_IN: float = 3.2      ## 旧画面马赛克化（块边长 1px → 60px 线性生长，全程可感知）
const MOSAIC_HOLD: float = 1.6    ## 全屏马赛克定格（期间在后台切换场景）
const SETTLE_FRAMES: int = 5      ## 场景切换后等新场景就绪的帧数
const MOSAIC_OUT: float = 3.2     ## 马赛克还原成新场景（块边长 60px → 1px）
## 三段合计约 8 秒。

@onready var _root: Control = $Root
@onready var _screen: TextureRect = $Root/Screen

var _mat: ShaderMaterial
## 转场互斥：上一次没跑完时忽略新的请求。
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 230
	visible = false
	_mat = _screen.material as ShaderMaterial


func is_busy() -> bool:
	return _busy


## 梦层跃迁转场：马赛克化 → 切场景 → 还原。landing 传给 GameState 由新场景的玩家应用。
func change_scene(path: String, landing: Vector2 = Vector2.INF) -> void:
	if _busy:
		push_warning("DreamTransition: 上一次跃迁还没结束，忽略 %s。" % path)
		return
	_busy = true
	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		# 无头模式等拿不到画面：退回普通淡入淡出，保证测试 / 服务器环境可用。
		await SceneFader.change_scene(path, 0.85, 1.05, landing)
		_busy = false
		return
	_busy = true

	# 1) 截取旧画面并铺满全屏。
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_screen.texture = tex
	_mat.set_shader_parameter("screen_tex", tex)
	_mat.set_shader_parameter("progress", 0.0)
	visible = true
	get_tree().paused = true
	GameState.pending_player_position = landing

	# 2) 旧画面马赛克化：块边长 1px → 60px 线性生长，全程均匀可感知。
	var tween_in := create_tween()
	tween_in.tween_method(_set_progress, 0.0, 1.0, MOSAIC_IN)
	await tween_in.finished

	# 3) 全屏马赛克定格一小会儿，期间在后台切换场景。
	var hold := create_tween()
	hold.tween_interval(MOSAIC_HOLD)
	await hold.finished
	get_tree().change_scene_to_file(path)

	# 3.5) 截新画面之前必须先把马赛克层自己藏起来——否则截到的是
	#      "马赛克的马赛克"，还原段就会一直是张糊死的图（正是"后半段消失"的根源）。
	visible = false
	for _i in SETTLE_FRAMES:
		await get_tree().process_frame

	# 4) 截取干净的新画面 → 重新盖上（此时是"新画面的全马赛克"，与旧画面的全马赛克无缝衔接）。
	var new_img: Image = get_viewport().get_texture().get_image()
	if new_img != null:
		var new_tex: ImageTexture = ImageTexture.create_from_image(new_img)
		_screen.texture = new_tex
		_mat.set_shader_parameter("screen_tex", new_tex)
	visible = true

	# 5) 解除暂停，马赛克还原成活的新场景：块边长 60px → 1px 线性收敛。
	get_tree().paused = false
	var tween_out := create_tween()
	tween_out.tween_method(_set_progress, 1.0, 0.0, MOSAIC_OUT)
	await tween_out.finished

	visible = false
	_busy = false


func _set_progress(value: float) -> void:
	_mat.set_shader_parameter("progress", value)
