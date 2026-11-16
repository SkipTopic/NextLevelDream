## 撕书动画结算层（Autoload CanvasLayer）。
##
## 写日记成功（GameState.diary_written）时触发：
##   1. 截取当前整个画面当作"一页纸"
##   2. 中缝出现毛边裂缝 → 两半撕开 → 全黑（tear_page.gdshader，见手绘草图三格）
##   3. 全黑保持片刻 → 缓缓变亮，回到被暂停的游戏
## 动画期间暂停场景树（海水浸页等规则不会在动画里偷跑）。
extends CanvasLayer

const CRACK_DURATION: float = 0.35    ## 裂缝出现
const TEAR_DURATION: float = 1.1      ## 两半撕开直到全黑
const BLACK_HOLD: float = 0.35        ## 全黑保持
const BRIGHTEN_DURATION: float = 1.4  ## 缓缓变亮

@onready var _root: Control = $Root
@onready var _page: TextureRect = $Root/Page

var _shader: ShaderMaterial
## 0 = 待机；1 = 裂缝；2 = 撕开；3 = 全黑保持；4 = 变亮。
var _phase: int = 0
var _phase_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 240
	visible = false
	_shader = _page.material as ShaderMaterial
	GameState.diary_written.connect(_on_diary_written)


func _on_diary_written() -> void:
	if _phase != 0:
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		return   # 拿不到画面（无头模式等）就跳过动画，不影响存档本身。
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_page.texture = tex
	# 关键：撕书 shader 采样的是 page_tex 参数，必须把截图传进去。
	_shader.set_shader_parameter("page_tex", tex)
	_phase = 1
	_phase_time = 0.0
	_shader.set_shader_parameter("progress", 0.0)
	_root.modulate.a = 1.0
	visible = true
	get_tree().paused = true


func _process(delta: float) -> void:
	if _phase == 0:
		return
	_phase_time += delta
	match _phase:
		1:
			var k := clampf(_phase_time / CRACK_DURATION, 0.0, 1.0)
			_shader.set_shader_parameter("progress", 0.06 * k)
			if k >= 1.0:
				_phase = 2
				_phase_time = 0.0
		2:
			var k := clampf(_phase_time / TEAR_DURATION, 0.0, 1.0)
			# 撕开越来越快（平方缓动），最后吞进全黑。
			_shader.set_shader_parameter("progress", 0.06 + 0.94 * k * k)
			if k >= 1.0:
				_phase = 3
				_phase_time = 0.0
		3:
			if _phase_time >= BLACK_HOLD:
				_phase = 4
				_phase_time = 0.0
		4:
			var k := clampf(_phase_time / BRIGHTEN_DURATION, 0.0, 1.0)
			_root.modulate.a = 1.0 - k   # 缓缓变亮：暂停的世界重新浮现
			if k >= 1.0:
				_phase = 0
				visible = false
				get_tree().paused = false
