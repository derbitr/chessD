import os
from PIL import Image, ImageDraw, ImageFilter

def draw_pawn_master(size=512):
    # Create image with transparent background
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background rounded rectangle (Squircle)
    margin = int(size * 0.05)
    rect_box = [margin, margin, size - margin, size - margin]
    radius = int(size * 0.22)

    # 1. Background gradient layer
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)

    # Draw dark rounded squircle
    bg_draw.rounded_rectangle(rect_box, radius=radius, fill=(15, 23, 42, 255), outline=(0, 229, 255, 120), width=int(size * 0.025))

    # Inner subtle glow/ring
    inner_box = [margin + int(size * 0.03), margin + int(size * 0.03), size - margin - int(size * 0.03), size - margin - int(size * 0.03)]
    bg_draw.rounded_rectangle(inner_box, radius=int(radius * 0.85), outline=(0, 229, 255, 40), width=int(size * 0.01))

    img = Image.alpha_composite(img, bg)

    # 2. Draw Pawn Glow Layer
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)

    w = size
    h = size
    cx = w * 0.5

    # Coordinates for Pawn elements (relative to size)
    # Head
    head_r = w * 0.125
    head_cy = h * 0.29
    glow_draw.ellipse([cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r], fill=(0, 229, 255, 160))

    # Collar
    collar_w = w * 0.24
    collar_h = h * 0.045
    collar_y = h * 0.42
    glow_draw.rounded_rectangle([cx - collar_w/2, collar_y, cx + collar_w/2, collar_y + collar_h], radius=int(collar_h/2), fill=(0, 229, 255, 160))

    # Torso (Polygon approximating elegant curved body)
    torso_top_w = w * 0.16
    torso_bot_w = w * 0.38
    torso_top_y = collar_y + collar_h * 0.8
    torso_bot_y = h * 0.67

    # Smooth curve points
    torso_points = [
        (cx - torso_top_w/2, torso_top_y),
        (cx - torso_top_w*0.4, torso_top_y + (torso_bot_y - torso_top_y)*0.35),
        (cx - torso_bot_w*0.35, torso_top_y + (torso_bot_y - torso_top_y)*0.7),
        (cx - torso_bot_w/2, torso_bot_y),
        (cx + torso_bot_w/2, torso_bot_y),
        (cx + torso_bot_w*0.35, torso_top_y + (torso_bot_y - torso_top_y)*0.7),
        (cx + torso_top_w*0.4, torso_top_y + (torso_bot_y - torso_top_y)*0.35),
        (cx + torso_top_w/2, torso_top_y),
    ]
    glow_draw.polygon(torso_points, fill=(0, 229, 255, 160))

    # Base Tier Ring
    tier_w = w * 0.44
    tier_h = h * 0.05
    tier_y = h * 0.67
    glow_draw.rounded_rectangle([cx - tier_w/2, tier_y, cx + tier_w/2, tier_y + tier_h], radius=int(tier_h/2), fill=(0, 229, 255, 160))

    # Pedestal
    ped_w = w * 0.54
    ped_h = h * 0.065
    ped_y = tier_y + tier_h * 0.9
    glow_draw.rounded_rectangle([cx - ped_w/2, ped_y, cx + ped_w/2, ped_y + ped_h], radius=int(ped_h/2), fill=(0, 229, 255, 160))

    # Blur glow
    glow = glow.filter(ImageFilter.GaussianBlur(radius=int(size * 0.04)))
    img = Image.alpha_composite(img, glow)

    # 3. Draw Solid Crisp Pawn
    pawn = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pawn_draw = ImageDraw.Draw(pawn)

    pawn_color = (0, 229, 255, 255) # Electric Cyan primary
    pawn_draw.ellipse([cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r], fill=pawn_color)
    pawn_draw.rounded_rectangle([cx - collar_w/2, collar_y, cx + collar_w/2, collar_y + collar_h], radius=int(collar_h/2), fill=pawn_color)
    pawn_draw.polygon(torso_points, fill=pawn_color)
    pawn_draw.rounded_rectangle([cx - tier_w/2, tier_y, cx + tier_w/2, tier_y + tier_h], radius=int(tier_h/2), fill=pawn_color)
    pawn_draw.rounded_rectangle([cx - ped_w/2, ped_y, cx + ped_w/2, ped_y + ped_h], radius=int(ped_h/2), fill=pawn_color)

    # 4. Highlight reflection layer (gives 3D glossy Staunton feel)
    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hl_draw = ImageDraw.Draw(highlight)

    # Highlight on head (top-left glint)
    hl_head_r = head_r * 0.45
    hl_draw.ellipse([cx - head_r*0.6, head_cy - head_r*0.6, cx - head_r*0.6 + hl_head_r, head_cy - head_r*0.6 + hl_head_r], fill=(255, 255, 255, 170))

    # Highlight along left side of torso
    hl_torso_points = [
        (cx - torso_top_w*0.35, torso_top_y + 4),
        (cx - torso_top_w*0.25, torso_top_y + (torso_bot_y - torso_top_y)*0.4),
        (cx - torso_bot_w*0.25, torso_top_y + (torso_bot_y - torso_top_y)*0.7),
        (cx - torso_bot_w*0.35, torso_bot_y - 4),
        (cx - torso_bot_w*0.42, torso_bot_y - 4),
        (cx - torso_bot_w*0.32, torso_top_y + (torso_bot_y - torso_top_y)*0.7),
        (cx - torso_top_w*0.35, torso_top_y + (torso_bot_y - torso_top_y)*0.4),
        (cx - torso_top_w*0.45, torso_top_y + 4),
    ]
    hl_draw.polygon(hl_torso_points, fill=(255, 255, 255, 110))

    # Base highlight
    hl_draw.rounded_rectangle([cx - ped_w*0.42, ped_y + 3, cx + ped_w*0.42, ped_y + int(ped_h*0.35)], radius=3, fill=(255, 255, 255, 90))

    pawn = Image.alpha_composite(pawn, highlight)
    img = Image.alpha_composite(img, pawn)

    return img

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print("Generating Master 512x512 Pawn Icon...")
    master = draw_pawn_master(512)

    # 1. Windows app_icon.ico (contains 256, 128, 64, 48, 32, 16)
    win_icon_path = os.path.join(base_dir, "windows", "runner", "resources", "app_icon.ico")
    print(f"Saving Windows ICO to: {win_icon_path}")
    icon_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    master.save(win_icon_path, format="ICO", sizes=icon_sizes)

    # 2. Android mipmap icons
    android_res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")
    mipmap_configs = [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]

    for folder, dim in mipmap_configs:
        target_folder = os.path.join(android_res_dir, folder)
        os.makedirs(target_folder, exist_ok=True)
        target_path = os.path.join(target_folder, "ic_launcher.png")
        resized = master.resize((dim, dim), Image.Resampling.LANCZOS)
        resized.save(target_path, "PNG")
        print(f"Generated Android {folder} ({dim}x{dim}): {target_path}")

    # Also save a high-res asset in assets/icons/ for general use
    assets_icon_dir = os.path.join(base_dir, "assets", "icons")
    os.makedirs(assets_icon_dir, exist_ok=True)
    master.save(os.path.join(assets_icon_dir, "chessd_pawn_logo.png"), "PNG")
    print("All Pawn logos and app launcher icons successfully generated!")

if __name__ == "__main__":
    main()
