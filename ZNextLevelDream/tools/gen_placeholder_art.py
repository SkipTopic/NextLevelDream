# -*- coding: utf-8 -*-
"""
Next Level Dream —— 占位美术资源生成器（一次性工具，不参与游戏运行）。

生成的全部 PNG 都是"可直接替换"的占位素材：
替换时只要保持文件名与尺寸一致，场景与碰撞体无需改动。

运行：
    pip install pillow   （首次）
    python tools/gen_placeholder_art.py

输出是确定性的（random.seed(20260903)），可反复运行。
"""

from __future__ import annotations

import os
import random

from PIL import Image, ImageDraw

PROJECT = r"E:\Godot4AllGame\ZcodeMadeGame\ZNextLevelDream"
ART = os.path.join(PROJECT, "assets", "art")
DIR_BG = os.path.join(ART, "backgrounds")
DIR_PROPS = os.path.join(ART, "props")
DIR_CHARS = os.path.join(ART, "characters")

for _d in (DIR_BG, DIR_PROPS, DIR_CHARS):
    os.makedirs(_d, exist_ok=True)

random.seed(20260903)

OUTLINE = (22, 20, 30, 255)
WOOD = (122, 89, 62, 255)
WOOD_DARK = (91, 62, 42, 255)
WOOD_LIGHT = (150, 112, 78, 255)


# --------------------------------------------------------------------------
# 基础绘制助手
# --------------------------------------------------------------------------
def ell(d: ImageDraw.ImageDraw, box, fill, outline: bool = True, width: int = 4):
    d.ellipse(box, fill=fill, outline=OUTLINE if outline else None, width=width)


def rr(d: ImageDraw.ImageDraw, box, radius, fill, outline: bool = True, width: int = 4):
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=OUTLINE if outline else None, width=width)


def vgradient(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, top, bottom) -> None:
    height = y1 - y0
    if height <= 0:
        return
    for i in range(height):
        t = i / max(height - 1, 1)
        color = tuple(int(top[k] + (bottom[k] - top[k]) * t) for k in range(3)) + (255,)
        d.line((x0, y0 + i, x1, y0 + i), fill=color)


