## 随机走动的 NPC（医院大厅等场景用）。
##
## 行为：每隔一小段时间随机换方向（偶尔停下），撞到东西就换个方向继续走。
## 没有任何交互与剧情效果——纯氛围；collision_layer = 1（world），
## 玩家会被它挡住（有碰撞），它自己也会撞墙/互相避让。
class_name WanderingNPC
extends CharacterBody2D

## 移动速度（像素/秒）。
@export var move_speed: float = 70.0
## 换方向的基准间隔（秒）；每次实际间隔在 0.6~1.6 倍之间随机。
@export var change_interval: float = 2.0

var _direction := Vector2.ZERO
var _timer := 0.0


func _ready() -> void:
	_timer = randf_range(0.4, change_interval)


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(0.6, 1.6) * change_interval
		if randf() < 0.35:
			_direction = Vector2.ZERO   # 偶尔停下来发呆
		else:
			_direction = Vector2.from_angle(randf() * TAU)
	velocity = _direction * move_speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		# 撞墙 / 撞人：换一个方向，避免顶着不动。
		_direction = Vector2.from_angle(randf() * TAU)
		_timer = randf_range(0.4, 1.0)
