## 第三层梦境·草地：明亮的草地与大树。
##
## 进入第三层后玩家在草地上醒来，背后是一棵大树。
## 左端有一座带烟囱的小屋（→ 草原小屋内部，白床通向第四层）；
## 右端有一位钓鱼的人（互动获得"书籍保护套"）。
## Q 捏脸在第三层无效。
extends Node2D

const GRASS_HOUSE: = "res://scenes/dream3_grass_house/GrassHouse.tscn"
const WORLD_SIZE: Vector2i = Vector2i(2880, 1620)
const TREE_TEX: = preload("res://assets/art/props/tree.png")
const HOUSE_TEX: = preload("res://assets/art/props/house.png")
const FISHERMAN_TEX: = preload("res://assets/art/props/fisherman.png")
const TREE_SWAY_SHADER: = preload("res://assets/shaders/tree_sway.gdshader")
## 醒来点的位置与背后的大树位置（树在玩家"背后"，即面向反方向）。
const SPAWN: = Vector2(1440.0, 950.0)
const SPAWN_TREE: = Vector2(1440.0, 690.0)

## 风摆幅度（像素，树顶处最大）与速度倍率——编辑器里选中本节点可调。
@export var sway_strength: float = 12.0
@export var sway_speed: float = 1.0
## 进入小屋后的落点（白门/屋门前）。
const HOUSE_LANDING: = Vector2(960.0, 860.0)

## 散布的树：位置 + 是否带碰撞（占位布置，后续可随意改）。
const SCATTERED_TREES: Array = [
	[Vector2(500, 500), true],
	[Vector2(2200, 420), true],
	[Vector2(2600, 1200), true],
	[Vector2(400, 1300), true],
	[Vector2(1900, 550), false],
	[Vector2(950, 1450), false],
	[Vector2(2450, 800), false],
	[Vector2(650, 900), false],
]

@onready var player: Player = $Player
@onready var house: Interactable = $Props/House/Interactable
@onready var fisherman: Interactable = $Props/Fisherman/Interactable
@onready var fisherman_sprite: Sprite2D = $Props/Fisherman/Sprite2D


func _ready() -> void:
	GameState.set_dream_layer(3)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	house.interacted.connect(_on_house_entered)
	fisherman.interacted.connect(_on_fisherman_interacted)
	_refresh_fisherman()
	_spawn_trees()


func _refresh_fisherman() -> void:
	var collected: bool = Backpack.has_item("book_sleeve")
	fisherman_sprite.visible = not collected
	fisherman.enabled = not collected


func _unhandled_input(event: InputEvent) -> void:
	# 第三层捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()


func _on_house_entered(_source: Node2D) -> void:
	player.say("推开小屋的门，里面摆着一张白床。")
	player.lock()
	GameState.record_position(scene_file_path, player.global_position)
	SceneFader.loading_text = "走进小屋……"
	await SceneFader.change_scene(GRASS_HOUSE, 0.85, 1.05, HOUSE_LANDING)


func _on_fisherman_interacted(_source: Node2D) -> void:
	if Backpack.add_item("book_sleeve"):
		_refresh_fisherman()
		player.say("钓鱼人没说话，只是递给你一个防水书套。（按 B 装备）")
	else:
		player.say("钓鱼人还在钓着鱼。")


func _spawn_trees() -> void:
	var trees: Node2D = $Trees
	# 醒来点背后的大树（画在玩家下层，玩家从树前"醒来"）。
	_add_tree(trees, SPAWN_TREE, 1.7, true)
	for entry: Array in SCATTERED_TREES:
		_add_tree(trees, entry[0], 1.0, entry[1])


func _add_tree(parent: Node2D, pos: Vector2, tree_scale: float, solid: bool) -> void:
	var tree := Sprite2D.new()
	tree.texture = TREE_TEX
	tree.position = pos
	tree.scale = Vector2(tree_scale, tree_scale)
	# 风摆材质：每棵树一个独立相位（按位置生成），不会整片同步摆动。
	var mat := ShaderMaterial.new()
	mat.shader = TREE_SWAY_SHADER
	mat.set_shader_parameter("phase", pos.x * 0.013 + pos.y * 0.021)
	mat.set_shader_parameter("sway_strength", sway_strength * tree_scale)
	mat.set_shader_parameter("sway_speed", sway_speed * randf_range(0.85, 1.2))
	tree.material = mat
	parent.add_child(tree)
	if not solid:
		return
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(110.0, 120.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -110.0)
	body.add_child(shape)
	tree.add_child(body)
