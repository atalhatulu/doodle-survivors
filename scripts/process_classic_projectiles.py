import os
import numpy as np
from PIL import Image

SHEET_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/classic_projectiles_sheet_1793442616289.jpg"

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

sheet = Image.open(SHEET_PATH)
w, h = sheet.size
cw = w / 2.0
ch = h / 2.0

# 1. Ok (Hunter Arrow) - Top-Left [0, 0]
crop_arrow = sheet.crop((0, 0, int(cw), int(ch)))
clean_arrow = remove_green_background_tight(crop_arrow)
# Save directly as proj_arrow.png
clean_arrow.save("assets/sprites/weapons/proj_arrow.png")
print("Saved proj_arrow.png:", clean_arrow.size)

# 2. Hançer (Throwing Dagger) - Top-Right [0, 1]
crop_dagger = sheet.crop((int(cw), 0, int(w), int(ch)))
clean_dagger = remove_green_background_tight(crop_dagger)
clean_dagger.save("assets/sprites/weapons/proj_dagger.png")
print("Saved proj_dagger.png:", clean_dagger.size)

# 3. Büyü Küresi (Mana Arcane Orb) - Bottom-Left [1, 0]
crop_orb = sheet.crop((0, int(ch), int(cw), int(h)))
clean_orb = remove_green_background_tight(crop_orb)
clean_orb.save("assets/sprites/weapons/proj_orb.png")
print("Saved proj_orb.png:", clean_orb.size)

# 4. Fırlatma Baltası Başı (Runic Throwing Axe) - Bottom-Right [1, 1]
crop_axe = sheet.crop((int(cw), int(ch), int(w), int(h)))
clean_axe = remove_green_background_tight(crop_axe)
clean_axe.save("assets/sprites/weapons/proj_axe_head.png")
print("Saved proj_axe_head.png:", clean_axe.size)
