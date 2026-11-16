# Next Level Dream — 项目约定（长程记忆）

> 这是该项目的工作约定，每次开始新会话前可读一下，避免重复决定。

## 工程基线

- **引擎**：Godot 4.7.2 stable（已验证），编辑器路径 `E:\Godot4\Godot_v4.7.2-stable_win64.exe`，headless 用 `Godot_v4.7.2-stable_win64_console.exe`。
- **分辨率**：viewport 1920×1080，window override 同样 1920×1080，stretch = canvas_items + aspect = expand。
- **渲染器**：`gl_compatibility`（兼容最广），默认纹理过滤 `0 = Nearest`。
- **语言**：GDScript 2.0 静态类型，禁止 `untyped var`。脚本 export 属性必须显式 `@export var x: 类型`。
- **C#**：本项目无 .NET，纯 GDScript 即可。

## 命名碰撞层（已写进 project.godot [layer_names]）

| 层 | bit | value | 用途 |
| --- | --- | --- | --- |
| world | 1 | 1 | 墙体、地板、家具的 StaticBody2D |
| player | 2 | 2 | CharacterBody2D 主体 |
| interactable | 3 | 4 | Interactable Area2D（玩家用 mask=4 探测） |

## 输入动作（project.godot）

| 动作 | 按键 |
| --- | --- |
| `move_left/right/up/down` | 方向键 |
| `interact` | Enter / Space / Z |
| `wake_up` | Q |
| `save_diary` | Y（写日记 / 存档） |
| `ui_*` | Godot 内置（Enter/Space/Esc 等） |

## Autoload

- `GameEvents`（事件总线）—— 仅放真正跨场景的事件，避免变成"全局垃圾桶"。
- `GameState`（存档）—— `user://diary.save`，JSON + 版本号 2；含 `is_dreaming / current_scene_path / player_position / dream_count / diary_pages`；**`save_diary()` 内部会调用 `capture_player_position()` 重新抓取玩家实时坐标**，保证"在哪写日记，读档就回哪"。
- `SceneFader`（淡入淡出 + 场景切换）—— `change_scene(path, fade_out, fade_in, landing)`；中途会写入 `GameState.pending_player_position`，Player._ready 时应用并清回 INF。
- `HUD`（Autoload 场景）—— 持久显示日记页数 + 写日记按钮；主菜单 / 介绍页自动隐藏。

## 组件化约定

- `Interactable`（Area2D 基类）—— 所有可交互物体都基于它（床、门、书桌、传送门、石碑）。新物体只需挂 `Interactable` 子节点 + CollisionShape2D + 脚本里 `connect("interacted", _on_xxx)`。
- `WakeUpComponent`（Node）—— 挂到所有梦境场景根节点上（DreamBedroom / Nexus / MeteorWorld / DeepForest），让 Q 键统一行为。
- `Player` —— 只有一个，单实例。

## 美术

- 占位美术由 `E:\Godot4AllGame\tools\gen_placeholder_art.py` 生成（**注意：脚本在项目外的 `tools/` 目录，不在 `NextLevelDream/tools/`**）。生成的内容覆盖了背景、角色、家具、所有彩色门、流星、深林树，下次美术替换时让美术保证 PNG 尺寸与碰撞矩形一致即可，不动代码。
- 主通道（Nexus）背景复用了 `bg_dream_world.png`（"十"字走廊）。

## 版本控制约定

- **git 仓库已建立**（2026-09-04，main 分支，初始提交为完整稳定基线）。本地身份：WorkBuddy / workbuddy@local。
- **每个任务完成并通过校验后立刻 `git add -A && git commit`**，提交信息写明"改了什么 + 验证结果"。提交前先跑 headless 校验 / 回归测试，不通过不提交。
- **回退手段**（按代价从小到大）：`git diff` 看改动 → `git checkout -- <文件>` 丢弃单文件未提交改动 → `git reset --hard HEAD` 回到上次提交 → `git revert <commit>` 撤销历史提交 → `git log --oneline` 找基线。
- `.gitignore` 已排除 `.godot/` 编辑器缓存与临时文件；`.uid` 文件必须提交。
- 用户没要求时不要 `git push`（没有远程仓库）；也不要做任何 `--force` 操作。

## 烟测脚本约定

- **临时 autoload 零容忍**：任何 `_` 前缀的临时 autoload（如 `_Screencap`、`_SaveTest`）必须**运行后立刻移除**，并用 `grep -E "_Screencap|_SaveTest" project.godot` 验证无残留。最好在同一条 Bash 命令里完成"挂载→运行→移除"。漏掉清理 = 下次启动游戏会自动跑测试脚本，表现像"闪退"（2026-09-04 实际踩过）。
- **临时截图**：`tools/_screencap.gd` 是临时脚本，截图后即删除；不留在生产代码里。
- **存档回归测试**：`tools/test_diary_save.gd` 是**永久保留**的回归测试，默认**不挂载**。需要验证时临时挂为 Autoload 跑，跑完移除。已覆盖 5 个场景的存档→读档→落地往返。

## 待办（按 Phase 顺序）

- 替换正式美术。
- 效果道具系统（`Effect.gd` + 桌面二级菜单）。
- 更多梦境场景。
- 屏幕扭曲 / 环境音 / 配乐。

## 已知约束

- 日记页数上限 `MAX_DIARY_PAGES = 15`，保存版本号 `SAVE_VERSION = 2`。改这两个常量时务必同步处理 `diary.save` 的旧版本兼容。
- `GameState.player_position` 是"上一次手工调用 `record_position` 留下的值"，写盘时会先被 `capture_player_position()` 覆盖；新场景 `_ready` 里手动 `record_position` 仅用于初值同步。
- 主通道里蓝/黄门是占位（提示"门后什么都没有"），新增世界时按 Nexus.gd 里 `door_meteor` / `door_forest` 的模式接入即可。