def canvas(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


# --------------------------------------------------------------------------
# 角色：protagonist.png —— 3 列（站立/左脚/右脚） x 4 行（下/左/右/上）
# 单帧 120x180，整表 360x720
# --------------------------------------------------------------------------
FRAME_W, FRAME_H = 120, 180

SKIN = (246, 216, 188, 255)
HAIR = (44, 40, 58, 255)
HAIR_LIGHT = (68, 62, 88, 255)
SHIRT = (242, 238, 228, 255)
SHIRT_SHADE = (206, 200, 188, 255)
PANTS = (56, 56, 80, 255)
SHOE = (104, 72, 50, 255)


def _leg_pose(step: int) -> tuple[int, int, int, int]:
    if step == 0:
        return 0, 0, 0, 0
    if step == 1:
        return -7, -7, 7, 5
    return 7, -7, -7, 5


def draw_hero(direction: str, step: int) -> Image.Image:
    img, d = canvas(FRAME_W, FRAME_H)
    lx, ly, rx, ry = _leg_pose(step)

    # 后发（齐耳短发轮廓）
    ell(d, (26, 6, 94, 98), HAIR)

    # 腿与鞋
    rr(d, (42 + lx, 122 + ly, 58 + lx, 166 + ly), 8, PANTS)
    rr(d, (62 + rx, 122 + ry, 78 + rx, 166 + ry), 8, PANTS)
    rr(d, (36 + lx, 158 + ly, 60 + lx, 176 + ly), 7, SHOE)
    rr(d, (60 + rx, 158 + ry, 84 + rx, 176 + ry), 7, SHOE)

    # 躯干
    rr(d, (34, 74, 86, 142), 13, SHIRT)
    d.rounded_rectangle((38, 124, 82, 138), radius=7, fill=SHIRT_SHADE)

    # 手臂
    rr(d, (26, 86, 40, 128), 7, SHIRT)
    rr(d, (80, 86, 94, 128), 7, SHIRT)
    ell(d, (26, 118, 42, 134), SKIN, width=3)
    ell(d, (78, 118, 94, 134), SKIN, width=3)

    # 头部底色
    ell(d, (34, 18, 86, 88), SKIN)

    if direction == "up":
        ell(d, (26, 6, 94, 96), HAIR)
        d.arc((40, 14, 80, 56), start=200, end=340, fill=HAIR_LIGHT, width=6)
    elif direction == "down":
        ell(d, (40, 44, 80, 90), SKIN)
        rr(d, (30, 8, 90, 54), 22, HAIR)
        ell(d, (46, 62, 54, 70), HAIR, outline=False)
        ell(d, (66, 62, 74, 70), HAIR, outline=False)
    elif direction == "left":
        ell(d, (36, 44, 76, 90), SKIN)
        rr(d, (30, 8, 78, 54), 22, HAIR)
        rr(d, (74, 34, 94, 98), 12, HAIR)
        ell(d, (48, 62, 56, 70), HAIR, outline=False)
    else:  # right
        ell(d, (44, 44, 84, 90), SKIN)
        rr(d, (42, 8, 90, 54), 22, HAIR)
        rr(d, (26, 34, 46, 98), 12, HAIR)
        ell(d, (64, 62, 72, 70), HAIR, outline=False)

    return img


def build_hero_sheet() -> None:
    sheet = Image.new("RGBA", (FRAME_W * 3, FRAME_H * 4), (0, 0, 0, 0))
    rows = {"down": 0, "left": 1, "right": 2, "up": 3}
    for name, row in rows.items():
        for col in range(3):
            sheet.alpha_composite(draw_hero(name, col), (col * FRAME_W, row * FRAME_H))
    sheet.save(os.path.join(DIR_CHARS, "protagonist.png"))


# --------------------------------------------------------------------------
# 道具
# --------------------------------------------------------------------------
def build_bed() -> None:
    img, d = canvas(320, 260)
    rr(d, (8, 6, 312, 76), 14, WOOD_DARK)          # 床头板
    rr(d, (14, 40, 306, 250), 12, WOOD)            # 床架
    rr(d, (28, 52, 292, 210), 14, (222, 216, 234, 255))   # 床垫
    rr(d, (28, 128, 292, 238), 16, (124, 110, 168, 255))  # 被子
    d.rounded_rectangle((28, 128, 292, 150), radius=10, fill=(158, 144, 200, 255))
    rr(d, (66, 62, 254, 124), 16, (242, 238, 228, 255))   # 枕头
    img.save(os.path.join(DIR_PROPS, "bed.png"))


def build_nightstand() -> None:
    img, d = canvas(150, 130)
    rr(d, (8, 26, 142, 126), 10, WOOD)
    rr(d, (2, 16, 148, 52), 10, WOOD_LIGHT)
    rr(d, (104, 40, 116, 62), 4, (120, 120, 130, 255))
    ell(d, (82, 0, 138, 44), (240, 214, 138, 255))
    img.save(os.path.join(DIR_PROPS, "nightstand.png"))


def build_desk() -> None:
    img, d = canvas(360, 220)
    rr(d, (16, 92, 44, 216), 6, WOOD_DARK)
    rr(d, (316, 92, 344, 216), 6, WOOD_DARK)
    rr(d, (0, 36, 360, 100), 10, WOOD_LIGHT)
    rr(d, (108, 0, 252, 84), 10, (43, 43, 56, 255))        # 显示器外壳
    rr(d, (120, 12, 240, 70), 6, (74, 127, 181, 255))      # 屏幕
    d.rectangle((132, 24, 228, 34), fill=(120, 170, 214, 255))
    d.rectangle((132, 44, 200, 54), fill=(120, 170, 214, 255))
    rr(d, (118, 96, 244, 118), 5, (216, 216, 216, 255))    # 键盘
    rr(d, (20, 60, 96, 96), 8, (196, 190, 176, 255))       # 日记本
    img.save(os.path.join(DIR_PROPS, "desk.png"))


def build_bookshelf() -> None:
    img, d = canvas(200, 300)
    rr(d, (4, 4, 196, 296), 10, WOOD_DARK)
    d.rectangle((14, 14, 186, 286), fill=(70, 48, 34, 255))
    palette = [
        (168, 96, 88, 255), (96, 128, 168, 255), (140, 160, 108, 255),
        (188, 156, 96, 255), (124, 100, 152, 255), (92, 148, 140, 255),
    ]
    for row, top in enumerate((30, 118, 206)):
        d.rectangle((14, top + 68, 186, top + 74), fill=WOOD)
        x = 20
        while x < 180:
            w = random.randint(12, 26)
            if x + w > 180:
                break
            d.rectangle((x, top + random.randint(6, 14), x + w, top + 68), fill=random.choice(palette))
            x += w + 3
    img.save(os.path.join(DIR_PROPS, "bookshelf.png"))


def build_rug() -> None:
    img, d = canvas(420, 240)
    ell(d, (0, 0, 420, 240), (138, 90, 138, 255))
    ell(d, (26, 14, 394, 226), (162, 112, 162, 255), outline=False)
    ell(d, (60, 30, 360, 210), (138, 90, 138, 255), outline=False)
    img.save(os.path.join(DIR_PROPS, "rug.png"))


def build_door() -> None:
    img, d = canvas(140, 230)
    rr(d, (0, 0, 140, 230), 8, WOOD_DARK)
    rr(d, (14, 12, 126, 218), 8, WOOD)
    rr(d, (30, 32, 110, 118), 6, WOOD_DARK)
    rr(d, (30, 132, 110, 200), 6, WOOD_DARK)
    ell(d, (106, 108, 122, 124), (216, 180, 106, 255), width=3)
    img.save(os.path.join(DIR_PROPS, "door.png"))


def build_portal() -> None:
    img, d = canvas(180, 220)
    ell(d, (6, 6, 174, 214), (42, 31, 61, 255))
    ell(d, (24, 24, 156, 196), (122, 79, 181, 255))
    ell(d, (46, 46, 134, 174), (216, 176, 240, 255))
    ell(d, (70, 70, 110, 150), (250, 244, 255, 255), outline=False)
    img.save(os.path.join(DIR_PROPS, "portal.png"))


def build_monolith() -> None:
    img, d = canvas(160, 260)
    rr(d, (20, 10, 140, 250), 10, (48, 42, 68, 255))
    d.rectangle((30, 20, 130, 60), fill=(72, 64, 100, 255))
    ell(d, (56, 90, 104, 138), (240, 226, 132, 255), width=3)
    ell(d, (74, 106, 86, 122), (36, 30, 48, 255), outline=False)
    for i in range(4):
        y = 160 + i * 22
        d.line((36, y, 124, y), fill=(36, 32, 54, 255), width=4)
    img.save(os.path.join(DIR_PROPS, "monolith.png"))


# ---- 背包物品图标：安眠药（128x128，场景内拾取物与背包图标共用） -----------
def build_pills() -> None:
    img, d = canvas(128, 128)
    rr(d, (36, 34, 92, 118), 10, (224, 138, 64, 255))      # 药瓶
    rr(d, (36, 34, 92, 62), 10, (206, 118, 50, 255))       # 瓶肩阴影
    rr(d, (32, 12, 96, 42), 6, (250, 246, 238, 255))       # 瓶盖
    d.rectangle((32, 34, 96, 40), fill=(196, 190, 180, 255))
    rr(d, (42, 66, 86, 106), 4, (246, 242, 232, 255))      # 标签
    d.rectangle((48, 74, 80, 80), fill=(110, 84, 60, 255))  # 标签字（占位横线）
    d.rectangle((48, 88, 72, 93), fill=(160, 150, 140, 255))
    ell(d, (56, 96, 68, 104), (96, 84, 160, 255), width=2)  # 深梦月牙徽记
    img.save(os.path.join(DIR_PROPS, "pills.png"))


# ---- 第二层轨道世界：保安室外观（480x520，正面关着：亮窗 + 白门） ----------
def build_booth() -> None:
    img, d = canvas(480, 520)
    # 主体箱体（关着的正面）
    rr(d, (20, 40, 460, 504), 10, (66, 74, 88, 255))
    rr(d, (34, 56, 446, 490), 8, (90, 100, 116, 255))
    # 屋檐
    rr(d, (4, 14, 476, 62), 8, (40, 46, 58, 255))
    # 门牌（占位横线）
    rr(d, (70, 78, 230, 108), 4, (222, 226, 234, 255))
    d.rectangle((86, 88, 214, 94), fill=(50, 56, 68, 255))
    d.rectangle((86, 98, 190, 102), fill=(50, 56, 68, 255))
    # 亮灯的窗（左侧）
    rr(d, (56, 130, 240, 290), 8, (36, 40, 50, 255))
    rr(d, (68, 142, 228, 278), 6, (216, 202, 150, 255))
    d.rectangle((144, 142, 152, 278), fill=(36, 40, 50, 255))
    d.rectangle((68, 206, 228, 214), fill=(36, 40, 50, 255))
    # 白色的门（右侧下方，通往保安室内部；位置与 .tscn 交互区对应）
    rr(d, (300, 210, 424, 490), 6, (150, 150, 158, 255))
    rr(d, (312, 222, 412, 478), 4, (238, 236, 230, 255))
    rr(d, (324, 238, 400, 330), 4, (206, 204, 198, 255))
    rr(d, (324, 348, 400, 462), 4, (206, 204, 198, 255))
    ell(d, (392, 356, 408, 372), (216, 180, 106, 255), width=3)
    img.save(os.path.join(DIR_PROPS, "booth.png"))


# ---- 白色的门（140x230，保安室内部的出口门） ------------------------------
def build_door_white() -> None:
    img, d = canvas(140, 230)
    rr(d, (0, 0, 140, 230), 8, (150, 150, 158, 255))      # 门框
    rr(d, (12, 10, 128, 220), 6, (238, 236, 230, 255))    # 白门
    rr(d, (26, 28, 114, 116), 4, (216, 214, 208, 255))    # 上门芯
    rr(d, (26, 132, 114, 204), 4, (216, 214, 208, 255))   # 下门芯
    ell(d, (104, 112, 122, 130), (216, 180, 106, 255), width=3)
    img.save(os.path.join(DIR_PROPS, "door_white.png"))


# ---- 背包物品图标：手枪（128x128，场景拾取物与背包图标共用） ----------------
def build_pistol() -> None:
    img, d = canvas(128, 128)
    # 枪身（指向右侧）
    rr(d, (14, 38, 112, 62), 6, (58, 60, 70, 255))
    rr(d, (14, 40, 110, 50), 4, (84, 88, 100, 255))       # 顶部高光
    d.rectangle((104, 44, 116, 56), fill=(30, 30, 38, 255))  # 枪口
    # 握把（向左下）
    d.polygon([(30, 60), (58, 60), (46, 112), (20, 112)], fill=(48, 50, 60, 255))
    d.polygon([(34, 66), (52, 66), (43, 104), (27, 104)], fill=(70, 74, 86, 255))
    # 扳机护圈
    d.arc((52, 58, 76, 84), start=20, end=180, fill=(30, 30, 38, 255), width=5)
    # 击锤
    d.polygon([(16, 36), (28, 36), (24, 46), (14, 44)], fill=(30, 30, 38, 255))
    img.save(os.path.join(DIR_PROPS, "pistol.png"))


# ---- 第二层·保安室内部背景（1920x1080，单屏房间） -------------------------
def build_security_room_bg() -> None:
    wall_bottom = 470
    img, d = canvas(ROOM_W, ROOM_H)
    # 墙：钢灰蓝 + 面板缝
    vgradient(d, 0, 0, ROOM_W, wall_bottom, (76, 84, 98), (54, 60, 74))
    for x in range(0, ROOM_W, 320):
        d.line((x, 0, x, wall_bottom), fill=(44, 50, 62, 255), width=4)
    d.line((0, 240, ROOM_W, 240), fill=(44, 50, 62, 255), width=4)
    # 带铁栏的值班窗（左上，夜色）
    rr(d, (240, 100, 560, 320), 8, (36, 40, 50, 255))
    vgradient(d, 252, 112, 548, 308, (28, 32, 52), (54, 46, 82))
    for bx in range(300, 540, 80):
        d.rectangle((bx, 112, bx + 8, 308), fill=(36, 40, 50, 255))
    d.rectangle((252, 204, 548, 212), fill=(36, 40, 50, 255))
    # 公告板（右上，占位横线当文字）
    rr(d, (1240, 110, 1660, 330), 8, (58, 62, 60, 255))
    d.rectangle((1256, 126, 1644, 314), fill=(214, 210, 196, 255))
    for i in range(6):
        y = 150 + i * 28
        d.rectangle((1276, y, 1276 + random.randint(120, 320), y + 10), fill=(120, 116, 108, 255))
    # 地面：水泥格子
    d.rectangle((0, wall_bottom, ROOM_W, ROOM_H), fill=(56, 56, 66, 255))
    d.rectangle((0, wall_bottom, ROOM_W, wall_bottom + 8), fill=(74, 74, 86, 255))
    for x in range(0, ROOM_W + 1, 240):
        d.line((x, wall_bottom, x, ROOM_H), fill=(44, 44, 54, 255), width=4)
    for y in range(wall_bottom + 90, ROOM_H, 90):
        d.line((0, y, ROOM_W, y), fill=(44, 44, 54, 255), width=4)
    # 污渍
    for _ in range(60):
        cx = random.randint(0, ROOM_W)
        cy = random.randint(wall_bottom + 10, ROOM_H - 10)
        r = random.randint(10, 40)
        d.ellipse((cx - r, cy - r // 2, cx + r, cy + r // 2), fill=(48, 48, 58, 255))
    img.save(os.path.join(DIR_BG, "bg_security_room.png"))


# --------------------------------------------------------------------------
# 背景
# --------------------------------------------------------------------------
ROOM_W, ROOM_H = 1920, 1080
WALL_BOTTOM = 470


def _draw_window(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int,
                 sky_top, sky_bottom, moon, stars: bool) -> None:
    rr(d, (x0, y0, x1, y1), 8, WOOD_DARK)
    ix0, iy0, ix1, iy1 = x0 + 16, y0 + 16, x1 - 16, y1 - 16
    vgradient(d, ix0, iy0, ix1, iy1, sky_top, sky_bottom)
    d.rectangle((ix0, iy0, ix1, iy1), outline=WOOD_DARK, width=6)
    if stars:
        for _ in range(46):
            sx = random.randint(ix0 + 6, ix1 - 6)
            sy = random.randint(iy0 + 6, iy1 - 40)
            r = random.choice([2, 2, 3])
            d.ellipse((sx - r, sy - r, sx + r, sy + r), fill=(238, 240, 255, 255))
    mx = ix1 - 110
    ell(d, (mx, iy0 + 26, mx + 62, iy0 + 88), moon, width=3)
    # 窗框十字
    mid_x = (ix0 + ix1) // 2
    mid_y = (iy0 + iy1) // 2
    d.line((mid_x, iy0, mid_x, iy1), fill=WOOD_DARK, width=8)
    d.line((ix0, mid_y, ix1, mid_y), fill=WOOD_DARK, width=8)


def _draw_wood_floor(d: ImageDraw.ImageDraw, top: int, base, dark) -> None:
    d.rectangle((0, top, ROOM_W, ROOM_H), fill=base)
    plank_h = 92
    y = top
    while y < ROOM_H:
        d.line((0, y, ROOM_W, y), fill=dark, width=3)
        offset = ((y - top) // plank_h) % 2
        x = offset * 190
        while x < ROOM_W:
            d.line((x, y, x, min(y + plank_h, ROOM_H)), fill=dark, width=3)
            x += 380
        y += plank_h
    d.rectangle((0, top - 8, ROOM_W, top + 6), fill=(74, 52, 36, 255))


def build_bedroom_bg(filename: str, wall_top, wall_bottom, floor_base, floor_dark,
                     sky_top, sky_bottom, moon, stars: bool, specks=None) -> None:
    img, d = canvas(ROOM_W, ROOM_H)
    vgradient(d, 0, 0, ROOM_W, WALL_BOTTOM, wall_top, wall_bottom)
    _draw_wood_floor(d, WALL_BOTTOM, floor_base, floor_dark)
    _draw_window(d, 760, 96, 1160, 336, sky_top, sky_bottom, moon, stars)
    if specks is not None:
        for _ in range(70):
            sx = random.randint(0, ROOM_W)
            sy = random.randint(WALL_BOTTOM, ROOM_H)
            r = random.choice([2, 3, 4])
            d.ellipse((sx - r, sy - r, sx + r, sy + r), fill=specks)
    img.save(os.path.join(DIR_BG, filename))


# ---- 梦境世界（门后的世界） -------------------------------------------------
WORLD_W, WORLD_H = 2880, 1620

OBSTACLES = [
    (340, 360, 300, 150),
    (2050, 320, 340, 160),
    (760, 1180, 360, 160),
    (1780, 1240, 320, 150),
    (1300, 700, 180, 320),
]


def build_dream_world_bg() -> None:
    img, d = canvas(WORLD_W, WORLD_H)
    vgradient(d, 0, 0, WORLD_W, WORLD_H, (74, 124, 116), (47, 88, 86))

    # 草地色块
    for _ in range(260):
        cx = random.randint(0, WORLD_W)
        cy = random.randint(0, WORLD_H)
        rw = random.randint(60, 220)
        rh = random.randint(40, 130)
        color = random.choice([(82, 136, 124, 255), (58, 100, 96, 255), (92, 148, 130, 255)])
        d.ellipse((cx - rw, cy - rh, cx + rw, cy + rh), fill=color)

    # 土路
    d.rectangle((0, 700, WORLD_W, 860), fill=(106, 91, 71, 255))
    d.rectangle((0, 700, WORLD_W, 712), fill=(122, 106, 84, 255))
    d.rectangle((0, 848, WORLD_W, 860), fill=(84, 72, 56, 255))
    d.rectangle((1900, 0, 2040, WORLD_H), fill=(106, 91, 71, 255))
    d.rectangle((1900, 0, 1912, WORLD_H), fill=(122, 106, 84, 255))
    d.rectangle((2028, 0, 2040, WORLD_H), fill=(84, 72, 56, 255))

    # 障碍块（与 .tscn 中的碰撞矩形一一对应）
    for ox, oy, ow, oh in OBSTACLES:
        rr(d, (ox, oy, ox + ow, oy + oh), 12, (38, 34, 54, 255))
        d.rectangle((ox + 10, oy + 10, ox + ow - 10, oy + 34), fill=(76, 68, 104, 255))
        for i in range(3):
            ly = oy + 60 + i * ((oh - 70) // 3)
            d.line((ox + 16, ly, ox + ow - 16, ly), fill=(28, 25, 42, 255), width=4)

    # 草丛与光点
    for _ in range(220):
        gx = random.randint(40, WORLD_W - 40)
        gy = random.randint(40, WORLD_H - 40)
        for _ in range(4):
            d.line((gx, gy, gx + random.randint(-9, 9), gy - random.randint(10, 22)),
                   fill=(36, 76, 68, 255), width=3)
    for _ in range(120):
        px = random.randint(0, WORLD_W)
        py = random.randint(0, WORLD_H)
        r = random.choice([3, 4, 5])
        d.ellipse((px - r, py - r, px + r, py + r), fill=(214, 238, 255, 210))

    # 传送门落脚点的地面纹样
    d.ellipse((1440 - 190, 1480 - 90, 1440 + 190, 1480 + 90), outline=(196, 156, 236, 255), width=8)
    d.ellipse((1440 - 130, 1480 - 60, 1440 + 130, 1480 + 60), outline=(196, 156, 236, 160), width=6)

    # 边缘虚空
    border = 70
    d.rectangle((0, 0, WORLD_W, border), fill=(18, 14, 28, 255))
    d.rectangle((0, WORLD_H - border, WORLD_W, WORLD_H), fill=(18, 14, 28, 255))
    d.rectangle((0, 0, border, WORLD_H), fill=(18, 14, 28, 255))
    d.rectangle((WORLD_W - border, 0, WORLD_W, WORLD_H), fill=(18, 14, 28, 255))

    img.save(os.path.join(DIR_BG, "bg_dream_world.png"))


# ---- 主通道（Nexus）用门：彩色门 -------------------------------------------
def build_colored_door(filename: str, body, panel) -> None:
    img, d = canvas(160, 260)
    rr(d, (0, 0, 160, 260), 10, body)
    rr(d, (14, 14, 146, 246), 8, panel)
    rr(d, (32, 34, 128, 132), 6, body)
    rr(d, (32, 148, 128, 240), 6, body)
    ell(d, (112, 120, 138, 142), (242, 228, 152, 255), width=3)
    img.save(os.path.join(DIR_PROPS, filename))


# ---- 流星世界 -------------------------------------------------------------
def build_meteor() -> None:
    img, d = canvas(96, 320)
    # 拖尾（越往上越淡）
    for i in range(30):
        t = i / 29.0
        alpha = int(170 * (1.0 - t) ** 1.6)
        half_w = int(3 + 34 * t)
        y = int(8 + t * 206)
        d.line((48 - half_w, y, 48 + half_w, y), fill=(255, 206, 128, alpha), width=3)
    # 亮核
    ell(d, (16, 208, 80, 278), (255, 246, 206, 255), width=5)
    d.ellipse((26, 218, 70, 268), fill=(255, 168, 62, 255))
    img.save(os.path.join(DIR_PROPS, "meteor.png"))


def build_meteor_world_bg() -> None:
    img, d = canvas(WORLD_W, WORLD_H)
    vgradient(d, 0, 0, WORLD_W, WORLD_H, (42, 34, 68), (16, 12, 28))

    for _ in range(220):
        cx = random.randint(0, WORLD_W)
        cy = random.randint(0, WORLD_H)
        rw = random.randint(70, 260)
        rh = random.randint(50, 170)
        color = random.choice([(48, 38, 78, 255), (28, 22, 48, 255), (58, 46, 92, 255)])
        d.ellipse((cx - rw, cy - rh, cx + rw, cy + rh), fill=color)

    # 陨石坑
    for _ in range(34):
        cx = random.randint(100, WORLD_W - 100)
        cy = random.randint(100, WORLD_H - 100)
        rw = random.randint(60, 150)
        rh = random.randint(38, 92)
        ell(d, (cx - rw, cy - rh, cx + rw, cy + rh), (78, 62, 108, 255), width=6)
        d.ellipse((cx - int(rw * 0.66), cy - int(rh * 0.62),
                   cx + int(rw * 0.66), cy + int(rh * 0.62)), fill=(22, 16, 34, 255))
        d.ellipse((cx - int(rw * 0.3), cy - int(rh * 0.26),
                   cx + int(rw * 0.3), cy + int(rh * 0.26)), fill=(104, 72, 48, 255))

    # 发光矿脉
    for _ in range(70):
        x = random.randint(0, WORLD_W)
        y = random.randint(0, WORLD_H)
        r = random.choice([3, 4, 6])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(216, 170, 255, 205))

    border = 70
    d.rectangle((0, 0, WORLD_W, border), fill=(14, 10, 22, 255))
    d.rectangle((0, WORLD_H - border, WORLD_W, WORLD_H), fill=(14, 10, 22, 255))
    d.rectangle((0, 0, border, WORLD_H), fill=(14, 10, 22, 255))
    d.rectangle((WORLD_W - border, 0, WORLD_W, WORLD_H), fill=(14, 10, 22, 255))

    img.save(os.path.join(DIR_BG, "bg_meteor_world.png"))


# ---- 深林世界 -------------------------------------------------------------
def build_tree() -> None:
    img, d = canvas(260, 380)
    # 树干
    rr(d, (106, 180, 154, 372), 14, (62, 44, 30, 255))
    rr(d, (92, 296, 122, 372), 8, (46, 32, 22, 255))
    rr(d, (138, 296, 168, 372), 8, (46, 32, 22, 255))
    # 树冠三层
    ell(d, (6, 6, 254, 192), (26, 60, 32, 255), width=6)
    ell(d, (24, 46, 236, 234), (40, 84, 46, 255), width=5)
    ell(d, (46, 96, 214, 302), (54, 102, 58, 255), width=5)
    d.ellipse((72, 62, 138, 128), fill=(76, 132, 78, 255))
    d.ellipse((150, 130, 196, 178), fill=(70, 122, 72, 255))
    img.save(os.path.join(DIR_PROPS, "tree.png"))


# ---- 深林世界（与轨道世界同宽：5760x1620） ---------------------------------
def build_deep_forest_bg() -> None:
    w, h = 5760, 1620
    img, d = canvas(w, h)
    vgradient(d, 0, 0, w, h, (36, 62, 42), (14, 28, 20))

    for _ in range(460):
        cx = random.randint(0, w)
        cy = random.randint(0, h)
        rw = random.randint(90, 300)
        rh = random.randint(60, 190)
        color = random.choice([(26, 50, 32, 255), (18, 38, 24, 255), (42, 72, 48, 255)])
        d.ellipse((cx - rw, cy - rh, cx + rw, cy + rh), fill=color)

    # 林间小径（横穿 + 纵穿，交点在传送门附近）
    d.rectangle((0, 780, w, 940), fill=(58, 44, 30, 255))
    d.rectangle((0, 780, w, 798), fill=(76, 58, 40, 255))
    d.rectangle((0, 922, w, 940), fill=(44, 32, 22, 255))
    d.rectangle((2800, 0, 2960, h), fill=(58, 44, 30, 255))
    d.rectangle((2800, 0, 2818, h), fill=(76, 58, 40, 255))
    d.rectangle((2942, 0, 2960, h), fill=(44, 32, 22, 255))

    # 灌木与蕨类
    for _ in range(520):
        bx = random.randint(30, w - 30)
        by = random.randint(30, h - 30)
        for _ in range(5):
            d.line((bx, by, bx + random.randint(-14, 14), by - random.randint(14, 34)),
                   fill=(48, 92, 54, 255), width=4)

    # 透过树叶的光斑
    for _ in range(190):
        x = random.randint(0, w)
        y = random.randint(0, h)
        r = random.choice([4, 6, 8])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(198, 246, 172, 150))

    # 传送门落脚点的地面纹样（底部中央）
    d.ellipse((2880 - 190, 1480 - 90, 2880 + 190, 1480 + 90), outline=(196, 156, 236, 255), width=8)
    d.ellipse((2880 - 130, 1480 - 60, 2880 + 130, 1480 + 60), outline=(196, 156, 236, 160), width=6)

    border = 70
    d.rectangle((0, 0, w, border), fill=(12, 20, 14, 255))
    d.rectangle((0, h - border, w, h), fill=(12, 20, 14, 255))
    d.rectangle((0, 0, border, h), fill=(12, 20, 14, 255))
    d.rectangle((w - border, 0, w, h), fill=(12, 20, 14, 255))

    img.save(os.path.join(DIR_BG, "bg_deep_forest.png"))


# ---- 第二层轨道世界（5760x1620，左端悬崖、右端保安室） ---------------------
RAIL_W, RAIL_H = 5760, 1620
RAIL_GROUND_TOP = 940
RAIL_TRACKS = (1030, 1160, 1290)
CLIFF_VOID_RIGHT = 292      # 悬崖深渊的右边缘（与 .tscn 悬崖墙 x=60±40 大体对应）
BOOTH_PAD = (5100, 1120, 5700, 1330)   # 保安室下的水泥台（booth 立绘 5160,600 起 480x520）


def build_rail_world_bg() -> None:
    img, d = canvas(RAIL_W, RAIL_H)
    # 夜空：钢蓝渐变
    vgradient(d, 0, 0, RAIL_W, RAIL_H, (32, 36, 56), (12, 13, 22))
    # 星
    for _ in range(260):
        x = random.randint(0, RAIL_W)
        y = random.randint(0, 880)
        r = random.choice([2, 2, 3])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(206, 216, 238, 190))
    # 远处城市剪影
    x = 0
    while x < RAIL_W:
        w = random.randint(60, 180)
        h = random.randint(60, 240)
        d.rectangle((x, RAIL_GROUND_TOP - h, x + w, RAIL_GROUND_TOP), fill=(20, 22, 34, 255))
        for _ in range(random.randint(2, 8)):
            wx = random.randint(x + 8, max(x + 10, x + w - 12))
            wy = random.randint(RAIL_GROUND_TOP - h + 10, RAIL_GROUND_TOP - 14)
            d.rectangle((wx, wy, wx + 6, wy + 9), fill=(190, 196, 170, 130))
        x += w + random.randint(20, 90)

    # 地面（道砟带）
    d.rectangle((0, RAIL_GROUND_TOP, RAIL_W, RAIL_H), fill=(34, 32, 40, 255))
    d.rectangle((0, RAIL_GROUND_TOP, RAIL_W, RAIL_GROUND_TOP + 12), fill=(54, 52, 64, 255))
    for _ in range(1100):
        gx = random.randint(0, RAIL_W)
        gy = random.randint(RAIL_GROUND_TOP + 14, RAIL_H - 70)
        r = random.choice([2, 3, 4])
        c = random.choice([(58, 56, 68, 255), (44, 42, 54, 255), (70, 66, 80, 255)])
        d.ellipse((gx - r, gy - r, gx + r, gy + r), fill=c)

    # 三条铁轨（轨枕 + 双钢轨）
    for ty in RAIL_TRACKS:
        for x in range(0, RAIL_W, 90):
            d.rectangle((x, ty - 34, x + 46, ty + 34), fill=(56, 42, 32, 255))
            d.rectangle((x, ty - 34, x + 46, ty - 26), fill=(72, 55, 41, 255))
        d.rectangle((0, ty - 42, RAIL_W, ty - 28), fill=(118, 124, 138, 255))
        d.rectangle((0, ty - 42, RAIL_W, ty - 38), fill=(164, 170, 186, 255))
        d.rectangle((0, ty + 28, RAIL_W, ty + 42), fill=(118, 124, 138, 255))
        d.rectangle((0, ty + 28, RAIL_W, ty + 32), fill=(164, 170, 186, 255))

    # 电线杆剪影
    for x in range(500, RAIL_W - 200, 720):
        d.rectangle((x, 430, x + 16, RAIL_GROUND_TOP), fill=(16, 16, 24, 255))
        d.rectangle((x - 64, 430, x + 80, 444), fill=(16, 16, 24, 255))
        d.rectangle((x - 48, 468, x + 64, 478), fill=(16, 16, 24, 255))

    # 保安室水泥台
    px0, py0, px1, py1 = BOOTH_PAD
    d.rectangle((px0, py0, px1, py1), fill=(56, 56, 66, 255))
    d.rectangle((px0, py0, px1, py0 + 10), fill=(74, 74, 86, 255))
    d.rectangle((px0 + 40, py1 - 16, px1 - 40, py1), fill=(40, 40, 48, 255))

    # 左端悬崖：地面与铁轨一起断裂进深渊
    d.rectangle((0, 0, CLIFF_VOID_RIGHT, RAIL_H), fill=(6, 6, 11, 255))
    y = RAIL_GROUND_TOP - 60
    while y < RAIL_H:
        step = random.randint(48, 88)
        d.rectangle((CLIFF_VOID_RIGHT, y, CLIFF_VOID_RIGHT + random.randint(20, 52), y + step),
                    fill=(22, 21, 30, 255))
        y += step
    # 悬崖警示柱（黄黑条纹）
    d.rectangle((RAIL_W * 0 + 400, 986, 416, 1120), fill=(30, 28, 36, 255))
    for i in range(5):
        sy = 990 + i * 26
        color = (232, 196, 84, 255) if i % 2 == 0 else (36, 34, 42, 255)
        d.rectangle((400, sy, 416, sy + 26), fill=color)

    # 边缘虚空（除左端悬崖外）
    border = 70
    d.rectangle((0, 0, RAIL_W, border), fill=(10, 10, 18, 255))
    d.rectangle((0, RAIL_H - border, RAIL_W, RAIL_H), fill=(10, 10, 18, 255))
    d.rectangle((RAIL_W - border, 0, RAIL_W, RAIL_H), fill=(10, 10, 18, 255))

    img.save(os.path.join(DIR_BG, "bg_rail_world.png"))


# ---- 背包物品图标：麻醉剂（128x128，场景拾取物与背包图标共用） -------------
def build_anesthetic() -> None:
    img, d = canvas(128, 128)
    # 斜放的注射器
    d.line((30, 98, 86, 42), fill=(196, 208, 222, 255), width=14)
    d.line((34, 94, 82, 46), fill=(150, 200, 226, 255), width=8)
    d.polygon([(86, 42), (96, 32), (104, 40), (94, 50)], fill=(160, 164, 176, 255))  # 针座
    d.line((100, 36, 112, 24), fill=(220, 224, 232, 255), width=4)                   # 针头
    d.rectangle((20, 92, 44, 116), fill=(96, 100, 112, 255))                          # 推杆
    # 小药瓶
    rr(d, (86, 84, 118, 118), 6, (150, 170, 200, 255))
    rr(d, (88, 78, 116, 92), 4, (220, 224, 232, 255))
    img.save(os.path.join(DIR_PROPS, "anesthetic.png"))


# ---- 第四层海洋：漂在海面上的书页（120x84，无碰撞） ------------------------
def build_page() -> None:
    img, d = canvas(120, 84)
    d.polygon([(8, 6), (112, 2), (116, 76), (4, 80)], fill=(240, 238, 228, 255))   # 纸面（微歪）
    d.polygon([(8, 6), (112, 2), (110, 10), (10, 14)], fill=(222, 218, 206, 255))  # 上缘折痕
    for i in range(4):
        y = 24 + i * 14
        d.line((20, y, 100 - random.randint(0, 18), y + 2), fill=(150, 168, 190, 200), width=3)
    d.line((16, 74, 60, 76), fill=(150, 168, 190, 160), width=3)
    img.save(os.path.join(DIR_PROPS, "page.png"))


# ---- 背包物品图标：电瓶车（128x128） ---------------------------------------
def build_scooter_icon() -> None:
    img, d = canvas(128, 128)
    rr(d, (30, 46, 96, 70), 10, (150, 96, 96, 255))        # 车身
    rr(d, (58, 30, 96, 52), 8, (120, 76, 76, 255))         # 座垫
    d.line((30, 52, 16, 84), fill=(70, 70, 80, 255), width=6)   # 前立管
    d.line((16, 84, 10, 40), fill=(70, 70, 80, 255), width=5)   # 把手
    ell(d, (28, 96, 56, 122), (40, 40, 48, 255), width=5)       # 前轮
    ell(d, (76, 96, 104, 122), (40, 40, 48, 255), width=5)      # 后轮
    img.save(os.path.join(DIR_PROPS, "scooter.png"))


# ---- 大街世界：救护车（440x300） -------------------------------------------
def build_ambulance() -> None:
    img, d = canvas(440, 300)
    rr(d, (8, 60, 430, 250), 16, (232, 234, 238, 255))     # 车身
    rr(d, (250, 60, 430, 170), 14, (214, 220, 230, 255))   # 驾驶舱
    rr(d, (280, 84, 380, 140), 8, (120, 160, 200, 255))    # 挡风玻璃
    rr(d, (40, 100, 220, 190), 8, (196, 200, 208, 255))    # 侧舱门
    d.rectangle((40, 150, 220, 158), fill=(196, 74, 66, 255))   # 红条
    rr(d, (100, 108, 150, 140), 4, (196, 74, 66, 255))     # 红十字（横）
    rr(d, (116, 92, 134, 156), 4, (196, 74, 66, 255))      # 红十字（竖）
    rr(d, (170, 20, 300, 52), 10, (226, 228, 232, 255))    # 顶灯箱
    ell(d, (190, 28, 216, 46), (226, 96, 84, 255), width=3)
    ell(d, (252, 28, 278, 46), (120, 168, 214, 255), width=3)
    ell(d, (100, 236, 156, 292), (32, 32, 40, 255), width=8)   # 后轮
    ell(d, (300, 236, 356, 292), (32, 32, 40, 255), width=8)   # 前轮
    img.save(os.path.join(DIR_PROPS, "ambulance.png"))


# ---- 大街世界：电瓶车（220x150，场景内可拾取的道具车） ---------------------
def build_scooter() -> None:
    img, d = canvas(220, 150)
    rr(d, (56, 40, 168, 78), 16, (162, 104, 104, 255))     # 车身
    rr(d, (104, 22, 166, 48), 12, (128, 82, 82, 255))      # 座垫
    d.line((58, 58, 34, 96), fill=(70, 70, 80, 255), width=8)   # 前立管
    d.line((34, 96, 24, 44), fill=(70, 70, 80, 255), width=6)   # 把手立杆
    d.line((14, 44, 44, 40), fill=(60, 60, 70, 255), width=5)   # 把手
    ell(d, (52, 108, 96, 148), (34, 34, 42, 255), width=7)      # 前轮
    ell(d, (136, 108, 180, 148), (34, 34, 42, 255), width=7)    # 后轮
    d.rectangle((150, 70, 168, 96), fill=(90, 90, 100, 255))    # 后架
    img.save(os.path.join(DIR_PROPS, "scooter_world.png"))


# ---- 医院内部：长椅（280x170）与接诊台（440x220） --------------------------
def build_bench() -> None:
    img, d = canvas(280, 170)
    rr(d, (6, 20, 274, 70), 10, (110, 128, 150, 255))      # 靠背
    rr(d, (0, 76, 280, 118), 10, (130, 148, 170, 255))     # 座面
    d.rectangle((18, 112, 40, 164), fill=(80, 92, 110, 255))
    d.rectangle((240, 112, 262, 164), fill=(80, 92, 110, 255))
    img.save(os.path.join(DIR_PROPS, "bench.png"))


def build_reception() -> None:
    img, d = canvas(440, 220)
    # 半月形台面
    d.ellipse((10, 40, 430, 200), fill=(198, 202, 210, 255))
    d.ellipse((40, 66, 400, 186), fill=(226, 228, 234, 255))
    rr(d, (30, 120, 410, 210), 14, (170, 174, 184, 255))   # 台体
    d.rectangle((30, 120, 410, 140), fill=(198, 202, 210, 255))
    # 台面上的终端
    rr(d, (180, 88, 260, 128), 6, (60, 64, 76, 255))
    rr(d, (188, 94, 252, 122), 4, (120, 170, 214, 255))
    img.save(os.path.join(DIR_PROPS, "reception.png"))


# ---- 医院内部：NPC（96x160，长袍小人，会随机走动） ------------------------
def build_npc() -> None:
    img, d = canvas(96, 160)
    ell(d, (28, 6, 68, 44), (238, 222, 200, 255))          # 头
    d.polygon([(48, 40), (76, 150), (20, 150)], fill=(96, 104, 128, 255))   # 长袍
    d.polygon([(48, 40), (62, 150), (34, 150)], fill=(112, 120, 146, 255))
    ell(d, (38, 20, 46, 28), (40, 40, 50, 255), outline=False)   # 眼
    ell(d, (54, 20, 62, 28), (40, 40, 50, 255), outline=False)
    img.save(os.path.join(DIR_PROPS, "npc.png"))


# ---- 大街背景（3840x1620：沿街楼群 + 斑马线 + 右端悬崖） -------------------
STREET_W, STREET_H = 3840, 1620
STREET_ROAD_TOP = 700
STREET_ROAD_BOTTOM = 1450
STREET_CROSSWALKS = (960, 2400)
STREET_CLIFF_RIGHT = 3620


def build_street_bg() -> None:
    img, d = canvas(STREET_W, STREET_H)
    # 夜空
    vgradient(d, 0, 0, STREET_W, STREET_H, (30, 34, 54), (14, 15, 26))
    for _ in range(200):
        x = random.randint(0, STREET_W)
        y = random.randint(0, 560)
        r = random.choice([2, 2, 3])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(206, 216, 238, 180))
    # 沿街楼群（高矮错落，亮窗）
    x = 0
    while x < STREET_W:
        w = random.randint(160, 320)
        h = random.randint(360, 660)
        body = random.choice([(64, 70, 88, 255), (74, 80, 98, 255), (56, 60, 78, 255)])
        d.rectangle((x, STREET_ROAD_TOP - h, x + w, STREET_ROAD_TOP), fill=body)
        d.rectangle((x, STREET_ROAD_TOP - h, x + w, STREET_ROAD_TOP - h + 12), fill=(40, 44, 58, 255))
        wy = STREET_ROAD_TOP - h + 40
        while wy < STREET_ROAD_TOP - 50:
            wx = x + 24
            while wx < x + w - 40:
                if random.random() < 0.6:
                    d.rectangle((wx, wy, wx + 26, wy + 20), fill=(226, 196, 120, 220))
                else:
                    d.rectangle((wx, wy, wx + 26, wy + 20), fill=(38, 42, 56, 255))
                wx += 52
            wy += 46
        x += w + random.randint(30, 90)
    # 人行道 + 马路
    d.rectangle((0, STREET_ROAD_TOP, STREET_W, STREET_ROAD_TOP + 46), fill=(84, 84, 96, 255))
    d.rectangle((0, STREET_ROAD_TOP + 46, STREET_W, STREET_ROAD_BOTTOM), fill=(46, 46, 54, 255))
    d.rectangle((0, STREET_ROAD_BOTTOM, STREET_W, STREET_ROAD_BOTTOM + 14), fill=(78, 78, 90, 255))
    # 车道中线（虚线）
    for x in range(0, STREET_W, 160):
        d.rectangle((x, 1060, x + 80, 1076), fill=(150, 150, 120, 200))
    # 斑马线
    for cx in STREET_CROSSWALKS:
        for i in range(6):
            d.rectangle((cx + i * 46, STREET_ROAD_TOP + 60, cx + i * 46 + 26, STREET_ROAD_BOTTOM - 60),
                        fill=(210, 212, 218, 210))
    # 路口下沿的医院入口牌坊区（右下角画一个入口通道示意）
    d.rectangle((1800, STREET_ROAD_BOTTOM, 2140, STREET_H), fill=(60, 60, 72, 255))
    d.rectangle((1800, STREET_ROAD_BOTTOM, 2140, STREET_ROAD_BOTTOM + 14), fill=(96, 96, 110, 255))
    # 碎石/杂点
    for _ in range(700):
        gx = random.randint(0, STREET_W)
        gy = random.randint(STREET_ROAD_TOP + 50, STREET_H - 40)
        r = random.choice([2, 3])
        c = random.choice([(58, 58, 68, 255), (40, 40, 50, 255)])
        d.ellipse((gx - r, gy - r, gx + r, gy + r), fill=c)
    # 右端悬崖（马路与楼群一起断进深渊）
    d.rectangle((STREET_CLIFF_RIGHT, 0, STREET_W, STREET_H), fill=(6, 6, 11, 255))
    y = STREET_ROAD_TOP - 60
    while y < STREET_H:
        step = random.randint(48, 88)
        d.rectangle((STREET_CLIFF_RIGHT, y, STREET_CLIFF_RIGHT + random.randint(20, 52), y + step),
                    fill=(22, 21, 30, 255))
        y += step
    # 边缘虚空（除右端悬崖外）
    border = 70
    d.rectangle((0, 0, STREET_W, border), fill=(10, 10, 18, 255))
    d.rectangle((0, STREET_H - border, STREET_W, STREET_H), fill=(10, 10, 18, 255))
    d.rectangle((0, 0, border, STREET_H), fill=(10, 10, 18, 255))
    img.save(os.path.join(DIR_BG, "bg_street.png"))


# ---- 医院外部背景（1920x1080：门诊楼 + 白门入口 + 前） ---------------------
def build_hospital_outside_bg() -> None:
    img, d = canvas(ROOM_W, ROOM_H)
    vgradient(d, 0, 0, ROOM_W, ROOM_H, (52, 56, 78), (26, 27, 44))
    for _ in range(120):
        x = random.randint(0, ROOM_W)
        y = random.randint(0, 380)
        r = random.choice([2, 2, 3])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(206, 216, 238, 170))
    # 门诊楼主体
    d.rectangle((0, 120, ROOM_W, 620), fill=(214, 216, 222, 255))
    d.rectangle((0, 120, ROOM_W, 150), fill=(190, 192, 200, 255))
    for row in range(2):
        for col in range(4):
            wx = 120 + col * 190
            wy = 200 + row * 150
            rr(d, (wx, wy, wx + 110, wy + 90), 6, (110, 140, 176, 255))
            rr(d, (ROOM_W - wx - 110, wy, ROOM_W - wx, wy + 90), 6, (110, 140, 176, 255))
    # 入口雨棚 + 红十字
    d.rectangle((700, 150, 1220, 220), fill=(226, 228, 232, 255))
    d.rectangle((760, 96, 1160, 150), fill=(206, 208, 214, 255))
    rr(d, (930, 40, 990, 104), 8, (196, 74, 66, 255))
    d.rectangle((900, 54, 1020, 90), fill=(196, 74, 66, 255))
    # 撑柱与玻璃门
    d.rectangle((740, 220, 770, 640), fill=(180, 182, 190, 255))
    d.rectangle((1150, 220, 1180, 640), fill=(180, 182, 190, 255))
    rr(d, (860, 400, 1060, 640), 6, (120, 160, 200, 255))
    d.rectangle((956, 400, 964, 640), fill=(90, 110, 140, 255))
    # 台阶与门前空地
    d.ellipse((240, 430, 1680, 900), fill=(120, 122, 134, 255))
    d.rectangle((640, 640, 1280, 700), fill=(196, 198, 206, 255))
    # 前方马路
    d.rectangle((0, 700, ROOM_W, ROOM_H), fill=(48, 48, 56, 255))
    d.rectangle((0, 700, ROOM_W, 714), fill=(80, 80, 92, 255))
    for x in range(0, ROOM_W, 180):
        d.rectangle((x, 900, x + 90, 916), fill=(150, 150, 120, 190))
    img.save(os.path.join(DIR_BG, "bg_hospital_outside.png"))


