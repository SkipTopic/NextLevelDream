## 全屏 HUD（Autoload CanvasLayer）。
##
## 职责：
##   - 显示剩余日记页数（右上）
##   - 显示"写日记"按钮（右下），点击或在游戏场景按 Y 键存档
##   - 在主菜单 / 介绍页时自动隐藏
extends CanvasLayer

@onready var pages_label: Label = $Root/TopBar/PagesLabel
@onready var save_button: Button = $Root/BottomRight/SaveButton
@onready var feedback_timer: Timer = $FeedbackTimer

var _feedback: String = ""


func _ready() -> void:
	layer = 100
	save_button.pressed.connect(_on_save_pressed)
	GameState.diary_changed.connect(_on_diary_changed)
	GameEvents.scene_entered.connect(_on_scene_entered)
	feedback_timer.timeout.connect(_reset_button)
	_refresh_visibility(GameState.current_scene_path)
	_on_diary_changed(GameState.diary_pages)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("save_diary"):
		_try_save()
		get_viewport().set_input_as_handled()


func _on_save_pressed() -> void:
	_try_save()


func _try_save() -> void:
	if save_button.disabled:
		_show_feedback("已经没有空白页了。")
		return
	if GameState.save_diary():
		_show_feedback("✓ 记下 %s (%d, %d)" % [
			_world_name(GameState.current_scene_path),
			int(GameState.player_position.x),
			int(GameState.player_position.y),
		])
	else:
		_show_feedback("保存失败……")


## 由场景路径换算一个带梦层的简短世界名，用于存档反馈。
func _world_name(scene_path: String) -> String:
	if scene_path.contains("main_menu") or scene_path.contains("intro"):
		return "序章"
	if scene_path.contains("dream2_rail_world"):
		return "二层·轨道世界"
	if scene_path.contains("dream1_meteor_world"):
		return "一层·流星世界"
	if scene_path.contains("dream1_deep_forest"):
		return "一层·深林"
	if scene_path.contains("dream1_nexus"):
		return "一层·主通道"
	if scene_path.contains("dream1_bedroom"):
		return "一层·卧室"
	return "现实·卧室"


func _show_feedback(text: String) -> void:
	save_button.text = text
	feedback_timer.start()


func _reset_button() -> void:
	if _feedback != "":
		save_button.text = _feedback
	else:
		save_button.text = "📖 写日记 (Y)"
	_on_diary_changed(GameState.diary_pages)


func _on_diary_changed(remaining: int) -> void:
	pages_label.text = "✏ 日记 %d / %d" % [remaining, GameState.MAX_DIARY_PAGES]
	save_button.disabled = remaining <= 0
	var base: String = "📖 写日记 (Y)"
	_feedback = base


func _on_scene_entered(scene_path: String) -> void:
	_refresh_visibility(scene_path)


func _refresh_visibility(scene_path: String) -> void:
	var hidden: bool = scene_path.contains("main_menu") or scene_path.contains("intro")
	visible = not hidden
	if visible and _feedback == "":
		save_button.text = "📖 写日记 (Y)"