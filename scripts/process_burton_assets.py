import os
import numpy as np
from PIL import Image

HEROES_SHEET = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/burton_fairytale_heroes_1793450988359.jpg"
MONSTERS_SHEET = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/burton_fairytale_monsters1_1793451014692.jpg"

def remove_green_background_tight(crop_img):
    rgba = crop_img.convert("RGBA")
    data = np.array(rgba, dtype=float)
    
    r = data[:, :, 0]
    g = data[:, :, 1]
    b = data[:, :, 2]
    
    # Chroma key logic for vivid green
    is_green = (g > 140) & (g > r * 1.30) & (g > b * 1.30)
    
    alpha = np.ones_like(g) * 255.0
    alpha[is_green] = 0.0
    
    # Handle green spill and fringe
    fringe = (~is_green) & (g > 105) & (g > r * 1.12) & (g > b * 1.12)
    diff = g[fringe] - np.maximum(r[fringe], b[fringe])
    alpha[fringe] = np.clip(255.0 - (diff * 2.5), 0.0, 255.0)
    
    data[:, :, 1][fringe] = np.maximum(r[fringe], b[fringe])
    data[:, :, 3] = alpha
    result = Image.fromarray(np.uint8(data), mode="RGBA")
    
    bbox = result.getbbox()
    if bbox:
        result = result.crop(bbox)
    return result

# 1. PROCESS HEROES (2x2 Grid)
# [0, 0]: Cursed Knight -> player_base.png & char_knight.png
# [0, 1]: Plague Necromancer -> char_necromancer.png
# [1, 0]: Tricorn Hunter -> char_ranger.png
# [1, 1]: Eccentric Alchemist -> char_mage.png & char_alchemist.png
heroes_im = Image.open(HEROES_SHEET)
w_h, h_h = heroes_im.size
cw_h = w_h / 2.0
ch_h = h_h / 2.0

hero_crops = [
    ((0, 0, int(cw_h), int(ch_h)), ["assets/sprites/characters/player_base.png", "assets/sprites/characters/char_knight.png"]),
    ((int(cw_h), 0, int(w_h), int(ch_h)), ["assets/sprites/characters/char_necromancer.png"]),
    ((0, int(ch_h), int(cw_h), int(h_h)), ["assets/sprites/characters/char_ranger.png"]),
    ((int(cw_h), int(ch_h), int(w_h), int(h_h)), ["assets/sprites/characters/char_mage.png", "assets/sprites/characters/char_alchemist.png"])
]

for box, out_paths in hero_crops:
    crop = heroes_im.crop(box)
    cleaned = remove_green_background_tight(crop)
    for p in out_paths:
        cleaned.save(p)
        print(f"Saved: {p} ({cleaned.size})")

# 2. PROCESS MONSTERS 1 (3x2 Grid)
# Top row:
# - Patchwork Stitched Bat: [0:350, 0:380] -> enemy_doodle_bat.png
# - Spindly Graveyard Ghoul: [0:460, 360:670] -> enemy_doodle_bee.png & enemy_doodle_noodles.png
# - Doll Face Bone Spider: [0:460, 670:1024] -> enemy_doodle_snail.png
# Bottom row:
# - Pot Helmet Skeleton: [460:1024, 0:360] -> enemy_doodle_flower.png
# - Candle Staff Goblin Cultist: [550:1024, 360:650] -> enemy_doodle_ghost.png
# - Stitched Winged Eyeball: [480:980, 640:1024] -> enemy_doodle_wingeye.png & enemy_doodle_eyeball.png
monsters_im = Image.open(MONSTERS_SHEET)

monster_crops = [
    ((10, 30, 380, 420), ["assets/sprites/characters/enemy_doodle_bat.png"]),
    ((370, 60, 670, 450), ["assets/sprites/characters/enemy_doodle_bee.png", "assets/sprites/characters/enemy_doodle_noodles.png"]),
    ((670, 70, 990, 460), ["assets/sprites/characters/enemy_doodle_snail.png"]),
    ((40, 500, 360, 960), ["assets/sprites/characters/enemy_doodle_flower.png"]),
    ((360, 600, 650, 960), ["assets/sprites/characters/enemy_doodle_ghost.png"]),
    ((630, 500, 990, 930), ["assets/sprites/characters/enemy_doodle_wingeye.png", "assets/sprites/characters/enemy_doodle_eyeball.png"])
]

for box, out_paths in monster_crops:
    crop = monsters_im.crop(box)
    cleaned = remove_green_background_tight(crop)
    for p in out_paths:
        cleaned.save(p)
        print(f"Saved: {p} ({cleaned.size})")

print("Tim Burton Cursed Fairytale sprites successfully processed and installed!")
