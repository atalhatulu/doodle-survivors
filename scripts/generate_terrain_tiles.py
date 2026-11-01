import os
import random
import math
from PIL import Image, ImageDraw, ImageFilter

os.makedirs("assets/sprites/terrain", exist_ok=True)

def clamp(val, min_v=0, max_v=255):
    return max(min_v, min(max_v, int(val)))

def create_ancient_flagstone():
    # 512x512 Seamless Dark Medieval Flagstone / Cobblestone
    width, height = 512, 512
    img = Image.new("RGBA", (width, height), (38, 36, 42, 255))
    draw = ImageDraw.Draw(img)
    
    # Base dark mortar background
    for y in range(height):
        for x in range(0, width, 4):
            n = random.randint(-4, 4)
            draw.point((x, y), fill=(32 + n, 30 + n, 36 + n, 255))

    # Grid of irregular stone pavers (approx 64x64 or 128x64)
    # Staggered brick/flagstone pattern
    row_height = 64
    for r in range(height // row_height):
        y0 = r * row_height
        y1 = y0 + row_height
        offset = (r % 2) * 48
        cols = 512 // 96 + 2
        for c in range(-1, cols):
            x0 = c * 96 + offset + (random.randint(-4, 4))
            x1 = x0 + 90 + (random.randint(-4, 4))
            
            # Stone color base
            tone = random.randint(58, 76)
            tint_r = tone + random.randint(-3, 3)
            tint_g = tone + random.randint(-2, 4)
            tint_b = tone + random.randint(0, 6)
            
            # Draw rounded stone rect with 4px mortar margin
            draw.rounded_rectangle(
                [(x0 + 4, y0 + 4), (x1 - 4, y1 - 4)],
                radius=6,
                fill=(tint_r, tint_g, tint_b, 255),
                outline=(tint_r - 18, tint_g - 18, tint_b - 16, 255),
                width=2
            )
            
            # Subtle stone highlight (top-left edge)
            draw.line([(x0 + 6, y0 + 6), (x1 - 6, y0 + 6)], fill=(tint_r + 20, tint_g + 20, tint_b + 22, 200), width=1)
            draw.line([(x0 + 6, y0 + 6), (x0 + 6, y1 - 6)], fill=(tint_r + 16, tint_g + 16, tint_b + 18, 200), width=1)
            
            # Stone shadow (bottom-right edge)
            draw.line([(x0 + 6, y1 - 5), (x1 - 6, y1 - 5)], fill=(tint_r - 22, tint_g - 22, tint_b - 20, 220), width=2)
            draw.line([(x1 - 5, y0 + 6), (x1 - 5, y1 - 5)], fill=(tint_r - 22, tint_g - 22, tint_b - 20, 220), width=2)
            
            # Occasional crack
            if random.random() < 0.35:
                cx = (x0 + x1) // 2
                cy = (y0 + y1) // 2
                draw.line([(cx, cy), (cx + random.randint(-12, 12), cy + random.randint(-14, 14))], fill=(28, 26, 32, 240), width=1)

    # Moss speckles in crevices
    for _ in range(350):
        mx = random.randint(0, width - 1)
        my = random.randint(0, height - 1)
        draw.ellipse([(mx, my), (mx + random.randint(2, 5), my + random.randint(2, 4))], fill=(42, 68, 38, random.randint(140, 210)))

    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save("assets/sprites/terrain/tile_ancient_flagstone.png")
    print("Created tile_ancient_flagstone.png")

def create_dark_earth():
    # 512x512 Dark Medieval Earth / Soil & Gravel
    width, height = 512, 512
    img = Image.new("RGBA", (width, height), (44, 38, 32, 255))
    draw = ImageDraw.Draw(img)
    
    # Noise layers for natural soil texture
    for y in range(height):
        for x in range(0, width, 3):
            v = random.randint(-12, 12)
            draw.point((x, y), fill=(clamp(46 + v), clamp(40 + v), clamp(34 + v), 255))

    # Dark soil clods & mud patches
    for _ in range(80):
        px = random.randint(0, width - 1)
        py = random.randint(0, height - 1)
        rw = random.randint(14, 38)
        rh = random.randint(10, 26)
        c = random.randint(30, 38)
        draw.ellipse([(px, py), (px + rw, py + rh)], fill=(c, c - 4, c - 8, random.randint(100, 180)))

    # Scattered small pebbles and stones
    for _ in range(200):
        px = random.randint(0, width - 1)
        py = random.randint(0, height - 1)
        sz = random.randint(2, 6)
        stone_col = random.randint(70, 95)
        draw.ellipse([(px, py), (px + sz, py + sz - 1)], fill=(stone_col, stone_col - 2, stone_col + 4, 255))
        # Pebble shadow
        draw.point((px + 1, py + sz), fill=(24, 20, 16, 200))

    # Faint withered grass tufts
    for _ in range(120):
        gx = random.randint(0, width - 1)
        gy = random.randint(0, height - 1)
        draw.line([(gx, gy), (gx + random.randint(-4, 4), gy - random.randint(4, 9))], fill=(58, 68, 36, 180), width=1)

    img = img.filter(ImageFilter.SMOOTH)
    img.save("assets/sprites/terrain/tile_dark_earth.png")
    print("Created tile_dark_earth.png")

def create_mossy_cobble():
    # 512x512 Overgrown Mossy Cobblestone
    width, height = 512, 512
    img = Image.new("RGBA", (width, height), (32, 42, 30, 255))
    draw = ImageDraw.Draw(img)
    
    # Irregular natural stones
    for r in range(12):
        for c in range(12):
            x = c * 44 + random.randint(-6, 6)
            y = r * 44 + random.randint(-6, 6)
            w = random.randint(36, 44)
            h = random.randint(34, 42)
            base_col = random.randint(48, 64)
            
            draw.rounded_rectangle(
                [(x, y), (x + w, y + h)],
                radius=8,
                fill=(base_col, base_col + random.randint(4, 10), base_col - 2, 255),
                outline=(24, 32, 22, 255),
                width=2
            )
            # Stone top highlight
            draw.arc([(x + 2, y + 2), (x + w - 2, y + h - 2)], start=180, end=270, fill=(base_col + 24, base_col + 32, base_col + 18, 190), width=2)

    # Heavy dark green forest moss overlays
    for _ in range(60):
        mx = random.randint(0, width - 1)
        my = random.randint(0, height - 1)
        mw = random.randint(24, 60)
        mh = random.randint(20, 48)
        draw.ellipse([(mx, my), (mx + mw, my + mh)], fill=(36, 66, 32, random.randint(80, 160)))

    # Bright lichen dots
    for _ in range(250):
        lx = random.randint(0, width - 1)
        ly = random.randint(0, height - 1)
        draw.ellipse([(lx, ly), (lx + random.randint(2, 4), ly + random.randint(2, 4))], fill=(68, 110, 52, 220))

    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save("assets/sprites/terrain/tile_mossy_cobble.png")
    print("Created tile_mossy_cobble.png")

def create_crypt_slate():
    # 512x512 Dark Gothic Crypt Slate Tile
    width, height = 512, 512
    img = Image.new("RGBA", (width, height), (26, 26, 32, 255))
    draw = ImageDraw.Draw(img)
    
    # 4 large polished dark tiles (256x256 each) with bevels
    tile_size = 256
    for ty in range(2):
        for tx in range(2):
            x0 = tx * tile_size + 6
            y0 = ty * tile_size + 6
            x1 = (tx + 1) * tile_size - 6
            y1 = (ty + 1) * tile_size - 6
            
            # Dark slate gradient/fill
            draw.rectangle([(x0, y0), (x1, y1)], fill=(40, 42, 50, 255))
            
            # Inner bevel
            draw.line([(x0, y0), (x1, y0)], fill=(65, 68, 80, 255), width=2)
            draw.line([(x0, y0), (x0, y1)], fill=(58, 60, 72, 255), width=2)
            draw.line([(x0, y1), (x1, y1)], fill=(18, 18, 24, 255), width=3)
            draw.line([(x1, y0), (x1, y1)], fill=(18, 18, 24, 255), width=3)
            
            # Subtle diagonal slate texture grain
            for d in range(0, 240, 16):
                draw.line([(x0 + d, y0), (x0, y0 + d)], fill=(35, 37, 45, 120), width=1)
                
            # Ancient carved runic groove in center of each slab
            cx = (x0 + x1) // 2
            cy = (y0 + y1) // 2
            draw.polygon([(cx - 24, cy), (cx, cy - 24), (cx + 24, cy), (cx, cy + 24)], outline=(22, 22, 28, 255), width=2)
            draw.ellipse([(cx - 10, cy - 10), (cx + 10, cy + 10)], outline=(22, 22, 28, 255), width=2)

    # Edge mortar joints
    draw.rectangle([(0, 0), (width, height)], outline=(16, 16, 20, 255), width=4)
    draw.line([(256, 0), (256, 512)], fill=(16, 16, 20, 255), width=4)
    draw.line([(0, 256), (512, 256)], fill=(16, 16, 20, 255), width=4)

    img = img.filter(ImageFilter.SMOOTH)
    img.save("assets/sprites/terrain/tile_crypt_slate.png")
    print("Created tile_crypt_slate.png")

if __name__ == "__main__":
    create_ancient_flagstone()
    create_dark_earth()
    create_mossy_cobble()
    create_crypt_slate()
