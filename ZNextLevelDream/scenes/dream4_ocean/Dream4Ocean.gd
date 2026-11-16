## 第四层梦境·海洋：全都是水，是大海。
##
## 规则：没有装备"书籍保护套"时，在海水里每走 2 步（静止不动不算）
## 日记本就湿掉一页；页数归 0 → 玩家死亡（GameOver 结算层触发）。
## 损失页数时会在玩家周围生成"飘在海面上的书页"（无碰撞、随机漂动）。
## 玩家站在水里：大腿以下被水渐变吞没（water_submerge.gdshader 挂在精灵上）。
## 目前没有出口——离开方式还没设计（手枪可回第三层小屋床边）。
## Q 捏脸在第四层无效。
extends Node2D

const WORLD_SIZE: Vector2i = Vector2i(2880, 1620)
## 一步的距离（像素）；走满 2 步湿掉一页。
const STEP_DISTANCE: float = 48.0
const STEPS_PER_PAGE: int = 2
const WATER_SUBMERGE_SHADER: = preload("res://assets/shaders/water_submerge.gdshader")
const PAGE_TEX: = preload("res://assets/art/props/page.png")
## 海面上同时存在的书页上限（超过就回收最早的）。
const MAX_PAGES: int = 36

@onready var player: Player = $Player

## 累计的行走距离。
var _walked: float = 0.0
## 浸水 shader 的材质（逐帧更新图集区域）。
var _sub_mat: ShaderMaterial
## 飘着的书页（无碰撞，随机漂动）。
var _pages: Array[FloatingPage] = []
var _pages_root: Node2D


func _ready() -> void:
	GameState.set_dream_layer(4)
	GameEvents.scene_entered.emit(scene_file_path)
	GameState.record_position(scene_file_path, player.global_position)
	player.set_camera_limits(Vector2i.ZERO, WORLD_SIZE)
	_apply_water_submerge()
	_pages_root = Node2D.new()
	_pages_root.name = "Pages"
	add_child(_pages_root)
	# 书页画在玩家下层：插到背景之后。
	move_child(_pages_root, 1)


## 站在水里的沉浸效果：把浸水 shader 挂到玩家精灵上，
## 并跟随动画帧更新图集区域（帧的内坐标才能算准水面高度）。
func _apply_water_submerge() -> void:
	_sub_mat = ShaderMaterial.new()
	_sub_mat.shader = WATER_SUBMERGE_SHADER
	player.sprite.material = _sub_mat
	_update_frame_region()
	player.sprite.frame_changed.connect(_update_frame_region)


func _update_frame_region() -> void:
	if _sub_mat == null or player.sprite.sprite_frames == null:
		return
	var tex: Texture2D = player.sprite.sprite_frames.get_frame_texture(
			player.sprite.animation, player.sprite.frame)
	if tex is AtlasTexture:
		_sub_mat.set_shader_parameter("frame_region", (tex as AtlasTexture).region)


func _physics_process(delta: float) -> void:
	# 装备了书籍保护套：海水浸不动日记本。
	if Backpack.is_equipped("book_sleeve"):
		return
	if player.locked:
		return
	var moved: float = player.velocity.length() * delta
	if moved <= 0.0:
		return   # 静止不动不算
	_walked += moved
	if _walked >= STEP_DISTANCE * STEPS_PER_PAGE:
		_walked = 0.0
		if GameState.consume_page():
			player.say("海水浸湿了日记本的一页……")
			_spawn_page(player.global_position + Vector2(randf_range(-120.0, 120.0), randf_range(-60.0, 60.0)))


## 损失一页时：在损失位置附近生成 1 片书页（一页对一页），飘在海面上（无碰撞、随机漂动）。
func _spawn_page(origin: Vector2) -> void:
	var page: FloatingPage = FloatingPage.new()
	page.texture = PAGE_TEX
	page.position = origin
	_pages_root.add_child(page)
	_pages.append(page)
	while _pages.size() > MAX_PAGES:
		var oldest: FloatingPage = _pages.pop_front()
		oldest.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	# 第四层捏脸醒来失效：保留按键反馈，让玩家知道"深梦醒不过来"。
	if event.is_action_pressed("wake_up"):
		player.say("怎么捏，脸颊都没有知觉。这里醒不过来。")
		get_viewport().set_input_as_handled()
