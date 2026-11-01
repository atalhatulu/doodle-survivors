"""
Production-quality Icon Generator for Doodle Survivors
Generates all 10 missing/borrowed weapon & evolution icons and updates any outdated passives
with dark medieval fantasy aesthetic, crisp sticker borders, and glowing runes.
"""
import os
import math
from PIL import Image, ImageDraw, ImageFilter

os.makedirs("assets/sprites/weapons", exist_ok=True)
os.makedirs("assets/sprites/passives", exist_ok=True)

CANVAS_SIZE = 256

def apply_glow_and_sticker(img, glow_color, border_width=6, glow_radius=8):
    # Separate alpha channel
    alpha = img.split()[-1]
    
    # 1. Outer Glow
    glow_mask = alpha.filter(ImageFilter.GaussianBlur(glow_radius))
    glow_layer = Image.new("RGBA", img.size, glow_color)
    glow_layer.putalpha(glow_mask)
    
    # 2. White sticker outline
    border_mask = alpha.filter(ImageFilter.MaxFilter(border_width * 2 + 1))
    border_layer = Image.new("RGBA", img.size, (255, 255, 255, 255))
    border_layer.putalpha(border_mask)
    
    # Composite: Glow -> Border -> Base Image
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(glow_layer, (0, 0), glow_layer)
    out.paste(border_layer, (0, 0), border_layer)
    out.paste(img, (0, 0), img)
    return out

# -------------------------------------------------------------
# 1. KUTSAL AURA (weapon_aura.png) - Radiating Golden Sacred Relic / Holy Halo
# -------------------------------------------------------------
def make_weapon_aura():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 128, 128
    
    # Holy circular halo aura
    for r in range(80, 50, -4):
        c = int(255 - (80 - r) * 3)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, c, 50, 240), width=3)
        
    # Radiating 8 golden holy spikes
    for i in range(8):
        ang = i * (math.pi / 4.0)
        x1 = cx + math.cos(ang) * 45
        y1 = cy + math.sin(ang) * 45
        x2 = cx + math.cos(ang) * 98
        y2 = cy + math.sin(ang) * 98
        
        # diamond spike
        orth = ang + math.pi/2
        ox = math.cos(orth) * 8
        oy = math.sin(orth) * 8
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        d.polygon([(x1, y1), (mid_x + ox, mid_y + oy), (x2, y2), (mid_x - ox, mid_y - oy)], 
                  fill=(255, 220, 80, 255), outline=(180, 130, 20, 255))

    # Inner sacred golden cross / sun core
    d.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=(255, 245, 180, 255), outline=(210, 160, 30, 255), width=3)
    d.rectangle([cx - 8, cy - 30, cx + 8, cy + 30], fill=(220, 140, 20, 255))
    d.rectangle([cx - 24, cy - 8, cx + 24, cy + 8], fill=(220, 140, 20, 255))
    d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=(255, 255, 255, 255))
    
    final_img = apply_glow_and_sticker(im, (255, 215, 0, 160))
    final_img.save("assets/sprites/weapons/weapon_aura.png")
    print("Created weapon_aura.png")

