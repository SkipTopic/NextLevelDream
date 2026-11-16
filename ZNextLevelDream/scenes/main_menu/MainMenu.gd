## 主菜单（CanvasLayer + Control）。
##
## 选项：开始做梦 / 阅读日记 / 离开。
## 阅读日记在没有存档时禁用（鼠标悬停会跳过，键盘导航也会跳过）。
extends CanvasLayer

const INTRO_SCENE: String = "res://scenes/intro/Intro.tscn"

@onready var start_button: Button = $Root/Options/StartButton
@onready var load_button: Button = $Root/Options/LoadButton
@onready var quit_button: Button = $Root/Options/QuitButton


func _ready() -> void:
	# 广播场景进入：让 HUD / 触屏控件等按"主菜单"规则隐藏自己。
	GameEvents.scene_entered.emit(scene_file_path)
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	for button: Button in _buttons():
		button.focus_entered.connect(_on_focus_changed.bind(button))
		button.mouse_entered.connect(_on_focus_changed.bind(button))
	_refresh_load_button()
	start_button.grab_focus()


func _refresh_load_button() -> void:
	var has_save: bool = GameState.has_diary_entry()
	load_button.disabled = not has_save
	load_button.modulate = Color(1.0, 1.0, 1.0, 1.0) if has_save else Color(0.45, 0.45, 0.55, 1.0)


func _on_focus_changed(button: Button) -> void:
	for other: Button in _buttons():
		if other == button:
			other.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			other.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6, 1.0))


func _on_start_pressed() -> void:
	start_button.disabled = true
	# 新周目：背包、做梦次数、日记页全部归零（存档文件保留到下次写日记覆盖）。
	GameState.new_game()
	SceneFader.loading_text = "开始做梦……"
	await SceneFader.change_scene(INTRO_SCENE)
	start_button.disabled = false


func _on_load_pressed() -> void:
	if not GameState.read_diary():
		_refresh_load_button()
		return
	load_button.disabled = true
	var landing: Vector2 = GameState.player_position
	SceneFader.loading_text = "翻开日记……"
	await SceneFader.change_scene(GameState.current_scene_path, 0.85, 1.05, landing)
	load_button.disabled = false


func _on_quit_pressed() -> void:
	await SceneFader.fade_out(0.6)
	get_tree().quit()


func _buttons() -> Array[Button]:
	return [start_button, load_button, quit_button]