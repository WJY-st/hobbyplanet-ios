#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成 Assets.xcassets 的目录结构与 App 图标。

图标是纯几何绘制（渐变底 + 行星 + 轨道环 + 光点），
用 4 倍超采样后缩小，避免边缘锯齿。
"""

import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "HobbyPlanet", "Assets.xcassets")

BRAND = (255, 106, 61)
VIOLET = (124, 92, 255)
CREAM = (255, 246, 238)


def write_json(path, payload):
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def gradient(size, top, bottom):
    """对角线性渐变：左上到右下。"""
    img = Image.new("RGB", (size, size))
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2.0 * (size - 1))
            pixels[x, y] = (
                int(top[0] + (bottom[0] - top[0]) * t),
                int(top[1] + (bottom[1] - top[1]) * t),
                int(top[2] + (bottom[2] - top[2]) * t),
            )
    return img


def make_icon(size=1024, supersample=3):
    s = size * supersample
    base = gradient(s, BRAND, VIOLET)

    # 左上角柔光
    glow = Image.new("L", (s, s), 0)
    draw = ImageDraw.Draw(glow)
    draw.ellipse((-s * 0.25, -s * 0.35, s * 0.55, s * 0.45), fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(s * 0.10))
    white = Image.new("RGB", (s, s), (255, 255, 255))
    base = Image.composite(white, base, glow.point(lambda v: int(v * 0.35)))

    draw = ImageDraw.Draw(base, "RGBA")

    # 行星本体
    cx, cy = s * 0.5, s * 0.52
    r = s * 0.20
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 246, 238, 255))
    draw.ellipse((cx - r * 0.72, cy - r * 0.78, cx + r * 0.30, cy + r * 0.12),
                 fill=(255, 214, 196, 255))

    # 轨道环：用粗弧线画一个斜椭圆
    ring_w = s * 0.045
    bbox = (cx - s * 0.33, cy - s * 0.135, cx + s * 0.33, cy + s * 0.135)
    draw.ellipse(bbox, outline=(255, 255, 255, 210), width=int(ring_w))

    # 环上的一颗小卫星
    sx, sy = cx + s * 0.26, cy + s * 0.07
    sr = s * 0.042
    draw.ellipse((sx - sr, sy - sr, sx + sr, sy + sr), fill=(255, 246, 238, 255))

    # 右下角闪光点
    for (fx, fy, fr, alpha) in ((0.78, 0.25, 0.016, 210), (0.86, 0.36, 0.010, 160),
                                (0.20, 0.80, 0.012, 170)):
        draw.ellipse((s * fx - s * fr, s * fy - s * fr, s * fx + s * fr, s * fy + s * fr),
                     fill=(255, 255, 255, alpha))

    return base.resize((size, size), Image.LANCZOS)


def main():
    os.makedirs(ASSETS, exist_ok=True)
    write_json(os.path.join(ASSETS, "Contents.json"),
               {"info": {"author": "xcode", "version": 1}})

    accent_dir = os.path.join(ASSETS, "AccentColor.colorset")
    os.makedirs(accent_dir, exist_ok=True)
    write_json(os.path.join(accent_dir, "Contents.json"), {
        "colors": [{
            "color": {
                "color-space": "srgb",
                "components": {"alpha": "1.000", "blue": "0x3D", "green": "0x6A", "red": "0xFF"}
            },
            "idiom": "universal"
        }],
        "info": {"author": "xcode", "version": 1}
    })

    icon_dir = os.path.join(ASSETS, "AppIcon.appiconset")
    os.makedirs(icon_dir, exist_ok=True)
    write_json(os.path.join(icon_dir, "Contents.json"), {
        "images": [{
            "filename": "AppIcon-1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024"
        }],
        "info": {"author": "xcode", "version": 1}
    })

    icon = make_icon(1024)
    icon.save(os.path.join(icon_dir, "AppIcon-1024.png"))
    print("图标与 asset catalog 已生成:", icon_dir)


if __name__ == "__main__":
    sys.exit(main())