# -------------------------------------------------------------
# 2. YILDIRIM ÇAĞRISI (weapon_lightning.png) - Crackling Thunder Bolt & Storm Sigil
# -------------------------------------------------------------
def make_weapon_lightning():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Storm Cloud / Dark Iron Crest
    d.ellipse([64, 40, 192, 110], fill=(45, 45, 65, 255), outline=(140, 160, 210, 255), width=4)
    d.ellipse([90, 30, 166, 95], fill=(70, 75, 105, 255))
    
    # Massive Jagged Lightning Bolt striking diagonally
    bolt_pts = [
        (135, 60), (165, 60), (125, 115), (160, 115), 
        (95, 215), (118, 140), (85, 140), (120, 60)
    ]
    # Bolt dark border
    d.polygon(bolt_pts, fill=(255, 255, 255, 255), outline=(40, 140, 255, 255))
    # Electric inner gradient
    inner_pts = [
        (133, 68), (155, 68), (123, 116), (150, 116),
        (102, 198), (117, 138), (92, 138), (122, 68)
    ]
    d.polygon(inner_pts, fill=(120, 220, 255, 255))
    d.line([(130, 72), (125, 116), (105, 185)], fill=(255, 255, 255, 255), width=3)
    
    # Electric spark branches
    d.line([(125, 115), (75, 125), (60, 145)], fill=(160, 230, 255, 255), width=3)
    d.line([(118, 140), (160, 155), (175, 175)], fill=(160, 230, 255, 255), width=3)
    d.line([(100, 185), (130, 200)], fill=(200, 240, 255, 255), width=2)
    
    final_img = apply_glow_and_sticker(im, (0, 180, 255, 180))
    final_img.save("assets/sprites/weapons/weapon_lightning.png")
    print("Created weapon_lightning.png")

# -------------------------------------------------------------
# 3. EJDERHA NEFESİ (weapon_dragon_breath.png) - Dragon Skull Breathing Fiery Torrent
# -------------------------------------------------------------
def make_weapon_dragon_breath():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Dragon Head Profile (left side looking right)
    head_pts = [
        (40, 95), (65, 70), (95, 60), (135, 75), (115, 105), 
        (140, 120), (110, 140), (90, 130), (60, 155), (45, 130)
    ]
    d.polygon(head_pts, fill=(55, 20, 15, 255), outline=(180, 40, 20, 255))
    
    # Dragon horns
    d.polygon([(90, 62), (80, 25), (105, 50)], fill=(30, 10, 10, 255), outline=(220, 60, 20, 255), width=2)
    d.polygon([(65, 70), (50, 40), (75, 60)], fill=(30, 10, 10, 255), outline=(220, 60, 20, 255), width=2)
    
    # Glowing Dragon Eye
    d.polygon([(85, 80), (100, 85), (88, 92)], fill=(255, 220, 0, 255))
    
    # Blazing Fire Cone erupting from jaws
    fire_pts_outer = [
        (115, 105), (170, 75), (225, 65), (210, 110), 
        (235, 140), (190, 160), (140, 135), (110, 125)
    ]
    d.polygon(fire_pts_outer, fill=(230, 60, 10, 240))
    
    fire_pts_mid = [
        (125, 110), (175, 90), (215, 90), (200, 120), 
        (215, 135), (180, 145), (135, 130)
    ]
    d.polygon(fire_pts_mid, fill=(255, 140, 10, 255))
    
    fire_pts_core = [
        (130, 115), (170, 105), (195, 105), (175, 125), (135, 125)
    ]
    d.polygon(fire_pts_core, fill=(255, 245, 120, 255))
    
    final_img = apply_glow_and_sticker(im, (255, 70, 0, 180))
    final_img.save("assets/sprites/weapons/weapon_dragon_breath.png")
    print("Created weapon_dragon_breath.png")

# -------------------------------------------------------------
# 4. HİÇLİK GİRDABI (weapon_void_vortex.png) - Dark Cosmic Black Hole & Swirling Purple Event Horizon
# -------------------------------------------------------------
def make_weapon_void_vortex():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 128, 128
    
    # Outer swirling spiral arms
    for arm in range(4):
        base_angle = arm * (math.pi / 2.0)
        pts = []
        for step in range(30):
            t = step / 30.0
            r = 30 + t * 75
            ang = base_angle + t * 3.5
            px = cx + math.cos(ang) * r
            py = cy + math.sin(ang) * r
            pts.append((px, py))
        for j in range(len(pts) - 1):
            w = int(2 + (j / 5.0))
            col = (int(140 + j * 3), 40, int(220 + j), 220)
            d.line([pts[j], pts[j+1]], fill=col, width=w)
            
    # Accretion Disk (glowing violet & magenta rings)
    d.ellipse([cx - 70, cy - 70, cx + 70, cy + 70], outline=(180, 50, 255, 200), width=6)
    d.ellipse([cx - 52, cy - 52, cx + 52, cy + 52], outline=(230, 100, 255, 240), width=8)
    
    # Event Horizon (Black Void Core)
    d.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=(12, 6, 22, 255), outline=(130, 20, 200, 255), width=4)
    # Gravitational eye / singularity dot
    d.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=(255, 200, 255, 255))
    
    final_img = apply_glow_and_sticker(im, (160, 32, 240, 180))
    final_img.save("assets/sprites/weapons/weapon_void_vortex.png")
    print("Created weapon_void_vortex.png")