# ---- 医院内部背景（2880x1620：大厅 + 通道口 + 门） -------------------------
HOSPITAL_INSIDE_W, HOSPITAL_INSIDE_H = 2880, 1620
HOSPITAL_WALL_BOTTOM = 620


def build_hospital_inside_bg() -> None:
    img, d = canvas(HOSPITAL_INSIDE_W, HOSPITAL_INSIDE_H)
    # 上墙（淡绿白）
    vgradient(d, 0, 0, HOSPITAL_INSIDE_W, HOSPITAL_WALL_BOTTOM, (208, 216, 210), (176, 186, 182))
    d.line((0, HOSPITAL_WALL_BOTTOM - 8, HOSPITAL_INSIDE_W, HOSPITAL_WALL_BOTTOM - 8), fill=(120, 130, 126, 255), width=6)
    # 地面：方格地砖
    d.rectangle((0, HOSPITAL_WALL_BOTTOM, HOSPITAL_INSIDE_W, HOSPITAL_INSIDE_H), fill=(196, 200, 198, 255))
    tile = 160
    for gx in range(0, HOSPITAL_INSIDE_W + tile, tile):
        d.line((gx, HOSPITAL_WALL_BOTTOM, gx, HOSPITAL_INSIDE_H), fill=(172, 176, 174, 255), width=4)
    for gy in range(HOSPITAL_WALL_BOTTOM, HOSPITAL_INSIDE_H, tile):
        d.line((0, gy, HOSPITAL_INSIDE_W, gy), fill=(172, 176, 174, 255), width=4)
    # 3号通道（顶部中央的双开门洞）
    d.rectangle((1320, 60, 1560, HOSPITAL_WALL_BOTTOM), fill=(96, 104, 112, 255))
    d.rectangle((1340, 90, 1425, HOSPITAL_WALL_BOTTOM - 20), fill=(56, 60, 70, 255))
    d.rectangle((1455, 90, 1540, HOSPITAL_WALL_BOTTOM - 20), fill=(56, 60, 70, 255))
    # 2号通道（左墙开口）与 1号通道（右墙开口）
    d.rectangle((0, 780, 220, 1180), fill=(96, 104, 112, 255))
    d.rectangle((40, 820, 200, 1140), fill=(56, 60, 70, 255))
    d.rectangle((HOSPITAL_INSIDE_W - 220, 780, HOSPITAL_INSIDE_W, 1180), fill=(96, 104, 112, 255))
    d.rectangle((HOSPITAL_INSIDE_W - 200, 820, HOSPITAL_INSIDE_W - 40, 1140), fill=(56, 60, 70, 255))
    # 右侧两扇门（深色门框 + 门）
    for dx in (2120, 2440):
        rr(d, (dx, 240, dx + 170, HOSPITAL_WALL_BOTTOM), 8, (150, 154, 150, 255))
        rr(d, (dx + 16, 262, dx + 154, HOSPITAL_WALL_BOTTOM - 20), 6, (104, 88, 74, 255))
        ell(d, (dx + 132, 400, dx + 152, 420), (226, 190, 120, 255), width=3)
    # 底部入口（医院入口内视）
    d.rectangle((1300, HOSPITAL_INSIDE_H - 130, 1580, HOSPITAL_INSIDE_H), fill=(96, 104, 112, 255))
    d.rectangle((1330, HOSPITAL_INSIDE_H - 110, 1550, HOSPITAL_INSIDE_H), fill=(56, 60, 70, 255))
    # 导视牌（顶部左右）
    rr(d, (620, 140, 980, 220), 8, (222, 226, 232, 255))
    d.rectangle((648, 164, 952, 176), fill=(96, 120, 150, 255))
    rr(d, (1900, 140, 2260, 220), 8, (222, 226, 232, 255))
    d.rectangle((1928, 164, 2232, 176), fill=(96, 120, 150, 255))
    img.save(os.path.join(DIR_BG, "bg_hospital_inside.png"))


