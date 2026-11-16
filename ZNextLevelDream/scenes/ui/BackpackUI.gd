## 背包界面（Autoload CanvasLayer）。
##
## 布局（1920x1080 设计分辨率，窗口居中，对应手绘草图）：
##   - 左侧大框：4x4 物品格子，底部一行收集计数
##   - 右上：选中物品的展示图
##   - 右下：物品名字 + 介绍 + "装备 / 卸下"按钮
##   - 左上角 ✕ 关闭；B 键开关背包，Esc 也能关
##
## 打开时暂停整个场景树（本界面 process_mode = ALWAYS 保持可交互），
## 玩家移动、Q 醒来、Y 存档都会被一并冻结，关界面时恢复。
extends CanvasLayer

## 梦日记式配色：近黑底 + 品红描边，与主菜单 / HUD 保持同一气质。
const _COLOR_WINDOW_BG := Color(0.04, 0.02, 0.05, 0.97)
const _COLOR_SLOT_BG := Color(0.10, 0.05, 0.12)
const _COLOR_SLOT_SELECTED_BG := Color(0.18, 0.09, 0.23)
const _COLOR_BORDER := Color(0.72, 0.28, 0.52)
const _COLOR_BORDER_BRIGHT := Color(0.90, 0.52, 0.72)
const _COLOR_BORDER_DIM := Color(0.42, 0.18, 0.32)
const _COLOR_TEXT := Color(0.93, 0.82, 0.88)
const _COLOR_TEXT_DIM := Color(0.72, 0.60, 0.67)
const _COLOR_TEXT_PINK := Color(0.96, 0.62, 0.80)

const _SLOT_SIZE := Vector2(130.0, 130.0)

@onready var _close_button: Button = $Window/CloseButton
@onready var _grid: GridContainer = $Window/GridPanel/Grid
@onready var _counter_label: Label = $Window/GridPanel/CounterLabel
@onready var _image_rect: TextureRect = $Window/ImagePanel/ImageRect
@onready var _name_label: Label = $Window/DescPanel/VBox/NameLabel
@onready var _desc_label: Label = $Window/DescPanel/VBox/DescLabel
@onready var _equip_button: Button = $Window/DescPanel/VBox/EquipButton

## 与 Backpack.MAX_SLOTS 对齐的格子控件。
var _slots: Array[Button] = []
var _slot_icons: Array[TextureRect] = []
var _slot_badges: Array[Label] = []
## 当前选中的格子下标；-1 表示未选中。
var _selected_index: int = -1
var _button_group := ButtonGroup.new()
## 主菜单 / 介绍页不允许打开背包（与 HUD 的隐藏规则一致）。
var _scene_allowed: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	visible = false
	_close_button.pressed.connect(_close)
	_equip_button.pressed.connect(_on_equip_pressed)
	Backpack.item_added.connect(_on_backpack_changed)
	Backpack.item_removed.connect(_on_backpack_changed)
	Backpack.equipped_changed.connect(_on_backpack_changed)
	GameEvents.scene_entered.connect(_on_scene_entered)
	_build_slots()
	# 自动加载先于主场景就绪，延迟一帧再判断初始场景。
	call_deferred("_check_initial_scene")


func _unhandled_input(event: InputEvent) -> void:
	# 转场期间不开背包，避免暂停把淡入淡出冻在半路。
	if SceneFader.is_transitioning():
		return
	if event.is_action_pressed("backpack"):
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


# --- 开关 ----------------------------------------------------------------

func _open() -> void:
	if visible or not _scene_allowed:
		return
	visible = true
	get_tree().paused = true
	# 热加载逐层介绍：改 data/item_descriptions.json 后重新打开背包立即生效。
	Backpack.reload_item_descriptions()
	if _selected_index < 0 and not Backpack.items.is_empty():
		_selected_index = 0
	_refresh_all()
	if _selected_index >= 0:
		_slots[_selected_index].grab_focus()