# -------------------------------------------------------------
# 5. SAVAŞ NARASI (weapon_earthquake.png) - War Horn / Tremor Slam Crest
# -------------------------------------------------------------
def make_weapon_earthquake():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Ancient Curved Nord War Horn
    # Horn curve points
    horn_pts = [
        (50, 180), (70, 195), (105, 180), (140, 145), 
        (175, 100), (200, 70), (210, 85), (185, 125), 
        (150, 165), (110, 195), (65, 210), (45, 195)
    ]
    d.polygon(horn_pts, fill=(190, 160, 115, 255), outline=(60, 40, 20, 255))
    
    # Iron / Bronze bindings & mouth rim
    d.ellipse([185, 60, 225, 95], fill=(215, 160, 45, 255), outline=(80, 50, 10, 255), width=4)
    d.ellipse([192, 67, 218, 88], fill=(30, 20, 10, 255))
    
    # Rune bands around the horn
    d.polygon([(135, 140), (150, 125), (158, 135), (143, 150)], fill=(80, 40, 15, 255))
    d.polygon([(95, 175), (110, 160), (118, 170), (103, 185)], fill=(80, 40, 15, 255))
    
    # Soundwaves / Shockwave concentric arcs bursting from horn
    for r in [40, 65, 90]:
        d.arc([160 - r, 30 - r, 240 + r, 110 + r], start=290, end=400, fill=(255, 200, 60, 240), width=5)
        
    final_img = apply_glow_and_sticker(im, (230, 150, 30, 170))
    final_img.save("assets/sprites/weapons/weapon_earthquake.png")
    print("Created weapon_earthquake.png")

# -------------------------------------------------------------
# 6. İLAHİ GÜNEŞ MABEDİ (weapon_evo_divine_sun.png) - Legendary Radiant Sun Core
# -------------------------------------------------------------
def make_weapon_evo_divine_sun():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 128, 128
    
    # 12 Majestic Solar Flare Blades
    for i in range(12):
        ang = i * (math.pi / 6.0)
        x1 = cx + math.cos(ang) * 50
        y1 = cy + math.sin(ang) * 50
        x2 = cx + math.cos(ang) * 115
        y2 = cy + math.sin(ang) * 115
        
        orth = ang + math.pi/2
        ox = math.cos(orth) * 12
        oy = math.sin(orth) * 12
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        d.polygon([(x1, y1), (mid_x + ox, mid_y + oy), (x2, y2), (mid_x - ox, mid_y - oy)], 
                  fill=(255, 180, 20, 255), outline=(255, 240, 150, 255), width=2)
                  
    # Ornate Sacred Sanctuary Ring
    d.ellipse([cx - 65, cy - 65, cx + 65, cy + 65], fill=(255, 215, 50, 255), outline=(200, 120, 0, 255), width=5)
    d.ellipse([cx - 48, cy - 48, cx + 48, cy + 48], fill=(255, 245, 180, 255), outline=(255, 150, 0, 255), width=3)
    
    # Blazing White Divine Center with Sun Face / Cross
    d.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=(255, 255, 255, 255))
    d.line([(cx - 24, cy), (cx + 24, cy)], fill=(255, 160, 20, 255), width=4)
    d.line([(cx, cy - 24), (cx, cy + 24)], fill=(255, 160, 20, 255), width=4)
    
    final_img = apply_glow_and_sticker(im, (255, 225, 50, 210), border_width=7)
    final_img.save("assets/sprites/weapons/weapon_evo_divine_sun.png")
    print("Created weapon_evo_divine_sun.png")