# ---- 第三层梦境：草地背景（2880x1620，明亮的草地与大树） ------------------
def build_grass_world_bg() -> None:
    img, d = canvas(WORLD_W, WORLD_H)
    vgradient(d, 0, 0, WORLD_W, WORLD_H, (110, 156, 96), (74, 116, 70))
    for _ in range(260):
        cx = random.randint(0, WORLD_W)
        cy = random.randint(0, WORLD_H)
        rw = random.randint(70, 240)
        rh = random.randint(50, 160)
        color = random.choice([(120, 168, 104, 255), (90, 130, 82, 255), (132, 176, 112, 255)])
        d.ellipse((cx - rw, cy - rh, cx + rw, cy + rh), fill=color)
    # 草丛
    for _ in range(300):
        gx = random.randint(30, WORLD_W - 30)
        gy = random.randint(30, WORLD_H - 30)
        for _ in range(4):
            d.line((gx, gy, gx + random.randint(-9, 9), gy - random.randint(12, 26)),
                   fill=(64, 104, 60, 255), width=3)
    # 远处小树剪影
    for _ in range(16):
        tx = random.randint(80, WORLD_W - 80)
        ty = random.randint(120, WORLD_H - 160)
        s = random.uniform(0.5, 0.8)
        ell(d, (tx - 60 * s, ty - 90 * s, tx + 60 * s, ty + 30 * s), (56, 96, 58, 255), width=4)
        d.rectangle((tx - 10 * s, ty + 20 * s, tx + 10 * s, ty + 60 * s), fill=(74, 56, 40, 255))
    # 光斑
    for _ in range(110):
        x = random.randint(0, WORLD_W)
        y = random.randint(0, WORLD_H)
        r = random.choice([3, 4, 6])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(228, 246, 190, 150))
    border = 70
    d.rectangle((0, 0, WORLD_W, border), fill=(26, 38, 26, 255))
    d.rectangle((0, WORLD_H - border, WORLD_W, WORLD_H), fill=(26, 38, 26, 255))
    d.rectangle((0, 0, border, WORLD_H), fill=(26, 38, 26, 255))
    d.rectangle((WORLD_W - border, 0, WORLD_W, WORLD_H), fill=(26, 38, 26, 255))
    img.save(os.path.join(DIR_BG, "bg_grass_world.png"))


