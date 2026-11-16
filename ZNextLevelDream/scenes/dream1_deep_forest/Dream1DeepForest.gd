## 第一层梦境·深林：5760x1620（与轨道世界同宽），稀疏排布的大树。
##
## 树的排布：按"军队列阵"式行距错位分布——横向成排、隔行错位半个列距、
## 纵向分层，配合 Y 排序（y_sort_enabled）分清前后，减少树冠重叠。
## 全部树木带树干碰撞体；树冠用风摆 shader 摇摆（底部固定、顶部左右摆）。
##
## 导航：
##   - 底部传送门 → 回到一层·主通道
##   - Q → 捏脸醒来回现实（第一层专属）
extends Node2D

const DREAM1_NEXUS: = "res://scenes/dream1_nexus/Dream1Nexus.tscn"
const REALITY_BEDROOM: = "res://scenes/reality_bedroom/RealityBedroom.tscn"
const TREE_TEX: = preload("res://assets/art/props/tree.png")
const PORTAL_TEX: = preload("res://assets/art/props/portal.png")
const TREE_SWAY_SHADER: = preload("res://assets/shaders/tree_sway.gdshader")

const WORLD_SIZE: Vector2i = Vector2i(5760, 1620)
## 播种参数：行距 / 列距 / 抖动幅度 / 稀疏跳过概率 / 树与树的最小间距。
const ROW_SPACING: float = 300.0
const COL_SPACING: float = 430.0
const ROW_JITTER: float = 60.0
const COL_JITTER: float = 110.0
const SKIP_CHANCE: float = 0.25
const MIN_TREE_DISTANCE: float = 240.0
## 保持空旷的圆形区域：玩家出生点与传送门。
const CLEAR_ZONES: Array = [
	[Vector2(1440.0, 1100.0), 280.0],
	[Vector2(2880.0, 1480.0), 280.0],
]
## 林间小径的带宽（横径 y 730~990、纵径 x 2720~3040）——树下不能长在小径上。
const PATH_BAND_Y := Vector2(730.0, 990.0)
const PATH_BAND_X := Vector2(2720.0, 3040.0)

## 风摆幅度（像素，树顶处最大）与速度倍率——编辑器里选中本节点可调。
@export var sway_strength: float = 14.0
@export var sway_speed: float = 1.0

@onready var player: Player = $Player
@onready var portal: Interactable = $Props/Portal/Interactable
@onready var wake_up: WakeUpComponent = $WakeUp


func _ready() -> void:
	GameState.set_dream_layer(1)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	portal.interacted.connect(_on_portal)
	wake_up.wake_requested.connect(_on_wake_up)
	_spawn_trees()


## 按"军队列阵"式行距错位播种：横向成排、隔行错位半个列距、
## 纵向每 ROW_SPACING 一层；跳过空旷区 / 小径 / 过近的位置，保持稀疏不重叠。
func _spawn_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var trees: Node2D = $Trees
	var placed: Array[Vector2] = []
	var row := 0
	var y := 190.0
	while y < WORLD_SIZE.y - 190.0:
		var offset := (COL_SPACING * 0.5) if row % 2 == 1 else 0.0
		var x := 190.0 + offset
		while x < WORLD_SIZE.x - 190.0:
			var pos := Vector2(
				x + rng.randf_range(-COL_JITTER, COL_JITTER),
				y + rng.randf_range(-ROW_JITTER, ROW_JITTER))
			if not _in_clear_zone(pos) and not _on_path(pos) \
					and rng.randf() > SKIP_CHANCE and _far_enough(placed, pos):
				_add_tree(trees, pos, rng)
				placed.append(pos)
			x += COL_SPACING
		y += ROW_SPACING
		row += 1


func _in_clear_zone(pos: Vector2) -> bool:
	for zone: Array in CLEAR_ZONES:
		if pos.distance_to(zone[0]) < float(zone[1]):
			return true
	return false


## 树不要长在小径上（横径 + 纵径）。
func _on_path(pos: Vector2) -> bool:
	return (pos.y > PATH_BAND_Y.x and pos.y < PATH_BAND_Y.y) \
		or (pos.x > PATH_BAND_X.x and pos.x < PATH_BAND_X.y)


## 与已种下的树保持最小间距，减少树冠重叠。
func _far_enough(placed: Array[Vector2], pos: Vector2) -> bool:
	for p: Vector2 in placed:
		if p.distance_to(pos) < MIN_TREE_DISTANCE:
			return false
	return true


## 一棵树：精灵（挂风摆材质，独立相位）+ 树干碰撞体。
func _add_tree(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var tree := Node2D.new()
	tree.position = pos

	var sprite := Sprite2D.new()
	sprite.texture = TREE_TEX
	var s := rng.randf_range(0.9, 1.15)
	sprite.scale = Vector2(s, s)
	# 风摆材质：每棵树一个独立相位（按位置生成），不会整排同步摆动。
	var mat := ShaderMaterial.new()
	mat.shader = TREE_SWAY_SHADER
	mat.set_shader_parameter("phase", pos.x * 0.013 + pos.y * 0.021)
	mat.set_shader_parameter("sway_strength", sway_strength * s)
	mat.set_shader_parameter("sway_speed", sway_speed * rng.randf_range(0.85, 1.2))
	sprite.material = mat
	tree.add_child(sprite)

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(110.0, 120.0)
	shape.shape = rect
	shape.position = Vector2(0.0, 80.0)
	body.add_child(shape)
	tree.add_child(body)

	parent.add_child(tree)


func _on_portal(_source: Node2D) -> void:
	player.say("回到主通道。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "梦在流动……"
	await SceneFader.change_scene(DREAM1_NEXUS, 0.85, 1.05, Vector2(1440.0, 800.0))


func _on_wake_up() -> void:
	player.lock()
	# 捏脸醒来：落回现实里睡着的那张床边（锚点 0）。
	GameState.set_dream_layer(GameState.LAYER_REALITY)
	var target: String = REALITY_BEDROOM
	var landing: Vector2 = Vector2(440.0, 780.0)
	var anchor: Dictionary = GameState.bed_anchor(GameState.LAYER_REALITY)
	if not anchor.is_empty():
		target = anchor["scene"]
		landing = anchor["position"]
	GameState.record_position(target, landing)
	# 梦层跃迁（1→0）：马赛克转场。
	await DreamTransition.change_scene(target, landing)