# -------------------------------------------------------------
# 7. CEHENNEM KIYAMETİ (weapon_evo_hellfire_storm.png) - Demonic Obsidian Skull Flask with Magma Storm
# -------------------------------------------------------------
def make_weapon_evo_hellfire_storm():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Flask Neck & Cork bound in spiked iron
    d.rectangle([112, 35, 144, 70], fill=(40, 25, 25, 255), outline=(180, 60, 30, 255), width=3)
    d.polygon([(104, 35), (152, 35), (142, 20), (114, 20)], fill=(120, 70, 40, 255), outline=(210, 120, 40, 255))
    
    # Spiked collar
    d.polygon([(100, 65), (156, 65), (166, 80), (90, 80)], fill=(80, 20, 20, 255), outline=(240, 70, 20, 255), width=2)
    
    # Bulbous Skull Flask Body
    d.ellipse([64, 75, 192, 215], fill=(25, 12, 16, 255), outline=(220, 50, 20, 255), width=5)
    
    # Swirling Magma Liquid inside
    d.chord([72, 115, 184, 207], start=0, end=180, fill=(240, 80, 10, 255))
    d.ellipse([88, 135, 168, 195], fill=(255, 175, 20, 255))
    
    # Demonic Skull Inset (Glowing lava eyes)
    d.ellipse([100, 145, 118, 168], fill=(255, 245, 180, 255))
    d.ellipse([138, 145, 156, 168], fill=(255, 245, 180, 255))
    d.polygon([(124, 165), (132, 165), (128, 175)], fill=(30, 10, 10, 255))
    
    # Rising Hellfire plumes
    d.polygon([(115, 30), (128, 5), (141, 30)], fill=(255, 150, 0, 255))
    d.polygon([(135, 25), (150, 10), (145, 32)], fill=(255, 80, 0, 255))
    
    final_img = apply_glow_and_sticker(im, (255, 40, 10, 190), border_width=7)
    final_img.save("assets/sprites/weapons/weapon_evo_hellfire_storm.png")
    print("Created weapon_evo_hellfire_storm.png")

# -------------------------------------------------------------
# 8. KRAL CELLADI (weapon_evo_king_cleaver.png) - Colossal Bloodforged Executioner Greatsword
# -------------------------------------------------------------
def make_weapon_evo_king_cleaver():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Diagonal Greatsword blade from bottom-left to top-right
    # Massive executioner squared tip with serrated blood grooves
    blade_pts = [
        (80, 175), (170, 70), (200, 35), (220, 55), (185, 90), (105, 190)
    ]
    d.polygon(blade_pts, fill=(200, 40, 40, 255), outline=(255, 180, 180, 255), width=3)
    
    # Inner steel bevel
    inner_blade = [
        (88, 172), (168, 78), (192, 50), (205, 63), (178, 95), (102, 185)
    ]
    d.polygon(inner_blade, fill=(240, 210, 210, 255))
    d.line([(95, 180), (185, 75)], fill=(160, 20, 20, 255), width=4)
    
    # Blood drip serrations
    d.polygon([(135, 125), (155, 125), (145, 140)], fill=(180, 20, 20, 255))
    d.polygon([(160, 95), (180, 95), (170, 110)], fill=(180, 20, 20, 255))
    
    # Golden King Skull Crossguard
    d.polygon([(55, 160), (105, 210), (95, 220), (45, 170)], fill=(225, 175, 40, 255), outline=(90, 60, 10, 255), width=3)
    d.ellipse([(65, 175), (85, 195)], fill=(15, 10, 10, 255))
    
    # Leather Hilt and Ruby Pommel
    d.line([(70, 190), (40, 225)], fill=(70, 40, 20, 255), width=10)
    d.ellipse([(30, 215), (50, 235)], fill=(220, 20, 60, 255), outline=(255, 200, 50, 255), width=3)
    
    final_img = apply_glow_and_sticker(im, (230, 30, 50, 190), border_width=7)
    final_img.save("assets/sprites/weapons/weapon_evo_king_cleaver.png")
    print("Created weapon_evo_king_cleaver.png")

