# 素材替换指南

> 把占位 PNG 换成正式像素图，**不需要改任何代码或场景文件**——只要保持文件名、目录、尺寸一致。

## 总体原则

- Godot 4 会在编辑器打开时自动生成 `.import` 元数据，首次替换时请在编辑器里右键 → Reimport 或重启编辑器。
- 所有 PNG 默认按 `gl_compatibility` 渲染器 + `default_texture_filter=0`（最近邻）渲染；正式美术若是高分辨率或抗锯齿友好，请单独在 `.import` 里把 `texture_filter` 改为 Linear。
- 透明度：保留 PNG alpha 通道；背景层通常是 RGB 实色，没有透明区域。

## 一键重新生成占位美术

```bash
pip install pillow          # 首次
python tools/gen_placeholder_art.py
```

生成脚本在项目内（`tools/gen_placeholder_art.py`），输出确定（`random.seed(20260903)`），可反复运行、整体覆盖 `assets/art/` 下所有 PNG。

## 各文件的尺寸与定位

> 单位为像素。`centered=true` 表示图片中心对齐到节点位置；`centered=false` 表示图片左上角对齐到节点位置。

### `assets/art/backgrounds/`

| 文件 | 尺寸 | 节点中心化 | 用途 |
| --- | --- | --- | --- |
| `bg_bedroom.png` | 1920 × 1080 | `centered = false` | 现实·卧室背景（第 0 层） |
| `bg_dream_bedroom.png` | 1920 × 1080 | `centered = false` | 一层·卧室背景（同布局的梦色版） |
| `bg_dream_world.png` | 2880 × 1620 | `centered = false` | 一层·主通道背景（"十"字走廊） |
| `bg_meteor_world.png` | 2880 × 1620 | `centered = false` | 一层·流星世界背景 |
| `bg_deep_forest.png` | **5760 × 1620** | `centered = false` | 一层·深林背景（横穿小径 y≈780~940 + 纵穿小径 x≈2800~2960 + 传送门纹样 (2880, 1480)） |
| `bg_rail_world.png` | **5760 × 1620** | `centered = false` | **二层·轨道世界**背景（夜空+城市剪影+三条铁轨+左端悬崖+右端保安室水泥台） |
| `bg_security_room.png` | 1920 × 1080 | `centered = false` | **保安室内部**背景（钢灰墙+铁栏窗+公告板+水泥地格） |
| `bg_street.png` | **3840 × 1620** | `centered = false` | **二层·大街**背景（沿街楼群亮窗+人行道+两条斑马线 x≈960/2400+右端悬崖） |
| `bg_hospital_outside.png` | 1920 × 1080 | `centered = false` | **医院外**背景（门诊楼+红十字雨棚+玻璃门+门前马路） |
| `bg_hospital_inside.png` | **2880 × 1620** | `centered = false` | **医院内部**背景（淡绿大厅+方格地砖+3/2/1号通道口+右侧两扇门） |
| `bg_grass_world.png` | **2880 × 1620** | `centered = false` | **第三层·草地**背景（明亮草地+远处树影） |

### `assets/art/characters/`

| 文件 | 尺寸 | 内容 | 引用方式 |
| --- | --- | --- | --- |
| `protagonist.png` | 360 × 720 | 单帧 120 × 180，4 行（down/left/right/up） × 3 列（stand/stepL/stepR） | `Player.tscn` 的 `sprite_sheet` 导出属性；运行期程序化切成 AtlasTexture |

> **如果改了单帧尺寸**，请同步修改 `scripts/Player.gd` 顶部的 `FRAME_SIZE / SHEET_COLUMNS / DIRECTION_ROWS`。

### `assets/art/props/`

#### 卧室家具（reality_bedroom + dream1_bedroom 共用，位置完全相同）

| 文件 | 尺寸 | 节点位置 | 碰撞体 |
| --- | --- | --- | --- |
| `bed.png` | 320 × 260 | (380, 560) | 300 × 110 @ offset (0, 80) |
| `nightstand.png` | 150 × 130 | (700, 560) | 130 × 80 @ offset (0, 55) |
| `desk.png` | 360 × 220 | (1500, 600) | 330 × 100 @ offset (0, 55) |
| `bookshelf.png` | 200 × 300 | (1810, 500) | 180 × 270（静态） |
| `door.png` | 140 × 230 | (1230, 350) | 无主体碰撞，仅交互区 |
| `rug.png` | 420 × 240 | (960, 940) | 无碰撞（纯装饰） |

#### 一层·主通道（dream1_nexus）

| 文件 | 尺寸 | 节点位置 | 备注 |
| --- | --- | --- | --- |
| `door_red.png` | 160 × 260 | (1440, 350) → 流星世界 | StaticBody2D + Interactable |
| `door_green.png` | 160 × 260 | (2240, 540) → 深林 | 同上 |
| `door_blue.png` | 160 × 260 | (2480, 1080) | 锁定占位 |
| `door_yellow.png` | 160 × 260 | (400, 1080) | 锁定占位 |
| `monolith.png` | 160 × 260 | (480, 1280) / (2400, 1280) | 石碑 / 石柱 |
| `portal.png` | 180 × 220 | (1440, 1080) | 回程传送门 → 一层卧室 |

#### 一层·流星世界（dream1_meteor_world）

| 文件 | 尺寸 | 节点位置 | 备注 |
| --- | --- | --- | --- |
| `portal.png` | 180 × 220 | (1440, 1480) | 回到主通道 |
| `pills.png` | **128 × 128** | (2300, 640) | **安眠药**（场景拾取物 + 背包图标共用）；捡过后隐藏节点 |
| `meteor.png` | 96 × 320 | 由 `MeteorSpawner` 随机生成 | 流星长条带尾迹 |