# ---- 第三层·草原小屋外观（420x460，带烟囱） --------------------------------
def build_house() -> None:
    img, d = canvas(420, 460)
    rr(d, (30, 160, 390, 444), 10, (196, 168, 128, 255))        # 木墙
    for x in range(60, 390, 60):
        d.line((x, 170, x, 440), fill=(172, 146, 108, 255), width=4)
    d.polygon([(10, 170), (210, 40), (410, 170)], fill=(140, 96, 66, 255))   # 屋顶
    d.polygon([(10, 170), (210, 40), (210, 60), (40, 172)], fill=(120, 82, 58, 255))
    d.rectangle((298, 56, 340, 128), fill=(152, 92, 76, 255))    # 烟囱
    d.rectangle((290, 48, 348, 66), fill=(120, 74, 62, 255))
    rr(d, (172, 300, 250, 440), 6, (110, 78, 54, 255))           # 门
    ell(d, (232, 366, 244, 378), (226, 190, 120, 255), width=3)
    rr(d, (76, 220, 142, 284), 6, (172, 200, 222, 255))          # 窗
    d.rectangle((106, 220, 114, 284), fill=(120, 96, 66, 255))
    d.rectangle((76, 248, 142, 256), fill=(120, 96, 66, 255))
    img.save(os.path.join(DIR_PROPS, "house.png"))