# -------------------------------------------------------------
# 9. FIRTINA YAYLIMI (weapon_evo_storm_quiver.png) - Electrified Tempest Recurve Bow & Triple Arrows
# -------------------------------------------------------------
def make_weapon_evo_storm_quiver():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Golden Electrified Recurve Bow Limb
    bow_pts = [
        (45, 45), (95, 75), (115, 128), (95, 181), (45, 211), 
        (55, 200), (98, 165), (108, 128), (98, 91), (55, 56)
    ]
    d.polygon(bow_pts, fill=(60, 140, 240, 255), outline=(220, 240, 255, 255), width=3)
    
    # Bowstring (crackling lightning cord)
    d.line([(45, 45), (150, 128)], fill=(180, 235, 255, 255), width=3)
    d.line([(150, 128), (45, 211)], fill=(180, 235, 255, 255), width=3)
    
    # Triple Storm Arrows nocked ready to loose
    for angle_off, col in [(-18, (120, 220, 255)), (0, (255, 255, 255)), (18, (120, 220, 255))]:
        rad = math.radians(angle_off)
        tip_x = 128 + math.cos(rad) * 90
        tip_y = 128 + math.sin(rad) * 90
        tail_x = 128 - math.cos(rad) * 30
        tail_y = 128 - math.sin(rad) * 30
        
        # shaft
        d.line([(tail_x, tail_y), (tip_x, tip_y)], fill=col, width=4)
        # arrowhead
        d.polygon([(tip_x, tip_y), (tip_x - 14, tip_y - 8), (tip_x - 8, tip_y), (tip_x - 14, tip_y + 8)], fill=(255, 240, 100, 255))
        
    final_img = apply_glow_and_sticker(im, (30, 160, 255, 190), border_width=7)
    final_img.save("assets/sprites/weapons/weapon_evo_storm_quiver.png")
    print("Created weapon_evo_storm_quiver.png")

# -------------------------------------------------------------
# 10. KOZMİK HÜKÜMDAR (weapon_evo_cosmic_archon.png) - Archon Staff of the Void & Galaxy Crystal
# -------------------------------------------------------------
def make_weapon_evo_cosmic_archon():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Deep Obsidian & Starlight Staff Shaft
    d.line([(60, 225), (150, 85)], fill=(35, 20, 50, 255), width=10)
    d.line([(60, 225), (150, 85)], fill=(160, 100, 220, 255), width=4)
    
    # Gold dragon talons holding cosmic sphere
    talons = [
        [(135, 95), (125, 60), (140, 50)],
        [(165, 80), (185, 60), (175, 45)],
        [(145, 105), (160, 115), (170, 95)]
    ]
    for t in talons:
        d.line(t, fill=(240, 190, 50, 255), width=5)
        
    # Floating Cosmic Galaxy Orb
    cx, cy = 155, 55
    d.ellipse([cx - 36, cy - 36, cx + 36, cy + 36], fill=(15, 8, 30, 255), outline=(210, 120, 255, 255), width=4)
    
    # Spiral Galaxy Nebula inside orb
    for a in range(2):
        base_ang = a * math.pi
        pts = [(cx + math.cos(base_ang + t*4)*t*24, cy + math.sin(base_ang + t*4)*t*24) for t in [i/15.0 for i in range(16)]]
        for k in range(len(pts)-1):
            d.line([pts[k], pts[k+1]], fill=(120 + k*8, 200, 255, 240), width=3)
            
    # Core pulsing pulsar star
    d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 255, 255, 255))
    
    final_img = apply_glow_and_sticker(im, (180, 50, 255, 200), border_width=7)
    final_img.save("assets/sprites/weapons/weapon_evo_cosmic_archon.png")
    print("Created weapon_evo_cosmic_archon.png")

