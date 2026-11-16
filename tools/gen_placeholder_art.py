# -*- coding: utf-8 -*-
"""
Next Level Dream —— 占位美术资源生成器（一次性工具，不参与游戏运行）。

生成的全部 PNG 都是"可直接替换"的占位素材：
替换时只要保持文件名与尺寸一致，场景与碰撞体无需改动。

运行：
    python tools/gen_placeholder_art.py
"""

from __future__ import annotations

import os
import random

from PIL import Image, ImageDraw

PROJECT = r"E:\Godot4AllGame\NextLevelDream"
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


def build_deep_forest_bg() -> None:
    img, d = canvas(WORLD_W, WORLD_H)
    vgradient(d, 0, 0, WORLD_W, WORLD_H, (36, 62, 42), (14, 28, 20))

    for _ in range(240):
        cx = random.randint(0, WORLD_W)
        cy = random.randint(0, WORLD_H)
        rw = random.randint(90, 300)
        rh = random.randint(60, 190)
        color = random.choice([(26, 50, 32, 255), (18, 38, 24, 255), (42, 72, 48, 255)])
        d.ellipse((cx - rw, cy - rh, cx + rw, cy + rh), fill=color)

    # 林间小径
    d.rectangle((0, 780, WORLD_W, 940), fill=(58, 44, 30, 255))
    d.rectangle((0, 780, WORLD_W, 798), fill=(76, 58, 40, 255))
    d.rectangle((0, 922, WORLD_W, 940), fill=(44, 32, 22, 255))
    d.rectangle((1360, 0, 1520, WORLD_H), fill=(58, 44, 30, 255))
    d.rectangle((1360, 0, 1378, WORLD_H), fill=(76, 58, 40, 255))
    d.rectangle((1502, 0, 1520, WORLD_H), fill=(44, 32, 22, 255))

    # 灌木与蕨类
    for _ in range(280):
        bx = random.randint(30, WORLD_W - 30)
        by = random.randint(30, WORLD_H - 30)
        for _ in range(5):
            d.line((bx, by, bx + random.randint(-14, 14), by - random.randint(14, 34)),
                   fill=(48, 92, 54, 255), width=4)

    # 透过树叶的光斑
    for _ in range(100):
        x = random.randint(0, WORLD_W)
        y = random.randint(0, WORLD_H)
        r = random.choice([4, 6, 8])
        d.ellipse((x - r, y - r, x + r, y + r), fill=(198, 246, 172, 150))

    border = 70
    d.rectangle((0, 0, WORLD_W, border), fill=(12, 20, 14, 255))
    d.rectangle((0, WORLD_H - border, WORLD_W, WORLD_H), fill=(12, 20, 14, 255))
    d.rectangle((0, 0, border, WORLD_H), fill=(12, 20, 14, 255))
    d.rectangle((WORLD_W - border, 0, WORLD_W, WORLD_H), fill=(12, 20, 14, 255))

    img.save(os.path.join(DIR_BG, "bg_deep_forest.png"))


# --------------------------------------------------------------------------
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

    # 梦境卧室：同一布局，梦的配色
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

    print("占位美术已生成 ->", ART)
    print("梦境世界障碍矩形（已画进背景，请与 .tscn 中的碰撞体保持一致）：")
    for ox, oy, ow, oh in OBSTACLES:
        print(f"  中心 ({ox + ow // 2}, {oy + oh // 2})  尺寸 ({ow}, {oh})")


if __name__ == "__main__":
    main()
