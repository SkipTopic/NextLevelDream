## 通用双选项对话框（场景级别 CanvasLayer）。
##
## 用法：
##   var dialog := preload("res://scenes/ui/ChoiceDialog.tscn").instantiate()
##   add_child(dialog)
##   dialog.open("书桌上有一本日记。", "保存游戏", "补充日记本")
##   dialog.choice_made.connect(_on_choice.bind(dialog))
##
## 选项索引：0 = A，1 = B。按 Esc / ui_cancel 触发 cancelled 信号后自释放。
extends CanvasLayer

signal choice_made(index: int)
signal cancelled

@onready var dimmer: ColorRect = $Dimmer
@onready var prompt_label: Label = $Panel/VBox/PromptLabel
@onready var option_a: Button = $Panel/VBox/OptionA
@onready var option_b: Button = $Panel/VBox/OptionB
@onready var option_c: Button = $Panel/VBox/OptionC

var _captured_player: Player = null


func _ready() -> void:
	layer = 200
	option_a.pressed.connect(_emit_a)
	option_b.pressed.connect(_emit_b)
	option_c.pressed.connect(_emit_c)
	visible = false
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP


## c_text 传空字符串时隐藏第三个选项（默认只有 A/B 两个选项）。
func open(prompt: String, a_text: String, b_text: String, c_text: String = "") -> void:
	prompt_label.text = prompt
	option_a.text = a_text
	option_b.text = b_text
	option_c.text = c_text
	option_c.visible = c_text != ""
	visible = true
	option_a.grab_focus()
	_capture_player()


func _capture_player() -> void:
	# 锁定当前场景里的玩家，让它在对话框期间不会乱跑。
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	_captured_player = _find_player(tree.current_scene)
	if _captured_player != null:
		_captured_player.lock()


func _find_player(node: Node) -> Player:
	if node is Player:
		return node
	for child in node.get_children():
		var found: Player = _find_player(child)
		if found != null:
			return found
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		cancelled.emit()
		queue_free()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if _captured_player != null and is_instance_valid(_captured_player):
		_captured_player.unlock()


func _emit_a() -> void:
	choice_made.emit(0)
	queue_free()


func _emit_b() -> void:
	choice_made.emit(1)
	queue_free()


## 第三个选项：与 Esc 等价的"返回"，不触发 choice_made。
func _emit_c() -> void:
	cancelled.emit()
	queue_free()