# -------------------------------------------------------------
# 11. KUVVET TILSIMI (passive_power_talisman.png) - Red Bloodforged Viking Rune Amulet (Replacing bomb)
# -------------------------------------------------------------
def make_passive_power_talisman():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 128, 138
    
    # Chain necklace at top
    d.arc([78, 30, 178, 120], start=20, end=160, fill=(180, 160, 130, 255), width=5)
    
    # Ancient Iron Talisman Plate (Octagonal)
    d.polygon([
        (cx - 35, cy - 65), (cx + 35, cy - 65), (cx + 65, cy - 35), (cx + 65, cy + 35),
        (cx + 35, cy + 65), (cx - 35, cy + 65), (cx - 65, cy + 35), (cx - 65, cy - 35)
    ], fill=(30, 25, 30, 255), outline=(190, 50, 40, 255), width=6)
    
    # Inset Glowing Crimson Power Rune (Uruz / Strength Sigil)
    d.line([(cx, cy - 42), (cx, cy + 42)], fill=(255, 60, 50, 255), width=8)
    d.line([(cx - 28, cy - 25), (cx, cy - 42)], fill=(255, 60, 50, 255), width=8)
    d.line([(cx - 28, cy - 25), (cx - 28, cy + 42)], fill=(255, 60, 50, 255), width=8)
    d.line([(cx + 28, cy + 10), (cx, cy + 42)], fill=(255, 60, 50, 255), width=8)
    
    # Center molten bright core
    d.line([(cx, cy - 35), (cx, cy + 35)], fill=(255, 230, 200, 255), width=3)
    
    final_img = apply_glow_and_sticker(im, (255, 40, 40, 180), border_width=6)
    final_img.save("assets/sprites/passives/passive_power_talisman.png")
    final_img.save("assets/sprites/passives/passive_bomb.png") # backward compatibility
    print("Created passive_power_talisman.png")

# -------------------------------------------------------------
# 12. TAŞ MASKE (passive_stone_mask.png) - Ancient Aztec/Vampire Stone Mask (Replacing piggy bank)
# -------------------------------------------------------------
def make_passive_stone_mask():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 128, 128
    
    # Weathered Grey Crypt Stone Face Outline
    mask_pts = [
        (cx - 55, cy - 75), (cx + 55, cy - 75), (cx + 65, cy - 10), 
        (cx + 45, cy + 65), (cx, cy + 85), (cx - 45, cy + 65), (cx - 65, cy - 10)
    ]
    d.polygon(mask_pts, fill=(110, 115, 125, 255), outline=(45, 50, 58, 255), width=5)
    
    # Brow ridge & Forehead Runes
    d.line([(cx - 45, cy - 45), (cx + 45, cy - 45)], fill=(60, 65, 75, 255), width=5)
    d.line([(cx - 30, cy - 60), (cx + 30, cy - 60)], fill=(215, 175, 40, 255), width=3)
    
    # Hollow Menacing Eye Sockets with Glowing Golden Coins inside
    d.polygon([(cx - 42, cy - 32), (cx - 18, cy - 32), (cx - 24, cy - 12), (cx - 38, cy - 12)], fill=(20, 22, 28, 255))
    d.polygon([(cx + 18, cy - 32), (cx + 42, cy - 32), (cx + 38, cy - 12), (cx + 24, cy - 12)], fill=(20, 22, 28, 255))
    d.ellipse([(cx - 34, cy - 26), (cx - 26, cy - 18)], fill=(255, 215, 50, 255))
    d.ellipse([(cx + 26, cy - 26), (cx + 34, cy - 18)], fill=(255, 215, 50, 255))
    
    # Chiseled Stone Nose & Stern Mouth
    d.polygon([(cx, cy - 25), (cx + 8, cy + 18), (cx - 8, cy + 18)], fill=(75, 80, 90, 255))
    d.rectangle([cx - 25, cy + 35, cx + 25, cy + 45], fill=(30, 32, 38, 255))
    
    # Gold coins pouring / tear marks
    d.line([(cx - 30, cy - 8), (cx - 30, cy + 50)], fill=(235, 185, 30, 255), width=3)
    d.line([(cx + 30, cy - 8), (cx + 30, cy + 50)], fill=(235, 185, 30, 255), width=3)
    
    final_img = apply_glow_and_sticker(im, (230, 180, 30, 170), border_width=6)
    final_img.save("assets/sprites/passives/passive_stone_mask.png")
    final_img.save("assets/sprites/passives/passive_piggy_bank.png") # backward compatibility
    print("Created passive_stone_mask.png")

