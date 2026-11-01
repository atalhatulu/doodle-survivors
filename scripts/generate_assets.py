import os
import math
from PIL import Image, ImageDraw

os.makedirs("assets/sprites/characters", exist_ok=True)
os.makedirs("assets/sprites/weapons", exist_ok=True)
os.makedirs("assets/sprites/entities", exist_ok=True)
os.makedirs("assets/sprites/props", exist_ok=True)

def draw_sticker_outline(draw_img, points, fill_color, outline_color, outline_width=4):
    # Draw thicker outline then inner fill
    pass

# 1. Necromancer Portrait (128x128) - Dark hooded robed sorcerer with glowing cyan-green eyes and skull amulet
def create_necromancer_sprite():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Outer sticker white border (drawn with multiple layered shapes)
    # Hood & Cloak
    draw.polygon([(64, 14), (24, 76), (28, 114), (100, 114), (104, 76)], fill=(255, 255, 255, 255))
    draw.polygon([(64, 18), (28, 76), (32, 110), (96, 110), (100, 76)], fill=(32, 28, 44, 255))
    
    # Hood shadow / Inner face void
    draw.ellipse([(44, 40), (84, 82)], fill=(15, 12, 22, 255))
    
    # Glowing Eerie Spectral Green/Cyan Eyes
    draw.ellipse([(50, 56), (58, 64)], fill=(120, 255, 180, 255))
    draw.ellipse([(70, 56), (78, 64)], fill=(120, 255, 180, 255))
    draw.ellipse([(52, 58), (56, 62)], fill=(220, 255, 240, 255))
    draw.ellipse([(72, 58), (76, 62)], fill=(220, 255, 240, 255))
    
    # Bone necklace / clasp
    draw.polygon([(64, 86), (56, 96), (64, 106), (72, 96)], fill=(240, 235, 220, 255))
    draw.ellipse([(60, 92), (68, 100)], fill=(40, 180, 120, 255))
    
    # Robe folds
    draw.line([(64, 106), (64, 114)], fill=(15, 12, 22, 255), width=2)
    draw.line([(44, 90), (36, 114)], fill=(15, 12, 22, 255), width=2)
    draw.line([(84, 90), (92, 114)], fill=(15, 12, 22, 255), width=2)
    
    img.save("assets/sprites/characters/char_necromancer.png")
    print("Created char_necromancer.png")

# 2. Spirit Wolf Sprite (128x128) - Ethereal ghostly wolf with glowing eyes, ears, snout, and ghostly trails
def create_spirit_wolf_sprite():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # White sticker border for wolf body
    # Snout pointing right
    body_pts_white = [
        (20, 70), (35, 45), (55, 30), (65, 15), (75, 35), (85, 20), (92, 40), 
        (116, 52), (105, 68), (85, 78), (95, 105), (80, 108), (70, 85), 
        (50, 86), (40, 106), (26, 104), (32, 78), (14, 82)
    ]
    draw.polygon(body_pts_white, fill=(255, 255, 255, 255))
    
    # Inset body - Ethereal Cyan/Blue
    body_pts = [
        (24, 68), (38, 48), (56, 34), (65, 22), (73, 38), (83, 26), (89, 42), 
        (110, 53), (100, 66), (82, 75), (91, 100), (81, 103), (72, 82), 
        (52, 83), (43, 101), (30, 99), (35, 76), (18, 80)
    ]
    draw.polygon(body_pts, fill=(50, 180, 240, 230))
    
    # Fur highlights and spectral markings
    draw.line([(55, 45), (75, 55)], fill=(180, 240, 255, 255), width=2)
    draw.line([(60, 60), (80, 70)], fill=(180, 240, 255, 255), width=2)
    
    # Ethereal Wolf Eye
    draw.polygon([(82, 48), (90, 50), (85, 54)], fill=(255, 255, 255, 255))
    draw.ellipse([(85, 49), (88, 52)], fill=(100, 255, 240, 255))
    
    # Snout nose
    draw.ellipse([(106, 52), (111, 57)], fill=(20, 60, 100, 255))
    
    img.save("assets/sprites/weapons/spirit_wolf.png")
    print("Created spirit_wolf.png")