# ---- 钓鱼的人（140x200） ----------------------------------------------------
def build_fisherman() -> None:
    img, d = canvas(140, 200)
    ell(d, (44, 20, 84, 60), (238, 222, 200, 255))               # 头
    rr(d, (34, 10, 94, 30), 10, (90, 120, 90, 255))              # 帽子
    rr(d, (38, 56, 102, 140), 12, (86, 110, 140, 255))           # 身体
    rr(d, (52, 132, 70, 190), 8, (60, 64, 78, 255))              # 腿
    rr(d, (76, 132, 94, 190), 8, (60, 64, 78, 255))
    d.line((96, 70, 136, 40), fill=(90, 70, 50, 255), width=5)   # 鱼竿
    d.line((136, 40, 134, 110), fill=(210, 214, 222, 255), width=2)  # 鱼线
    ell(d, (126, 108, 142, 122), (150, 170, 200, 255), width=3)  # 浮漂
    img.save(os.path.join(DIR_PROPS, "fisherman.png"))


# ---- 背包物品图标：书籍保护套（128x128） ------------------------------------
def build_book_sleeve() -> None:
    img, d = canvas(128, 128)
    rr(d, (26, 34, 96, 102), 8, (74, 110, 160, 255))             # 书（蓝封皮）
    d.rectangle((30, 38, 44, 98), fill=(56, 86, 128, 255))       # 书脊
    d.rectangle((54, 48, 90, 56), fill=(230, 234, 240, 200))     # 封面字条
    sleeve = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sleeve)
    sd.rounded_rectangle((16, 24, 106, 112), radius=10, fill=(200, 226, 244, 70))
    sd.rounded_rectangle((16, 24, 106, 112), radius=10, outline=(230, 244, 252, 200), width=4)
    sd.line((22, 44, 60, 24), fill=(240, 250, 255, 160), width=5)
    img.alpha_composite(sleeve)
    img.save(os.path.join(DIR_PROPS, "book_sleeve.png"))