# -------------------------------------------------------------
# 13. TORRONA'NIN KUTUSU (passive_torronas_box.png) - Ornate Eldritch Reliquary Chest (Replacing origami)
# -------------------------------------------------------------
def make_passive_torronas_box():
    im = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 128, 128
    
    # Eldritch Purple Reliquary Chest (Isometric perspective)
    # Chest base
    d.polygon([
        (cx - 65, cy + 5), (cx + 65, cy + 5), (cx + 75, cy + 70), (cx - 75, cy + 70)
    ], fill=(45, 20, 60, 255), outline=(210, 160, 40, 255), width=5)
    
    # Chest curved lid
    d.polygon([
        (cx - 70, cy + 5), (cx - 45, cy - 45), (cx + 45, cy - 45), (cx + 70, cy + 5)
    ], fill=(70, 30, 90, 255), outline=(230, 185, 50, 255), width=5)
    
    # Golden Filigree Trim and Corners
    d.polygon([(cx - 70, cy + 5), (cx - 50, cy + 5), (cx - 60, cy + 25)], fill=(230, 185, 50, 255))
    d.polygon([(cx + 70, cy + 5), (cx + 50, cy + 5), (cx + 60, cy + 25)], fill=(230, 185, 50, 255))
    
    # Center Demon Lock / Eye of Torrona
    d.ellipse([cx - 24, cy - 10, cx + 24, cy + 22], fill=(20, 10, 30, 255), outline=(255, 215, 60, 255), width=3)
    d.ellipse([cx - 14, cy - 4, cx + 14, cy + 16], fill=(220, 40, 60, 255))
    d.line([(cx, cy - 4), (cx, cy + 16)], fill=(255, 240, 200, 255), width=3) # Slit pupil
    
    # Radiant violet aura leaking from chest seams
    d.line([(cx - 65, cy + 5), (cx + 65, cy + 5)], fill=(200, 80, 255, 255), width=4)
    
    final_img = apply_glow_and_sticker(im, (180, 50, 230, 180), border_width=6)
    final_img.save("assets/sprites/passives/passive_torronas_box.png")
    final_img.save("assets/sprites/passives/passive_origami_box.png") # backward compatibility
    print("Created passive_torronas_box.png")

if __name__ == "__main__":
    print("Generating all 13 dark fantasy weapon & passive sprites...")
    make_weapon_aura()
    make_weapon_lightning()
    make_weapon_dragon_breath()
    make_weapon_void_vortex()
    make_weapon_earthquake()
    make_weapon_evo_divine_sun()
    make_weapon_evo_hellfire_storm()
    make_weapon_evo_king_cleaver()
    make_weapon_evo_storm_quiver()
    make_weapon_evo_cosmic_archon()
    make_passive_power_talisman()
    make_passive_stone_mask()
    make_passive_torronas_box()
    print("All sprites successfully generated!")
