## 游戏结束结算层（Autoload CanvasLayer）。
##
## 规则：日记页数归 0 → 玩家死亡，游戏结束。
## 监听 GameState.diary_changed：页数一旦为 0，暂停整个场景树，
## 黑屏缓缓浮现"永远沉溺在梦境之中吧"，玩家只能回到主菜单重新开始。
extends CanvasLayer

const MAIN_MENU: = "res://scenes/main_menu/MainMenu.tscn"
## 黑屏浮现的时长（秒）——死亡要沉得足够慢。
const FADE_DURATION: = 2.2

@onready var _root: Control = $Root
@onready var _menu_button: Button = $Root/MenuButton

var _shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 250
	visible = false
	_root.modulate.a = 0.0
	_menu_button.pressed.connect(_on_menu_pressed)
	GameState.diary_changed.connect(_on_diary_changed)


func _on_diary_changed(remaining: int) -> void:
	if remaining > 0 or _shown:
		return
	_shown = true
	visible = true
	get_tree().paused = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 回到主菜单：解除暂停并重置整局（页数、梦层、背包全部归零）。
func _on_menu_pressed() -> void:
	_shown = false
	visible = false
	get_tree().paused = false
	GameState.new_game()
	SceneFader.change_scene(MAIN_MENU)
