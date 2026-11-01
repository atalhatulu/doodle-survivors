import os
import numpy as np
from PIL import Image

SHEET1_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/dark_fantasy_enemies_sheet1_1793443083078.jpg"
SHEET2_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/dark_fantasy_enemies_sheet2_1793443101256.jpg"

def remove_green_background_tight(crop_img):
    rgba = crop_img.convert("RGBA")
    data = np.array(rgba, dtype=float)
    
    r = data[:, :, 0]
    g = data[:, :, 1]
    b = data[:, :, 2]
    
    is_green = (g > 140) & (g > r * 1.30) & (g > b * 1.30)
    
    alpha = np.ones_like(g) * 255.0
    alpha[is_green] = 0.0
    
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

# SHEET 1: (1024x1024)
# Let's inspect coordinates for the creatures on Sheet 1:
# Top row:
# - Bat: [0:350, 20:480]
# - Ghoul Beast 1: [20:350, 520:960]
# Mid row:
# - Werebeast/Ghoul 2: [340:650, 80:420]
# - Bone Spider: [350:640, 550:960]
# Bottom row:
# - Skeleton Footman: [650:1000, 40:340]
# - Dark Cultist: [650:1000, 360:630]
# - Winged Eyeball: [670:970, 630:990]

sheet1 = Image.open(SHEET1_PATH)

sheet1_crops = [
    # Bat -> enemy_doodle_bat.png
    ((10, 20, 470, 340), "assets/sprites/characters/enemy_doodle_bat.png"),
    # Ghoul Beast -> enemy_doodle_bee.png (Fast swarm creature)
    ((510, 20, 950, 350), "assets/sprites/characters/enemy_doodle_bee.png"),
    # Werebeast -> enemy_doodle_noodles.png (Creepy elongated stalker)
    ((80, 340, 420, 650), "assets/sprites/characters/enemy_doodle_noodles.png"),
    # Bone Spider -> enemy_doodle_snail.png (Armored crawling creature)
    ((550, 350, 960, 640), "assets/sprites/characters/enemy_doodle_snail.png"),
    # Skeleton Footman -> enemy_doodle_flower.png (Standard wandering undead)
    ((40, 650, 340, 1000), "assets/sprites/characters/enemy_doodle_flower.png"),
    # Dark Cultist -> enemy_doodle_ghost.png (Spectral dark spellcaster)
    ((350, 650, 630, 1000), "assets/sprites/characters/enemy_doodle_ghost.png"),
    # Winged Eyeball -> enemy_doodle_wingeye.png & enemy_doodle_eyeball.png
    ((630, 670, 990, 980), "assets/sprites/characters/enemy_doodle_wingeye.png")
]

for box, out_path in sheet1_crops:
    crop = sheet1.crop(box)
    cleaned = remove_green_background_tight(crop)
    cleaned.save(out_path)
    print(f"Saved: {out_path} ({cleaned.size})")

# Also copy wingeye to eyeball for consistency
clean_eye = Image.open("assets/sprites/characters/enemy_doodle_wingeye.png")
clean_eye.save("assets/sprites/characters/enemy_doodle_eyeball.png")
print("Saved: assets/sprites/characters/enemy_doodle_eyeball.png")

# SHEET 2: (1024x1024) 2x2 Clean Grid
sheet2 = Image.open(SHEET2_PATH)
w2, h2 = sheet2.size
cw2 = w2 / 2.0
ch2 = h2 / 2.0

sheet2_crops = [
    # [0, 0]: Armored Juggernaut -> enemy_doodle_brute.png
    ((0, 0, int(cw2), int(ch2)), "assets/sprites/characters/enemy_doodle_brute.png"),
    # [0, 1]: Gaping Abomination -> enemy_doodle_chomper.png
    ((int(cw2), 0, int(w2), int(ch2)), "assets/sprites/characters/enemy_doodle_chomper.png"),
    # [1, 0]: Lich King Boss -> enemy_doodle_king.png
    ((0, int(ch2), int(cw2), int(h2)), "assets/sprites/characters/enemy_doodle_king.png"),
    # [1, 1]: Toxic Horned Demon Toad -> enemy_doodle_frog.png
    ((int(cw2), int(ch2), int(w2), int(h2)), "assets/sprites/characters/enemy_doodle_frog.png")
]

for box, out_path in sheet2_crops:
    crop = sheet2.crop(box)
    cleaned = remove_green_background_tight(crop)
    cleaned.save(out_path)
    print(f"Saved: {out_path} ({cleaned.size})")

print("All 12 enemy sprites successfully processed and replaced!")
