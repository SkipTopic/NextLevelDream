## 飘在海面上的书页：无碰撞体，随机漂动 + 轻微起伏（第四层海洋浸页的表现）。
## 由 Dream4Ocean 在损失页数时生成，数量有上限、随场景一起释放。
class_name FloatingPage
extends Sprite2D

## 漂动速度（像素/秒）。
@export var drift_speed: float = 26.0

var _dir := Vector2.RIGHT
var _phase := 0.0


func _ready() -> void:
	_phase = randf() * TAU
	_dir = Vector2.from_angle(randf() * TAU)


func _process(delta: float) -> void:
	_phase += delta
	# 偶尔换个漂动方向。
	if randf() < delta * 0.6:
		_dir = Vector2.from_angle(randf() * TAU)
	position += _dir * drift_speed * delta
	# 随浪轻微起伏 + 慢慢打转。
	position.y += sin(_phase * 2.2) * 5.0 * delta
	rotation = sin(_phase * 1.4) * 0.22
