## 主角：8 方向移动 + 朝向动画 + 前置交互探针 + 提示/台词气泡。
##
## 设计要点：
##   1. 移动用 Input.get_vector + CharacterBody2D.move_and_slide；不直接处理网格吸附。
##   2. "面向方向"由最近一次输入方向决定，并驱动交互探针的位置（朝向探针）。
##   3. 交互物体由 InteractArea 重叠区计算最近的一个，提示文字实时刷新。
##   4. 锁定（locked）时禁用一切输入，但已被锁的对话框仍能继续播完。
##   5. sprite_frames 在 _ready 中由 sprite_sheet 程序化拼出，便于美术替换。
class_name Player
extends CharacterBody2D

const FRAME_SIZE: Vector2 = Vector2(120.0, 180.0)
const SHEET_COLUMNS: int = 3
const DIRECTION_ROWS: Dictionary = {"down": 0, "left": 1, "right": 2, "up": 3}
const ANIMATION_FPS: float = 6.0
const PROBE_FORWARD_DISTANCE: float = 96.0

## 行走速度（像素/秒）。梦境世界更大时保持相同节奏。
@export var walk_speed: float = 320.0
## 装备电瓶车后的移动速度（像素/秒）。
## 调节位置：编辑器里选中场景中的 Player 节点 → 检查器 → "Scooter Speed"。
@export var scooter_speed: float = 560.0
## 精灵表（4 行 x 3 列）。替换时保持每个格子 120x180 即可。
@export var sprite_sheet: Texture2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var hint_label: Label = $HintLabel
@onready var speech_label: Label = $SpeechLabel
@onready var speech_timer: Timer = $SpeechTimer
@onready var camera: Camera2D = $Camera2D

## 锁定后不能移动、不能交互；用于淡出淡出场景切换期间。
var locked: bool = false

var _facing: String = "down"
var _nearest: Interactable = null


func _ready() -> void:
	sprite.sprite_frames = _build_sprite_frames(sprite_sheet)
	sprite.animation = "down"
	sprite.frame = 0
	hint_label.text = ""
	speech_label.text = ""
	speech_timer.timeout.connect(_on_speech_timer_timeout)
	if GameState.pending_player_position != Vector2.INF:
		global_position = GameState.pending_player_position
		GameState.pending_player_position = Vector2.INF


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event.is_action_pressed("interact") and _nearest != null:
		_nearest.interact(self)
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	_update_interaction_probe()
	if locked:
		velocity = Vector2.ZERO
	else:
		var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * _effective_speed()
		if direction != Vector2.ZERO:
			_facing = _direction_to_name(direction)
	_update_animation()
	_refresh_hint()
	move_and_slide()


## 实际移动速度：装备了电瓶车就用 scooter_speed（编辑器可调），否则用 walk_speed。
func _effective_speed() -> float:
	if Backpack.is_equipped("scooter"):
		return scooter_speed
	return walk_speed


# --- 公共 API ------------------------------------------------------------

## 在切换场景前调用，避免淡出过程中玩家仍然可输入。
func lock() -> void:
	locked = true
	velocity = Vector2.ZERO
	hint_label.text = ""
	_nearest = null


func unlock() -> void:
	locked = false


## 设置跟随相机的限位边界（左上 / 右下，瓦片坐标）。
func set_camera_limits(top_left: Vector2i, bottom_right: Vector2i) -> void:
	camera.limit_left = top_left.x
	camera.limit_top = top_left.y
	camera.limit_right = bottom_right.x
	camera.limit_bottom = bottom_right.y


## 让玩家头顶浮出一段台词气泡，2.4 秒后自动隐藏。
func say(text: String) -> void:
	speech_label.text = text
	speech_timer.start(2.4)


# --- 内部 ---------------------------------------------------------------

func _update_interaction_probe() -> void:
	interaction_area.position = _facing_vector() * PROBE_FORWARD_DISTANCE
	var best: Interactable = null
	var best_distance: float = INF
	for area: Variant in interaction_area.get_overlapping_areas():
		var candidate: Area2D = area
		if not (candidate is Interactable):
			continue
		var interactable: Interactable = candidate
		if not interactable.enabled:
			continue
		var distance: float = global_position.distance_to(interactable.global_position)
		if distance < best_distance:
			best_distance = distance
			best = interactable
	_nearest = best


func _refresh_hint() -> void:
	if locked or _nearest == null:
		hint_label.text = ""
		return
	hint_label.text = _nearest.hint_text


func _update_animation() -> void:
	if velocity.length_squared() > 1.0:
		if sprite.animation != _facing or not sprite.is_playing():
			sprite.play(_facing)
	else:
		if sprite.is_playing():
			sprite.stop()
			sprite.frame = 0


func _direction_to_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"


func _facing_vector() -> Vector2:
	match _facing:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
	return Vector2.RIGHT


func _on_speech_timer_timeout() -> void:
	speech_label.text = ""


func _build_sprite_frames(sheet: Texture2D) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	for direction: String in DIRECTION_ROWS:
		frames.add_animation(direction)
		frames.set_animation_speed(direction, ANIMATION_FPS)
		frames.set_animation_loop(direction, true)
		var row: int = DIRECTION_ROWS[direction]
		for column in SHEET_COLUMNS:
			frames.add_frame(direction, _make_frame(sheet, column, row))
	return frames


func _make_frame(sheet: Texture2D, column: int, row: int) -> AtlasTexture:
	var frame: AtlasTexture = AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(Vector2(column * FRAME_SIZE.x, row * FRAME_SIZE.y), FRAME_SIZE)
	return frame