# ---- 草原小屋内部背景（1920x1080：木屋 + 窗外草原） ------------------------
def build_grass_house_bg() -> None:
    img, d = canvas(ROOM_W, ROOM_H)
    wall_bottom = 470
    vgradient(d, 0, 0, ROOM_W, wall_bottom, (164, 134, 102), (132, 106, 80))
    for y in range(40, wall_bottom, 72):
        d.line((0, y, ROOM_W, y), fill=(120, 96, 72, 255), width=4)
    d.rectangle((0, wall_bottom - 8, ROOM_W, wall_bottom), fill=(104, 82, 60, 255))
    d.rectangle((0, wall_bottom, ROOM_W, ROOM_H), fill=(142, 112, 84, 255))
    plank_h = 92
    y = wall_bottom
    while y < ROOM_H:
        d.line((0, y, ROOM_W, y), fill=(116, 90, 66, 255), width=3)
        offset = ((y - wall_bottom) // plank_h) % 2
        x = offset * 190
        while x < ROOM_W:
            d.line((x, y, x, min(y + plank_h, ROOM_H)), fill=(116, 90, 66, 255), width=3)
            x += 380
        y += plank_h
    rr(d, (760, 96, 1160, 336), 8, (110, 84, 60, 255))
    vgradient(d, 776, 112, 1144, 320, (150, 190, 226), (120, 160, 108))
    d.ellipse((900, 150, 1010, 240), fill=(238, 232, 190, 255))
    for _ in range(8):
        gx = random.randint(800, 1110)
        gy = random.randint(240, 300)
        d.line((gx, gy, gx + random.randint(-8, 8), gy - 12), fill=(88, 128, 88, 255), width=3)
    d.rectangle((776, 208, 1144, 216), fill=(110, 84, 60, 255))
    d.rectangle((954, 112, 964, 320), fill=(110, 84, 60, 255))
    img.save(os.path.join(DIR_BG, "bg_grass_house.png"))


# ---- 白色的床（320x260） ----------------------------------------------------
def build_bed_white() -> None:
    img, d = canvas(320, 260)
    rr(d, (8, 6, 312, 76), 14, (222, 220, 216, 255))             # 床头板（白）
    rr(d, (14, 40, 306, 250), 12, (208, 206, 202, 255))          # 床架
    rr(d, (28, 52, 292, 210), 14, (244, 244, 246, 255))          # 床垫（白）
    rr(d, (28, 128, 292, 238), 16, (214, 218, 226, 255))         # 薄被
    d.rounded_rectangle((28, 128, 292, 150), radius=10, fill=(232, 234, 240, 255))
    rr(d, (66, 62, 254, 124), 16, (250, 250, 252, 255))          # 枕头
    img.save(os.path.join(DIR_PROPS, "bed_white.png"))


# ---- 医疗仪器（240x320，床边的监护设备） ------------------------------------
def build_machine() -> None:
    img, d = canvas(240, 320)
    rr(d, (30, 20, 210, 190), 10, (88, 96, 112, 255))            # 仪器头
    rr(d, (44, 34, 196, 120), 6, (24, 30, 26, 255))              # 屏幕
    d.arc((60, 50, 180, 110), start=180, end=360, fill=(120, 230, 150, 255), width=4)  # 波形
    for i in range(3):
        ell(d, (56 + i * 34, 140, 76 + i * 34, 160), (150, 160, 180, 255), width=3)
    d.rectangle((108, 190, 132, 284), fill=(70, 76, 90, 255))    # 支架
    rr(d, (60, 280, 180, 316), 8, (70, 76, 90, 255))             # 底座
    img.save(os.path.join(DIR_PROPS, "machine.png"))


# ---- 第四层梦境：海洋背景（2880x1620，全是水） -----------------------------
def build_ocean_bg() -> None:
    img, d = canvas(WORLD_W, WORLD_H)
    vgradient(d, 0, 0, WORLD_W, WORLD_H, (30, 66, 102), (10, 24, 46))
    for y in range(40, WORLD_H, 52):
        offset = random.randint(0, 130)
        for x in range(offset - 200, WORLD_W, 280):
            d.arc((x, y, x + 180, y + 30), start=200, end=340,
                  fill=(126, 176, 216, 80), width=4)
    for _ in range(7):
        x = random.randint(200, WORLD_W - 300)
        d.polygon([(x, 0), (x + 36, 0), (x + 130, WORLD_H), (x + 40, WORLD_H)],
                  fill=(182, 214, 242, 14))
    for _ in range(170):
        x = random.randint(0, WORLD_W)
        y = random.randint(0, WORLD_H)
        r = random.choice([2, 3, 4])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(204, 232, 250, 120))
    border = 70
    deep = (6, 14, 28, 255)
    d.rectangle((0, 0, WORLD_W, border), fill=deep)
    d.rectangle((0, WORLD_H - border, WORLD_W, WORLD_H), fill=deep)
    d.rectangle((0, 0, border, WORLD_H), fill=deep)
    d.rectangle((WORLD_W - border, 0, WORLD_W, WORLD_H), fill=deep)
    img.save(os.path.join(DIR_BG, "bg_ocean.png"))


