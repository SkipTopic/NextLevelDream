## 流星生成器：周期生成下落的流星 Sprite2D 并自动回收。
##
## 单纯视觉氛围，不与玩家发生物理碰撞（Phase 2 范围内）。
## 使用：
##   - 作为 Node2D 节点加入场景
##   - 设置 world_width / world_height 让生成范围匹配世界尺寸
class_name MeteorSpawner
extends Node2D

const METEOR_TEX: = preload("res://assets/art/props/meteor.png")

@export var world_width: float = 2880.0
@export var world_height: float = 1620.0
@export var spawn_interval_min: float = 0.18
@export var spawn_interval_max: float = 0.42
@export var speed_min: float = 550.0
@export var speed_max: float = 1100.0
@export var pre_spawn_count: int = 28

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_timer: float = 0.0
var _meteors: Array[Sprite2D] = []


func _ready() -> void:
	_rng.randomize()
	_spawn_timer = _rng.randf_range(0.1, 0.4)
	for _i in pre_spawn_count:
		_create_meteor(
			_rng.randf_range(0.0, world_width),
			_rng.randf_range(-300.0, world_height),
		)


func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _rng.randf_range(spawn_interval_min, spawn_interval_max)
		_create_meteor(
			_rng.randf_range(0.0, world_width),
			_rng.randf_range(-260.0, -60.0),
		)
	var to_remove: Array[Sprite2D] = []
	for m in _meteors:
		m.position.y += m.get_meta("vy") * delta
		m.position.x += m.get_meta("vx") * delta
		if m.position.y > world_height + 100.0:
			to_remove.append(m)
	for m in to_remove:
		m.queue_free()
		_meteors.erase(m)


func _create_meteor(x: float, y: float) -> void:
	var m: Sprite2D = Sprite2D.new()
	m.texture = METEOR_TEX
	m.position = Vector2(x, y)
	m.rotation = _rng.randf_range(-0.4, 0.4)
	var s: float = _rng.randf_range(0.8, 1.5)
	m.scale = Vector2(s, _rng.randf_range(0.8, 1.5))
	m.modulate = Color(1.0, 1.0, 1.0, _rng.randf_range(0.7, 1.0))
	# 流星从天上落下：画在玩家与场景道具之上，避免"穿到玩家后面"。
	m.z_index = 20
	m.set_meta("vy", _rng.randf_range(speed_min, speed_max))
	m.set_meta("vx", _rng.randf_range(-60.0, 60.0))
	add_child(m)
	_meteors.append(m)