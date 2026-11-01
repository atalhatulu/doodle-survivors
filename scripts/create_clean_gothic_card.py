"""
Creates clean, elegant, high-contrast dark gothic character selection card backgrounds:
- Dark obsidian/slate stone base with subtle inner gradient
- Ornate thin aged brass / gold filigree corner brackets and borders
- Clear, readable, dark center area for crisp text and stat display
"""
from PIL import Image, ImageDraw

def create_gothic_card(width=340, height=480):
    im = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # 1. Dark charcoal/slate stone rounded rectangle body
    d.rounded_rectangle([6, 6, width - 6, height - 6], radius=12, fill=(18, 15, 22, 245), outline=(15, 12, 18, 255), width=2)
    
    # 2. Inner subtle dark gradient vignette
    d.rounded_rectangle([14, 14, width - 14, height - 14], radius=8, fill=(24, 20, 30, 230), outline=(65, 52, 38, 255), width=2)
    
    # 3. Aged brass / antique gold ornate inner frame
    d.rounded_rectangle([18, 18, width - 18, height - 18], radius=6, outline=(180, 140, 55, 240), width=2)
    d.rounded_rectangle([22, 22, width - 22, height - 22], radius=4, outline=(110, 85, 30, 180), width=1)
    
    # 4. Ornate brass corner brackets
    c_size = 24
    corners = [
        # Top-left
        [(18, 18), (18 + c_size, 18), (18, 18 + c_size)],
        # Top-right
        [(width - 18, 18), (width - 18 - c_size, 18), (width - 18, 18 + c_size)],
        # Bottom-left
        [(18, height - 18), (18 + c_size, height - 18), (18, height - 18 - c_size)],
        # Bottom-right
        [(width - 18, height - 18), (width - 18 - c_size, height - 18), (width - 18, height - 18 - c_size)]
    ]
    for c in corners:
        d.polygon(c, fill=(215, 175, 75, 255), outline=(130, 95, 35, 255))
        
    # 5. Top header divider and portrait plate
    d.line([(26, 62), (width - 26, 62)], fill=(160, 125, 50, 200), width=2)
    
    # 6. Center parchment inset for stats (high contrast, perfectly clean)
    d.rounded_rectangle([26, 175, width - 26, height - 70], radius=6, fill=(12, 10, 15, 240), outline=(140, 110, 45, 180), width=1)
    
    im.save("assets/sprites/ui/parchment_clean.png")
    im.save("assets/sprites/ui/ui_card_obsidian.png")
    im.save("assets/sprites/ui/gothic_char_card.png")
    print("Created clean gothic character selection card backgrounds!")

if __name__ == "__main__":
    create_gothic_card()