# 3. Minion Skeleton Sprite (128x128) - Cute/scary dark fantasy miniature skeleton warrior
def create_minion_skeleton_sprite():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Sticker outline
    draw.ellipse([(36, 16), (92, 70)], fill=(255, 255, 255, 255))
    draw.rectangle([(50, 64), (78, 114)], fill=(255, 255, 255, 255))
    draw.polygon([(78, 50), (112, 20), (116, 26), (84, 60)], fill=(255, 255, 255, 255)) # Sword arm
    
    # Skull
    draw.ellipse([(40, 20), (88, 66)], fill=(235, 230, 215, 255))
    # Eye sockets
    draw.ellipse([(48, 36), (60, 50)], fill=(20, 20, 30, 255))
    draw.ellipse([(68, 36), (80, 50)], fill=(20, 20, 30, 255))
    # Glowing green pinprick eyes
    draw.ellipse([(52, 41), (56, 45)], fill=(80, 255, 120, 255))
    draw.ellipse([(72, 41), (76, 45)], fill=(80, 255, 120, 255))
    # Nose & Teeth
    draw.polygon([(62, 50), (66, 50), (64, 54)], fill=(20, 20, 30, 255))
    draw.line([(52, 60), (76, 60)], fill=(40, 40, 40, 255), width=2)
    draw.line([(58, 58), (58, 62)], fill=(40, 40, 40, 255), width=1)
    draw.line([(64, 58), (64, 62)], fill=(40, 40, 40, 255), width=1)
    draw.line([(70, 58), (70, 62)], fill=(40, 40, 40, 255), width=1)
    
    # Ribcage / Spine
    draw.rectangle([(54, 68), (74, 100)], fill=(220, 215, 200, 255))
    draw.line([(56, 74), (72, 74)], fill=(40, 35, 30, 255), width=2)
    draw.line([(56, 82), (72, 82)], fill=(40, 35, 30, 255), width=2)
    draw.line([(56, 90), (72, 90)], fill=(40, 35, 30, 255), width=2)
    
    # Legs
    draw.line([(58, 100), (52, 114)], fill=(235, 230, 215, 255), width=4)
    draw.line([(70, 100), (76, 114)], fill=(235, 230, 215, 255), width=4)
    
    # Rusty Bone Blade
    draw.polygon([(82, 54), (110, 24), (114, 28), (86, 60)], fill=(140, 145, 155, 255))
    draw.polygon([(108, 22), (116, 26), (110, 30)], fill=(210, 215, 225, 255))
    
    img.save("assets/sprites/entities/minion_skeleton.png")
    print("Created minion_skeleton.png")

# 4. Pact Shrine Sprite (128x128) - Ancient dark stone altar with floating glowing runes
def create_pact_shrine_sprite():
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # White die-cut outline
    draw.polygon([(24, 118), (104, 118), (96, 76), (104, 74), (98, 48), (64, 20), (30, 48), (24, 74), (32, 76)], fill=(255, 255, 255, 255))
    
    # Dark stone pedestal
    draw.polygon([(28, 114), (100, 114), (92, 78), (36, 78)], fill=(45, 42, 52, 255))
    # Stone texture cracks
    draw.line([(45, 82), (52, 105)], fill=(25, 22, 32, 255), width=2)
    draw.line([(78, 86), (72, 110)], fill=(25, 22, 32, 255), width=2)
    
    # Altar top
    draw.polygon([(26, 76), (102, 76), (96, 52), (32, 52)], fill=(65, 60, 75, 255))
    
    # Floating Runestone Obelisk
    draw.polygon([(34, 50), (64, 24), (94, 50), (64, 68)], fill=(38, 35, 48, 255))
    
    # Glowing Blood/Runic Sigil
    draw.polygon([(64, 32), (54, 44), (64, 56), (74, 44)], fill=(255, 50, 70, 255))
    draw.polygon([(64, 36), (58, 44), (64, 52), (70, 44)], fill=(255, 180, 190, 255))
    
    img.save("assets/sprites/props/pact_shrine.png")
    print("Created pact_shrine.png")

if __name__ == "__main__":
    create_necromancer_sprite()
    create_spirit_wolf_sprite()
    create_minion_skeleton_sprite()
    create_pact_shrine_sprite()