func _close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func _on_scene_entered(scene_path: String) -> void:
	_scene_allowed = not (scene_path.contains("main_menu") or scene_path.contains("intro"))
	if not _scene_allowed:
		_close()


func _check_initial_scene() -> void:
	var current: Node = get_tree().current_scene
	if current != null and not current.scene_file_path.is_empty():
		_on_scene_entered(current.scene_file_path)


# --- 刷新 ----------------------------------------------------------------

func _on_backpack_changed(_id: String) -> void:
	# 打开时才跟着刷；关闭时下次 _open 会统一刷新。
	if visible:
		_refresh_all()


func _refresh_all() -> void:
	var ids: Array[String] = Backpack.items
	for i in _slots.size():
		var id: String = ids[i] if i < ids.size() else ""
		_update_slot(i, id)
		_slots[i].set_pressed_no_signal(i == _selected_index)
	_counter_label.text = "收集 %d / %d" % [ids.size(), Backpack.MAX_SLOTS]
	_update_detail()


func _update_slot(index: int, id: String) -> void:
	var icon: TextureRect = _slot_icons[index]
	var badge: Label = _slot_badges[index]
	if id.is_empty():
		icon.texture = null
		_slots[index].tooltip_text = ""
		badge.visible = false
		return
	var info: Dictionary = Backpack.get_item_info(id)
	icon.texture = _load_icon(String(info.get("icon", "")))
	_slots[index].tooltip_text = String(info.get("name", id))
	badge.visible = Backpack.is_equipped(id)


func _update_detail() -> void:
	var id := _selected_id()
	if id.is_empty():
		_image_rect.texture = null
		_name_label.text = "—"
		if Backpack.items.is_empty():
			_desc_label.text = "还没有收集到任何东西。"
		else:
			_desc_label.text = "从左边的格子里选一个物品看看吧。"
		_equip_button.disabled = true
		_equip_button.text = "装备"
		return
	var info: Dictionary = Backpack.get_item_info(id)
	_name_label.text = String(info.get("name", id))
	# 介绍随当前梦层变化（data/item_descriptions.json）。
	_desc_label.text = Backpack.get_item_description(id)
	_image_rect.texture = _load_icon(String(info.get("icon", "")))
	if bool(info.get("usable", false)):
		_equip_button.disabled = false
		_equip_button.text = "使用"
	elif bool(info.get("equippable", false)):
		_equip_button.disabled = false
		_equip_button.text = "卸下" if Backpack.is_equipped(id) else "装备"
	else:
		_equip_button.disabled = true
		_equip_button.text = "装备"


func _selected_id() -> String:
	if _selected_index < 0 or _selected_index >= Backpack.items.size():
		return ""
	return Backpack.items[_selected_index]


# --- 交互 ----------------------------------------------------------------

func _on_slot_pressed(index: int) -> void:
	_selected_index = index
	_update_detail()


func _on_equip_pressed() -> void:
	var id := _selected_id()
	if id.is_empty():
		return
	if bool(Backpack.get_item_info(id).get("usable", false)):
		_use_item(id)
		return
	if Backpack.is_equipped(id):
		Backpack.unequip()
	else:
		Backpack.equip(id)


# --- 物品使用 -------------------------------------------------------------

## 可用物品的使用入口；每种物品的使用效果在这里分发。
func _use_item(id: String) -> void:
	match id:
		"pistol":
			_use_pistol()
		_:
			push_warning("BackpackUI: 物品 %s 没有使用逻辑。" % id)


