"""
Transforms existing weapon and passive icon assets into the Tim Burton / Don't Starve
gothic storybook style:
1. Strips any residual white borders.
2. Applies a fine, sharp dark ink contour line around the subject.
3. Enhances ink hatching/sketchy texture contrast and desaturates slightly to rich watercolor washes.
"""
import os
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance

def stylize_to_burton_ink(image_path):
    if not os.path.exists(image_path):
        return
    im = Image.open(image_path).convert("RGBA")
    
    # 1. First, strip any outer white halo
    data = np.array(im, dtype=float)
    r = data[:, :, 0]
    g = data[:, :, 1]
    b = data[:, :, 2]
    a = data[:, :, 3]
    
    has_alpha = a > 25.0
    if not np.any(has_alpha):
        return
        
    brightness = (r + g + b) / 3.0
    max_c = np.maximum(np.maximum(r, g), b)
    min_c = np.minimum(np.minimum(r, g), b)
    saturation = max_c - min_c
    
    # White border detection
    is_white_border = (brightness > 215) & (saturation < 35) & (a > 100.0)
    
    alpha_bin = Image.fromarray(np.uint8(has_alpha * 255), mode="L")
    eroded = alpha_bin.filter(ImageFilter.MinFilter(9))
    eroded_data = np.array(eroded) > 0
    is_outer_rim = has_alpha & (~eroded_data)
    
    target_border = is_white_border & is_outer_rim
    
    # Replace white border with deep charcoal ink
    data[:, :, 0][target_border] = 20.0
    data[:, :, 1][target_border] = 16.0
    data[:, :, 2][target_border] = 22.0
    data[:, :, 3][target_border] = 255.0
    
    cleaned_im = Image.fromarray(np.uint8(data), mode="RGBA")
    
    # 2. Extract alpha channel for a clean thin ink stroke
    alpha = cleaned_im.split()[-1]
    
    # Generate 2px crisp black outer stroke
    stroke_mask = alpha.filter(ImageFilter.MaxFilter(5))
    stroke_layer = Image.new("RGBA", cleaned_im.size, (15, 12, 18, 255))
    stroke_layer.putalpha(stroke_mask)
    
    # 3. Stylize artwork: Slightly desaturate color towards watercolor palette and increase contrast
    rgb = cleaned_im.convert("RGB")
    enhancer_color = ImageEnhance.Color(rgb)
    rgb_toned = enhancer_color.enhance(0.85) # Vintage fairytale wash
    enhancer_contrast = ImageEnhance.Contrast(rgb_toned)
    rgb_contrast = enhancer_contrast.enhance(1.18) # Sharp pen-and-ink hatching
    
    toned_im = rgb_contrast.convert("RGBA")
    toned_im.putalpha(alpha)
    
    # Composite: Thin black stroke behind the toned artwork
    final = Image.new("RGBA", cleaned_im.size, (0, 0, 0, 0))
    final.paste(stroke_layer, (0, 0), stroke_layer)
    final.paste(toned_im, (0, 0), toned_im)
    
    final.save(image_path)
    print(f"Stylized to Burton ink: {image_path}")

# Target all weapon and passive icons
icon_files = [
    # Weapons
    "assets/sprites/weapons/weapon_sword.png",
    "assets/sprites/weapons/weapon_bow.png",
    "assets/sprites/weapons/weapon_dagger.png",
    "assets/sprites/weapons/weapon_staff.png",
    "assets/sprites/weapons/weapon_axe.png",
    "assets/sprites/weapons/weapon_boomerang.png",
    "assets/sprites/weapons/weapon_potion.png",
    "assets/sprites/weapons/weapon_spellbook.png",
    "assets/sprites/weapons/weapon_aura.png",
    "assets/sprites/weapons/weapon_lightning.png",
    "assets/sprites/weapons/weapon_dragon_breath.png",
    "assets/sprites/weapons/weapon_void_vortex.png",
    "assets/sprites/weapons/weapon_earthquake.png",
    "assets/sprites/weapons/weapon_evo_divine_sun.png",
    "assets/sprites/weapons/weapon_evo_hellfire_storm.png",
    "assets/sprites/weapons/weapon_evo_king_cleaver.png",
    "assets/sprites/weapons/weapon_evo_storm_quiver.png",
    "assets/sprites/weapons/weapon_evo_cosmic_archon.png",
    "assets/sprites/weapons/proj_arrow.png",
    "assets/sprites/weapons/proj_dagger.png",
    "assets/sprites/weapons/proj_storm_arrow.png",
    "assets/sprites/weapons/proj_king_cleaver.png",
    "assets/sprites/weapons/proj_flame_puff.png",
    "assets/sprites/weapons/proj_void_swirl.png",
    
    # Passives
    "assets/sprites/passives/passive_power_talisman.png",
    "assets/sprites/passives/passive_bomb.png",
    "assets/sprites/passives/passive_stone_mask.png",
    "assets/sprites/passives/passive_piggy_bank.png",
    "assets/sprites/passives/passive_torronas_box.png",
    "assets/sprites/passives/passive_origami_box.png",
    "assets/sprites/passives/passive_shoes.png",
    "assets/sprites/passives/passive_heart.png",
    "assets/sprites/passives/passive_magnet.png",
    "assets/sprites/passives/passive_stopwatch.png",
    "assets/sprites/passives/passive_armor.png",
    "assets/sprites/passives/passive_clover.png",
    "assets/sprites/passives/passive_magnifier.png",
    "assets/sprites/passives/passive_carbon_paper.png",
    "assets/sprites/passives/passive_bandage.png",
    "assets/sprites/passives/passive_rubber_band.png",
    "assets/sprites/passives/passive_hourglass.png",
    "assets/sprites/passives/passive_graduation_cap.png",
    "assets/sprites/passives/passive_eraser_backup.png",
    "assets/sprites/passives/passive_ruler_shield.png",
    "assets/sprites/passives/passive_ink_skull.png",
    "assets/sprites/passives/passive_sharpener.png",
    
    # Bosses (Brute, Chomper, Frog, King)
    "assets/sprites/characters/enemy_doodle_brute.png",
    "assets/sprites/characters/enemy_doodle_chomper.png",
    "assets/sprites/characters/enemy_doodle_frog.png",
    "assets/sprites/characters/enemy_doodle_king.png"
]

for p in icon_files:
    stylize_to_burton_ink(p)

print("All weapons, passives and boss monsters successfully unified into Tim Burton ink aesthetic!")
