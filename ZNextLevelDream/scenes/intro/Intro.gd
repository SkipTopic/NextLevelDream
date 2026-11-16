## 介绍页（新游戏之后第一个进入的画面）。
##
## 显示一段简短文字说明玩法，等待玩家按任意交互键
## 或点击底部"继续"按钮（手机端没有键盘）进入现实卧室。
extends CanvasLayer

const BEDROOM_SCENE: String = "res://scenes/reality_bedroom/RealityBedroom.tscn"

@onready var hint_label: Label = $Root/HintLabel
@onready var continue_button: Button = $Root/ContinueButton


func _ready() -> void:
	# 广播场景进入：让 HUD / 触屏控件等按"介绍页"规则隐藏自己。
	GameEvents.scene_entered.emit(scene_file_path)
	hint_label.modulate.a = 0.0
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(hint_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(hint_label, "modulate:a", 0.45, 1.0).set_trans(Tween.TRANS_SINE)
	continue_button.pressed.connect(_continue)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode != KEY_ESCAPE:
			_continue()
	elif event.is_action_pressed("interact"):
		_continue()


func _continue() -> void:
	get_viewport().set_input_as_handled()
	GameState.set_dream_layer(GameState.LAYER_REALITY)
	GameState.current_scene_path = BEDROOM_SCENE
	GameState.player_position = Vector2(960.0, 860.0)
	SceneFader.loading_text = "走进房间……"
	await SceneFader.change_scene(BEDROOM_SCENE)