## 手枪：在梦里开一枪，痛醒回上一层"入睡的地方"（床锚点）；
## 第一层用 → 醒回现实的床边；现实里不能用——只说"太危险"。
func _use_pistol() -> void:
	if GameState.dream_layer == GameState.LAYER_REALITY:
		var player_here: Player = _find_player(get_tree().current_scene)
		_close()
		if player_here != null:
			player_here.say("在现实里用这个，就真的醒不过来了。太危险了。")
		return
	var target_layer: int = GameState.dream_layer - 1
	var target: String = ""
	var landing: Vector2 = Vector2.ZERO
	var anchor: Dictionary = GameState.bed_anchor(target_layer)
	if not anchor.is_empty():
		target = anchor["scene"]
		landing = anchor["position"]
	else:
		# 锚点缺失的兜底（正常流程睡觉时都会记录锚点）。
		var fallback: Dictionary = _PISTOL_FALLBACK.get(target_layer, {})
		target = String(fallback.get("scene", ""))
		landing = fallback.get("position", Vector2.ZERO)
	if target.is_empty():
		push_warning("BackpackUI: 手枪找不到第 %d 层的落点。" % target_layer)
		return
	# 先关背包解除暂停，否则转场截图会拍到背包界面。
	var player: Player = _find_player(get_tree().current_scene)
	_close()
	if player != null:
		player.lock()
	GameState.set_dream_layer(target_layer)
	GameState.record_position(target, landing)
	# 梦层跃迁（n→n-1）：马赛克转场。枪声快进慢出的刺激感来自马赛克的节奏。
	await DreamTransition.change_scene(target, landing)


## 手枪在锚点缺失时的兜底落点：梦层 → {scene, position}。
const _PISTOL_FALLBACK := {
	0: {"scene": "res://scenes/reality_bedroom/RealityBedroom.tscn", "position": Vector2(960.0, 860.0)},
	1: {"scene": "res://scenes/dream1_bedroom/Dream1Bedroom.tscn", "position": Vector2(440.0, 780.0)},
	2: {"scene": "res://scenes/dream2_rail_world/Dream2RailWorld.tscn", "position": Vector2(900.0, 1150.0)},
}


func _find_player(node: Node) -> Player:
	if node is Player:
		return node
	for child: Node in node.get_children():
		var found: Player = _find_player(child)
		if found != null:
			return found
	return null


# --- 格子构建 -------------------------------------------------------------

## 物品没配 icon 时返回 null，避免 load("") 报错。
func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(path) as Texture2D


## 格子控件在代码里生成：数量跟随 Backpack.MAX_SLOTS，改常量即可增减。
func _build_slots() -> void:
	var normal := _make_slot_style(_COLOR_SLOT_BG, _COLOR_BORDER_DIM)
	var hover := _make_slot_style(_COLOR_SLOT_BG.lightened(0.05), _COLOR_BORDER)
	var selected := _make_slot_style(_COLOR_SLOT_SELECTED_BG, _COLOR_BORDER_BRIGHT)
	for i in Backpack.MAX_SLOTS:
		var slot := Button.new()
		slot.custom_minimum_size = _SLOT_SIZE
		slot.toggle_mode = true
		# ButtonGroup 让格子互斥选中：按下态就是选中态。
		slot.button_group = _button_group
		slot.add_theme_stylebox_override("normal", normal)
		slot.add_theme_stylebox_override("hover", hover)
		slot.add_theme_stylebox_override("pressed", selected)
		slot.add_theme_stylebox_override("hover_pressed", selected)
		# 选中态已经足够明显，压掉默认的聚焦高亮框。
		slot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		slot.pressed.connect(_on_slot_pressed.bind(i))

		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 14.0
		icon.offset_top = 14.0
		icon.offset_right = -14.0
		icon.offset_bottom = -14.0
		slot.add_child(icon)

		var badge := Label.new()
		badge.text = "装备中"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 18)
		badge.add_theme_color_override("font_color", _COLOR_BORDER_BRIGHT)
		badge.add_theme_color_override("font_outline_color", Color.BLACK)
		badge.add_theme_constant_override("outline_size", 4)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		badge.offset_top = -32.0
		badge.offset_bottom = -6.0
		badge.visible = false
		slot.add_child(badge)

		_grid.add_child(slot)
		_slots.append(slot)
		_slot_icons.append(icon)
		_slot_badges.append(badge)


func _make_slot_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(3)
	style.set_content_margin_all(4.0)
	return style
