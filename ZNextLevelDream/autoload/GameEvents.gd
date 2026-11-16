## 跨场景事件总线（Autoload）。
##
## 职责边界：
##   只登记真正跨越多个场景的事件；场景内部的通信请直接用节点信号相连。
## 生命周期：与进程同生共死；不持有任何场景节点引用，避免悬空。
extends Node

## 玩家在现实卧室的床上入睡。
signal fell_asleep
## 玩家在梦境中捏脸醒来，回到现实卧室。
signal woke_up
## 玩家进入或离开某个场景。参数为场景文件路径。
signal scene_entered(scene_path: String)
## 玩家进入或离开梦境状态。参数为是否处于梦境中。
signal dream_state_changed(is_dreaming: bool)
