## 梦境场景专用：按 Q 触发"捏脸醒来"。
##
## 挂到任何梦境场景的根节点下，由场景脚本连接 wake_requested 即可。
## 不会干扰玩家的方向键与交互键——只关心 wake_up 输入动作。
class_name WakeUpComponent
extends Node

signal wake_requested


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("wake_up"):
		wake_requested.emit()
		get_viewport().set_input_as_handled()
