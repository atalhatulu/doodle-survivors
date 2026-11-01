import os
import numpy as np
from PIL import Image, ImageFilter

SHEET1_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/dark_fantasy_weapons_sheet_1793441140529.jpg"
SHEET2_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/dark_fantasy_passives_sheet_1793441152726.jpg"

def remove_green_background(crop_img):
    # Convert to RGBA
    rgba = crop_img.convert("RGBA")
    data = np.array(rgba, dtype=float)
    
    r = data[:, :, 0]
    g = data[:, :, 1]
    b = data[:, :, 2]
    
    # Chroma key logic for vivid green
    # Pure/near-pure green has high G, low R, low B
    # Excess green condition:
    is_green = (g > 150) & (g > r * 1.35) & (g > b * 1.35)
    
    # Smooth alpha near edges
    alpha = np.ones_like(g) * 255.0
    alpha[is_green] = 0.0
    
    # Also handle anti-aliased fringe:
    fringe = (~is_green) & (g > 110) & (g > r * 1.15) & (g > b * 1.15)
    diff = g[fringe] - np.maximum(r[fringe], b[fringe])
    alpha[fringe] = np.clip(255.0 - (diff * 2.5), 0.0, 255.0)
    
    # Despill green color tint on semi-transparent edge pixels
    data[:, :, 1][fringe] = np.maximum(r[fringe], b[fringe])
    
    data[:, :, 3] = alpha
    result = Image.fromarray(np.uint8(data), mode="RGBA")
    
    # Auto-crop to content bounding box
    bbox = result.getbbox()
    if bbox:
        result = result.crop(bbox)
        
    # Resize nicely to square icon (256x256) with padding
    final_icon = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    # Keep aspect ratio
    w, h = result.size
    max_dim = max(w, h)
    scale = 220.0 / max_dim
    new_w = int(w * scale)
    new_h = int(h * scale)
    resized = result.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    paste_x = (256 - new_w) // 2
    paste_y = (256 - new_h) // 2
    final_icon.paste(resized, (paste_x, paste_y), resized)
    return final_icon

# Sheet 1: 3x3 Grid (1024x1024)
# Cell dimensions: ~341 x ~341
# (row, col) mapping:
# Row 0:
# [0, 0]: Kutsal Aura (Golden Holy Sun) -> assets/sprites/weapons/weapon_aura.png
# [0, 1]: Yıldırım Çağrısı (Electric Lightning Bolt) -> assets/sprites/weapons/weapon_lightning.png
# [0, 2]: Ejderha Nefesi (Dragon Breathing Fire) -> assets/sprites/weapons/weapon_dragon_breath.png
# Row 1:
# [1, 0]: Hiçlik Girdabı (Void Vortex Black Hole) -> assets/sprites/weapons/weapon_void_vortex.png
# [1, 1]: Savaş Narası (Ancient War Horn with Runes) -> assets/sprites/weapons/weapon_earthquake.png
# [1, 2]: Cehennem Kıyameti (Demonic Magma Potion Flask) -> assets/sprites/weapons/weapon_evo_hellfire_storm.png
# Row 2:
# [2, 0]: Kral Celladı (Heavy Executioner Greatsword) -> assets/sprites/weapons/weapon_evo_king_cleaver.png
# [2, 1]: Fırtına Yaylımı (Storm Recurve Bow) -> assets/sprites/weapons/weapon_evo_storm_quiver.png
# [2, 2]: Kozmik Hükümdar (Galaxy Archon Staff) -> assets/sprites/weapons/weapon_evo_cosmic_archon.png

sheet1 = Image.open(SHEET1_PATH)
w1, h1 = sheet1.size
cw1 = w1 / 3.0
ch1 = h1 / 3.0

sheet1_targets = [
    (0, 0, "assets/sprites/weapons/weapon_aura.png"),
    (0, 1, "assets/sprites/weapons/weapon_lightning.png"),
    (0, 2, "assets/sprites/weapons/weapon_dragon_breath.png"),
    (1, 0, "assets/sprites/weapons/weapon_void_vortex.png"),
    (1, 1, "assets/sprites/weapons/weapon_earthquake.png"),
    (1, 2, "assets/sprites/weapons/weapon_evo_hellfire_storm.png"),
    (2, 0, "assets/sprites/weapons/weapon_evo_king_cleaver.png"),
    (2, 1, "assets/sprites/weapons/weapon_evo_storm_quiver.png"),
    (2, 2, "assets/sprites/weapons/weapon_evo_cosmic_archon.png")
]

for r, c, out_path in sheet1_targets:
    box = (int(c * cw1), int(r * ch1), int((c + 1) * cw1), int((r + 1) * ch1))
    crop = sheet1.crop(box)
    icon = remove_green_background(crop)
    icon.save(out_path)
    print(f"Processed & saved: {out_path}")

# Sheet 2: 2x2 Grid (1024x1024)
# Cell dimensions: 512 x 512
# [0, 0]: İlahi Güneş Mabedi (Divine Sun Sanctuary Medallion) -> assets/sprites/weapons/weapon_evo_divine_sun.png
# [0, 1]: Kuvvet Tılsımı (Bloodforged Rune Talisman) -> assets/sprites/passives/passive_power_talisman.png & passive_bomb.png
# [1, 0]: Taş Maske (Vampire Crypt Stone Mask) -> assets/sprites/passives/passive_stone_mask.png & passive_piggy_bank.png
# [1, 1]: Torrona'nın Kutusu (Eldritch Reliquary Chest) -> assets/sprites/passives/passive_torronas_box.png & passive_origami_box.png

sheet2 = Image.open(SHEET2_PATH)
w2, h2 = sheet2.size
cw2 = w2 / 2.0
ch2 = h2 / 2.0

sheet2_targets = [
    (0, 0, ["assets/sprites/weapons/weapon_evo_divine_sun.png"]),
    (0, 1, ["assets/sprites/passives/passive_power_talisman.png", "assets/sprites/passives/passive_bomb.png"]),
    (1, 0, ["assets/sprites/passives/passive_stone_mask.png", "assets/sprites/passives/passive_piggy_bank.png"]),
    (1, 1, ["assets/sprites/passives/passive_torronas_box.png", "assets/sprites/passives/passive_origami_box.png"])
]

for r, c, out_paths in sheet2_targets:
    box = (int(c * cw2), int(r * ch2), int((c + 1) * cw2), int((r + 1) * ch2))
    crop = sheet2.crop(box)
    icon = remove_green_background(crop)
    for p in out_paths:
        icon.save(p)
        print(f"Processed & saved: {p}")

print("All 13 icons successfully extracted, keyed and saved!")