#### 一层·深林（dream1_deep_forest）

| 文件 | 尺寸 | 节点位置 | 备注 |
| --- | --- | --- | --- |
| `tree.png` | 260 × 380 | 程序化随机撒 70 棵 | ~70% 带 110×120 树干碰撞 |
| `portal.png` | 180 × 220 | 底端中间 → 回主通道 | 位置由 .tscn 写死 |

#### 二层·轨道世界（dream2_rail_world）+ 保安室内部

| 文件 | 尺寸 | 节点位置 | 备注 |
| --- | --- | --- | --- |
| `booth.png` | **480 × 520** | Booth 节点 (5160, 600)，`centered = false` | 保安室外观（正面关着：亮窗 + 白色门）；主体碰撞 480 × 400 @ 局部 (240, 200) |
| `door_white.png` | **140 × 230** | SecurityRoom 白门 (1137, 350) | 保安室内部出口门；交互区 220 × 290 |
| `pistol.png` | **128 × 128** | SecurityRoom 手枪 (1620, 545)，办公桌上 | 场景拾取物 + 背包图标共用；捡过后隐藏节点 |
| `desk.png` | 360 × 220 | SecurityRoom 办公桌 (1560, 600) | 与卧室书桌共用素材 |
| `bed.png` | 320 × 260 | SecurityRoom 床 (450, 560) | **床在保安室内部**（麻醉剂→第三层） |
| `scooter_world.png` | 220 × 150 | 大街 Scooter (2600, 1120) | **电瓶车**（装备后提速）；拾取后隐藏节点 |
| `page.png` | 120 × 84 | 由 `Dream4Ocean._spawn_pages()` 动态生成 | **漂在海面上的书页**（无碰撞、随机漂动）；上限 36 片 |
| `ambulance.png` | 440 × 300 | 医院外 Ambulance (1450, 880) | **救护车**（麻醉剂拾取点）；拾取后隐藏节点 |
| `reception.png` | 440 × 220 | 医院内 Reception (1440, 950) | 接诊台；碰撞 380 × 120，交互区 460 × 280 |
| `bench.png` | 280 × 170 | 医院内长椅 ×2 (700/1010, 520) + 椅子 (780, 700) 缩放 0.75 | 碰撞 220 × 90 |
| `npc.png` | 96 × 160 | 由 `HospitalInside._spawn_npc()` 生成 3 个 | 随机走动 NPC（`scripts/WanderingNPC.gd`），layer=1 有碰撞 |

> 大街布局常量：斑马线 x = 960 / 2400；悬崖深渊右缘 x ≈ 3620（悬崖交互区 (3520, 1150)）；
> 医院入口交互区 (1970, 1420)。医院内部：3号通道 (1440, 380)、2号 (160, 980)、1号 (2720, 980)、
> 两扇门 (2205/2525, 480)、底部出口 (1440, 1470)——均为占位互动。

> 轨道世界布局常量（背景与碰撞对应关系，替换美术时注意）：
> 三条铁轨 y = 1030 / 1160 / 1290；悬崖深渊右缘 x ≈ 292（悬崖交互区中心 (240, 1150)，墙 x=60）；
> 保安室水泥台 = (5100, 1120)–(5700, 1330)；白门交互区中心 = Booth 局部 (360, 390) → 全局 (5520, 990)。
> 保安室内部的门/桌/床坐标见 `SecurityRoom.tscn`（门 (1230,350)、桌 (1560,600)、床 (450,560)）。

### 主通道背景里的墙体

`bg_dream_world.png` 里的"十"字形走廊对应 `Dream1Nexus.tscn` 中的四条边界 StaticBody2D（各 80px 厚）。美术替换时**不要改变这个"十"字位置**。

## 推荐的正式美术分辨率

- 角色精灵图：单帧 240 × 360、整体 720 × 1440（放大 2 倍后更耐看），然后把 `FRAME_SIZE` 改成 `Vector2(240, 360)`。
- 道具：每个道具单文件 ≥ 480 px 宽边长，PNG 8-bit；`pills.png` 这类背包图标保持 128 × 128 或翻倍到 256 × 256。

## 字体

工程未引入自定义字体；中文沿用 Godot 默认 fallback。若要统一美术字风，可在 `project.godot` 添加 `[gui] theme/custom_font`。

## 着色器（assets/shaders/）

| 文件 | 用途 | 参数 |
| --- | --- | --- |
| `ocean_water.gdshader` | 第四层海洋水面（挂在 Ocean 场景 Water 节点） | wave_speed / deep·shallow·crest_color / crest_density / sparkle_strength |
| `water_submerge.gdshader` | 玩家站海水里的浸身效果（Dream4Ocean 挂到玩家精灵上） | water_color / waterline_v（水面高度 0.7）/ max_submerge / wave_amp；frame_region 由代码逐帧更新 |
| `fireflies.gdshader` | 主菜单萤火虫层（数量 = shader 里循环上限 18） | speed / glow_size / firefly_color / aspect |
| `tear_page.gdshader` | 写日记的撕书动画（TearPage 结算层驱动 progress） | progress 由代码驱动，无需手调 |
| `dream_mosaic.gdshader` | 梦层跃迁的马赛克转场（DreamTransition 驱动 progress） | screen_tex / progress 由代码驱动；max_block_px（60×60）/ fade_strength 可调 |
| `tree_sway.gdshader` | 深林树冠风摆（挂在每棵树的精灵上，底部固定顶部摆动） | sway_strength / sway_speed / phase（逐棵由位置生成） |
