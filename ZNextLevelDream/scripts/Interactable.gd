## 交互探针的基类（Area2D）。
##
## 玩家按下"交互键"且位于 InteractArea 半径内时，触发 interacted 信号。
## 场景脚本应连接到本节点，处理"睡眠 / 写日记 / 进门 / 醒来"等具体行为。
class_name Interactable
extends Area2D

## 玩家按下交互键时触发，参数为发起交互的玩家节点。
signal interacted(source: Node2D)

## 站在附近时显示的提示文字；留空则不显示提示。
@export var hint_text: String = ""

## 关闭后不再响应交互。
@export var enabled: bool = true:
	set(value):
		enabled = value
		monitoring = value
		monitorable = value


func _ready() -> void:
	monitoring = enabled
	monitorable = enabled


## 玩家按交互键时调用；子类可重写以处理一次性交互或冷却。
func interact(source: Node2D) -> void:
	if not enabled:
		return
	interacted.emit(source)