def main() -> None:
    build_hero_sheet()
    build_bed()
    build_nightstand()
    build_desk()
    build_bookshelf()
    build_rug()
    build_door()
    build_portal()
    build_monolith()
    build_meteor()
    build_tree()
    build_pills()
    build_pistol()
    build_booth()
    build_door_white()
    build_security_room_bg()
    build_colored_door("door_red.png", (152, 62, 56, 255), (200, 98, 86, 255))
    build_colored_door("door_green.png", (56, 124, 74, 255), (94, 170, 108, 255))
    build_colored_door("door_blue.png", (56, 92, 144, 255), (94, 134, 196, 255))
    build_colored_door("door_yellow.png", (156, 134, 56, 255), (208, 182, 94, 255))

    # 现实卧室
    build_bedroom_bg(
        "bg_bedroom.png",
        wall_top=(186, 176, 202), wall_bottom=(158, 148, 178),
        floor_base=(138, 106, 74), floor_dark=(112, 84, 56),
        sky_top=(26, 35, 64), sky_bottom=(58, 72, 118),
        moon=(242, 234, 214), stars=True,
    )

    # 第一层梦境·卧室：同一布局，梦的配色
    build_bedroom_bg(
        "bg_dream_bedroom.png",
        wall_top=(80, 66, 116), wall_bottom=(56, 44, 88),
        floor_base=(86, 68, 102), floor_dark=(66, 50, 82),
        sky_top=(46, 20, 70), sky_bottom=(96, 46, 124),
        moon=(228, 202, 252), stars=False, specks=(196, 168, 240, 120),
    )

    build_dream_world_bg()
    build_meteor_world_bg()
    build_deep_forest_bg()
    build_rail_world_bg()
    build_street_bg()
    build_hospital_outside_bg()
    build_hospital_inside_bg()
    build_grass_world_bg()
    build_anesthetic()
    build_page()
    build_scooter_icon()
    build_scooter()
    build_ambulance()
    build_bench()
    build_reception()
    build_npc()
    build_house()
    build_fisherman()
    build_book_sleeve()
    build_grass_house_bg()
    build_bed_white()
    build_machine()
    build_ocean_bg()

    print("占位美术已生成 ->", ART)
    print("轨道世界：轨道 y =", RAIL_TRACKS, "；悬崖深渊右缘 x =", CLIFF_VOID_RIGHT,
          "；保安室水泥台 =", BOOTH_PAD)


if __name__ == "__main__":
    main()
