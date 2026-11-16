## 转场时全黑屏幕上显示的"载入中"指示器：一圈缓慢旋转的弧光。
##
## 只负责画自己，不参与转场时序（时序在 SceneFader.gd 里）。
## 用法：SceneFader 在全黑阶段把它 show() 出来，淡入结束后 hide()。
class_name LoadingSpinner
extends Control

## 每秒转过的弧度（0.5 圈/秒，慢到不会让人眼晕）。
const SPIN_SPEED: float = TAU * 0.5
## 轨道圆的分段数，越大越圆滑。
const TRACK_POINTS: int = 48
## 高亮弧的分段数。
const ARC_POINTS: int = 20
## 高亮弧占整圈的比例。
const ARC_SPAN: float = TAU * 0.32
## 线宽（像素）。
const LINE_WIDTH: float = 7.0

## 底部暗轨道颜色。
@export var track_color: Color = Color(1.0, 1.0, 1.0, 0.10)
## 旋转高亮弧颜色。
@export var arc_color: Color = Color(1.0, 1.0, 1.0, 0.80)

var _angle: float = 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_angle = fmod(_angle + SPIN_SPEED * delta, TAU)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.36
	draw_arc(center, radius, 0.0, TAU, TRACK_POINTS, track_color, LINE_WIDTH, true)
	draw_arc(center, radius, _angle, _angle + ARC_SPAN, ARC_POINTS, arc_color, LINE_WIDTH, true)
