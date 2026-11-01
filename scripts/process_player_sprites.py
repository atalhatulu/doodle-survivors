import os
import numpy as np
from PIL import Image

SHEET_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/dark_fantasy_player_heroes_1793443280592.jpg"

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

sheet = Image.open(SHEET_PATH)
w, h = sheet.size
cw = w / 2.0
ch = h / 2.0

# [0, 0]: Dark Wanderer Knight (Base player & Knight)
crop_knight = sheet.crop((0, 0, int(cw), int(ch)))
clean_knight = remove_green_background_tight(crop_knight)
clean_knight.save("assets/sprites/characters/player_base.png")
clean_knight.save("assets/sprites/characters/char_knight.png")
print("Saved player_base.png & char_knight.png:", clean_knight.size)

# [0, 1]: Necromancer
crop_necro = sheet.crop((int(cw), 0, int(w), int(ch)))
clean_necro = remove_green_background_tight(crop_necro)
clean_necro.save("assets/sprites/characters/char_necromancer.png")
print("Saved char_necromancer.png:", clean_necro.size)

# [1, 0]: Ranger Archer
crop_ranger = sheet.crop((0, int(ch), int(cw), int(h)))
clean_ranger = remove_green_background_tight(crop_ranger)
clean_ranger.save("assets/sprites/characters/char_ranger.png")
print("Saved char_ranger.png:", clean_ranger.size)

# [1, 1]: Arcane Mage
crop_mage = sheet.crop((int(cw), int(ch), int(w), int(h)))
clean_mage = remove_green_background_tight(crop_mage)
clean_mage.save("assets/sprites/characters/char_mage.png")
print("Saved char_mage.png:", clean_mage.size)

print("All hero character sprites processed and saved!")
