import os
import numpy as np
from PIL import Image

MENU_BG_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/dark_fantasy_main_menu_bg_1793445181563.jpg"
UI_SHEET_PATH = "/home/teha/.gemini/antigravity/brain/1fc6545e-e484-4df3-a814-cc888ca06418/dark_fantasy_ui_elements_1793445216684.jpg"

os.makedirs("assets/sprites/ui", exist_ok=True)

# 1. Main Menu / Game Over Background: 1920x1080 high-res
bg_im = Image.open(MENU_BG_PATH)
bg_im_resized = bg_im.resize((1920, 1080), Image.Resampling.LANCZOS)
bg_im_resized.save("assets/sprites/ui/dark_fantasy_menu_bg.png")
print("Saved assets/sprites/ui/dark_fantasy_menu_bg.png")

# Also replace parchment_bg.png with this glorious background for immediate drop-in upgrade
bg_im_resized.save("assets/sprites/ui/parchment_bg.png")
print("Replaced assets/sprites/ui/parchment_bg.png with dark fantasy background!")

# 2. Extract UI elements from 2x2 green screen sheet
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

sheet = Image.open(UI_SHEET_PATH)
w, h = sheet.size
cw = w / 2.0
ch = h / 2.0

# [0, 0]: Gothic Stone Slab Dialog Frame -> ui_panel_gothic_frame.png
crop_frame = sheet.crop((0, 0, int(cw), int(ch)))
clean_frame = remove_green_background_tight(crop_frame)
clean_frame.save("assets/sprites/ui/ui_panel_gothic_frame.png")
print("Saved ui_panel_gothic_frame.png:", clean_frame.size)

# [0, 1]: Crypt Parchment Scroll -> parchment_clean.png & ui_scroll_banner.png
crop_scroll = sheet.crop((int(cw), 0, int(w), int(ch)))
clean_scroll = remove_green_background_tight(crop_scroll)
clean_scroll.save("assets/sprites/ui/ui_scroll_banner.png")
clean_scroll.save("assets/sprites/ui/parchment_clean.png")
print("Saved ui_scroll_banner.png & parchment_clean.png:", clean_scroll.size)

# [1, 0]: Obsidian Gold Inlaid Card Frame -> parchment_card_active.png & ui_card_obsidian.png
crop_card = sheet.crop((0, int(ch), int(cw), int(h)))
clean_card = remove_green_background_tight(crop_card)
clean_card.save("assets/sprites/ui/ui_card_obsidian.png")
clean_card.save("assets/sprites/ui/parchment_card_active.png")
print("Saved ui_card_obsidian.png & parchment_card_active.png:", clean_card.size)

# [1, 1]: Bloodstone Forged Iron Button Plaque -> btn_banner_green.png & ui_btn_bloodstone.png
crop_btn = sheet.crop((int(cw), int(ch), int(w), int(h)))
clean_btn = remove_green_background_tight(crop_btn)
clean_btn.save("assets/sprites/ui/ui_btn_bloodstone.png")
clean_btn.save("assets/sprites/ui/btn_banner_green.png")
print("Saved ui_btn_bloodstone.png & btn_banner_green.png:", clean_btn.size)

print("All dark fantasy UI elements successfully processed!")
