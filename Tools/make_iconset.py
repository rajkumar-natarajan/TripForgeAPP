import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SET = os.path.join(os.path.dirname(HERE), "TripForge", "Assets.xcassets", "AppIcon.appiconset")
master = Image.open(os.path.join(SET, "AppIcon-1024.png")).convert("RGB")

# (size_pt, scale, idiom, filename)
specs = [
    (20, 2, "iphone", "Icon-20@2x.png"),
    (20, 3, "iphone", "Icon-20@3x.png"),
    (29, 2, "iphone", "Icon-29@2x.png"),
    (29, 3, "iphone", "Icon-29@3x.png"),
    (40, 2, "iphone", "Icon-40@2x.png"),
    (40, 3, "iphone", "Icon-40@3x.png"),
    (60, 2, "iphone", "Icon-60@2x.png"),
    (60, 3, "iphone", "Icon-60@3x.png"),
    (20, 1, "ipad", "Icon-20~ipad.png"),
    (20, 2, "ipad", "Icon-20@2x~ipad.png"),
    (29, 1, "ipad", "Icon-29~ipad.png"),
    (29, 2, "ipad", "Icon-29@2x~ipad.png"),
    (40, 1, "ipad", "Icon-40~ipad.png"),
    (40, 2, "ipad", "Icon-40@2x~ipad.png"),
    (76, 2, "ipad", "Icon-76@2x~ipad.png"),
    (83.5, 2, "ipad", "Icon-83.5@2x~ipad.png"),
]

# De-dup identical pixel sizes -> filename map
made = {}
images_json = []
for pt, scale, idiom, fname in specs:
    px = int(round(pt * scale))
    if px not in made:
        img = master.resize((px, px), Image.LANCZOS)
        img.save(os.path.join(SET, fname), "PNG")
        made[px] = fname
    # size string like "20x20", "83.5x83.5"
    size_str = f"{pt:g}x{pt:g}"
    images_json.append({
        "size": size_str,
        "idiom": idiom,
        "filename": made[px],
        "scale": f"{scale}x",
    })

# App Store marketing icon (this is what App Store Connect / TestFlight displays)
images_json.append({
    "size": "1024x1024",
    "idiom": "ios-marketing",
    "filename": "AppIcon-1024.png",
    "scale": "1x",
})

import json
contents = {"images": images_json, "info": {"author": "xcode", "version": 1}}
with open(os.path.join(SET, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)
    f.write("\n")

print("generated", len(made), "unique sizes +", "marketing 1024")
print("wrote Contents.json with", len(images_json), "entries")
