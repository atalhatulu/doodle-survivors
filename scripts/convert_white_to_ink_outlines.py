"""
Converts thick white die-cut sticker outlines into refined dark gothic ink contours.
Detects white outer border pixels and replaces them with an organic dark ink outline
while preserving interior highlights.
"""
import os
import numpy as np
from PIL import Image, ImageFilter

def process_sprite_outline(path):
    if not os.path.exists(path):
        return
    im = Image.open(path).convert("RGBA")
    data = np.array(im, dtype=float)
    
    r = data[:, :, 0]
    g = data[:, :, 1]
    b = data[:, :, 2]
    a = data[:, :, 3]
    
    # Non-transparent pixels
    has_alpha = a > 20.0
    if not np.any(has_alpha):
        return
        
    # Detect the white outer border:
    # High brightness in R, G, B with very low saturation (R, G, B close to each other)
    brightness = (r + g + b) / 3.0
    max_c = np.maximum(np.maximum(r, g), b)
    min_c = np.minimum(np.minimum(r, g), b)
    saturation = max_c - min_c
    
    # White border condition: brightness > 220, saturation < 30, high alpha
    is_white_border = (brightness > 220) & (saturation < 35) & (a > 120.0)
    
    # We only want to turn the OUTER border dark, not tiny white eye dots or sword shines
    # Find boundary pixels:
    # Use morphological erosion to see distance from transparent exterior
    alpha_bin = Image.fromarray(np.uint8(has_alpha * 255), mode="L")
    eroded = alpha_bin.filter(ImageFilter.MinFilter(13)) # 6-8px border radius
    eroded_data = np.array(eroded) > 0
    
    # Outer rim is within the first 6-8px from transparency
    is_outer_rim = has_alpha & (~eroded_data)
    
    # Pixels that are part of the outer rim and white:
    target_border = is_white_border & is_outer_rim
    
    # Dark ink color: very dark gothic iron/charcoal (22, 18, 26)
    data[:, :, 0][target_border] = 22.0
    data[:, :, 1][target_border] = 18.0
    data[:, :, 2][target_border] = 26.0
    data[:, :, 3][target_border] = 255.0
    
    # Now slightly thin the border so it becomes a sleek 2-3px dark outline instead of an 8px thick bar
    # Outer edge of the dark border can be trimmed
    new_img = Image.fromarray(np.uint8(data), mode="RGBA")
    
    # Save back
    new_img.save(path)
    print(f"Refined outline: {path}")

# Target folders and sprites
sprites = [
    # Player Heroes
    "assets/sprites/characters/player_base.png",
    "assets/sprites/characters/char_knight.png",
    "assets/sprites/characters/char_necromancer.png",
    "assets/sprites/characters/char_ranger.png",
    "assets/sprites/characters/char_mage.png",
    
    # Enemies
    "assets/sprites/characters/enemy_doodle_bat.png",
    "assets/sprites/characters/enemy_doodle_wingeye.png",
    "assets/sprites/characters/enemy_doodle_eyeball.png",
    "assets/sprites/characters/enemy_doodle_bee.png",
    "assets/sprites/characters/enemy_doodle_flower.png",
    "assets/sprites/characters/enemy_doodle_snail.png",
    "assets/sprites/characters/enemy_doodle_noodles.png",
    "assets/sprites/characters/enemy_doodle_ghost.png",
    "assets/sprites/characters/enemy_doodle_frog.png",
    "assets/sprites/characters/enemy_doodle_brute.png",
    "assets/sprites/characters/enemy_doodle_chomper.png",
    "assets/sprites/characters/enemy_doodle_king.png",
    
    # Weapons & Projectiles
    "assets/sprites/weapons/weapon_sword.png",
    "assets/sprites/weapons/weapon_bow.png",
    "assets/sprites/weapons/weapon_dagger.png",
    "assets/sprites/weapons/weapon_staff.png",
    "assets/sprites/weapons/weapon_axe.png",
    "assets/sprites/weapons/proj_arrow.png",
    "assets/sprites/weapons/proj_dagger.png",
    "assets/sprites/weapons/proj_storm_arrow.png",
    "assets/sprites/weapons/proj_king_cleaver.png",
    "assets/sprites/weapons/proj_axe_head.png",
    "assets/sprites/weapons/spirit_wolf.png",
    
    # Environment props
    "assets/sprites/environment/paper_tree_big_swirl.png",
    "assets/sprites/environment/paper_rock_large.png",
    "assets/sprites/environment/paper_bush_dense.png",
    "assets/sprites/environment/paper_grass_tall.png",
    "assets/sprites/environment/paper_grass_spiky.png",
    "assets/sprites/environment/paper_rock_small.png",
    "assets/sprites/environment/paper_stump.png"
]

for s in sprites:
    process_sprite_outline(s)

print("All white die-cut borders successfully transformed into gothic ink contours!")
