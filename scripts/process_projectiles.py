import os
import numpy as np
from PIL import Image

SHEET_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/projectiles_sheet_1793441348334.jpg"

def remove_green_background(crop_img):
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
        
    final_icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    w, h = result.size
    max_dim = max(w, h)
    scale = 224.0 / max_dim
    new_w = int(w * scale)
    new_h = int(h * scale)
    resized = result.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    paste_x = (256 - new_w) // 2
    paste_y = (256 - new_h) // 2
    final_icon.paste(resized, (paste_x, paste_y), resized)
    return final_icon

sheet = Image.open(SHEET_PATH)
w, h = sheet.size
cw = w / 2.0
ch = h / 2.0

targets = [
    # [0, 0]: Flame puff burst -> proj_flame_puff.png (Dragon breath)
    (0, 0, "assets/sprites/weapons/proj_flame_puff.png"),
    # [0, 1]: Void cosmic vortex swirl -> proj_void_swirl.png (Void vortex)
    (0, 1, "assets/sprites/weapons/proj_void_swirl.png"),
    # [1, 0]: Electric lightning arrow -> proj_storm_arrow.png (Storm quiver)
    (1, 0, "assets/sprites/weapons/proj_storm_arrow.png"),
    # [1, 1]: Bloodstained executioner cleaver -> proj_king_cleaver.png (King cleaver)
    (1, 1, "assets/sprites/weapons/proj_king_cleaver.png")
]

for r, c, out_path in targets:
    box = (int(c * cw), int(r * ch), int((c + 1) * cw), int((r + 1) * ch))
    crop = sheet.crop(box)
    icon = remove_green_background(crop)
    icon.save(out_path)
    print(f"Processed & saved: {out_path}")

print("All projectile sprites extracted successfully!")
