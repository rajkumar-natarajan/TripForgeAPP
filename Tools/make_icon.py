import math
from PIL import Image, ImageDraw, ImageFilter

S = 1024
# Brand colors
TEAL = (0x0F, 0x76, 0x6E)
TEAL_L = (0x33, 0xBB, 0xAB)
ORANGE = (0xF9, 0x73, 0x16)

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# Diagonal gradient teal (top-left) -> orange (bottom-right), like Brand.brandGradient
img = Image.new("RGB", (S, S), TEAL)
px = img.load()
for y in range(S):
    for x in range(S):
        # position along the top-left -> bottom-right diagonal
        t = (x + y) / (2 * (S - 1))
        # ease slightly toward a richer mid using teal-light in the middle
        if t < 0.5:
            c = lerp(TEAL, TEAL_L, t / 0.5 * 0.6)
        else:
            c = lerp(TEAL_L, ORANGE, (t - 0.5) / 0.5)
        px[x, y] = c

draw = ImageDraw.Draw(img, "RGBA")

# Soft radial glow highlight (top-left) for depth
glow = Image.new("L", (S, S), 0)
gd = ImageDraw.Draw(glow)
cx, cy, r = S * 0.30, S * 0.26, S * 0.60
for i in range(60, 0, -1):
    rr = r * i / 60
    alpha = int(60 * (i / 60) ** 1.6)
    gd.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=alpha)
glow = glow.filter(ImageFilter.GaussianBlur(S * 0.06))
white_layer = Image.new("RGBA", (S, S), (255, 255, 255, 255))
img_rgba = img.convert("RGBA")
img_rgba = Image.composite(white_layer, img_rgba, glow.point(lambda a: min(a, 60)))
img = img_rgba.convert("RGB")
draw = ImageDraw.Draw(img, "RGBA")

# --- Navigation arrow (matches location.north.circle.fill vibe) ---
# A crisp white paper-plane / north arrow, centered.
center = (S / 2, S / 2 + S * 0.01)
scale = S * 0.30

def rot(px_, py_, ang):
    ca, sa = math.cos(ang), math.sin(ang)
    return (px_ * ca - py_ * sa, px_ * sa + py_ * ca)

# Arrow pointing up (north). Two-tone: solid white with a subtle inner split.
tip = (0, -1.0)
left = (-0.72, 0.72)
right = (0.72, 0.72)
notch = (0, 0.34)  # concave base -> gives the classic navigation arrow

pts = [tip, right, notch, left]
poly = [(center[0] + p[0] * scale, center[1] + p[1] * scale) for p in pts]

# Drop shadow
shadow = [(x + S * 0.012, y + S * 0.018) for (x, y) in poly]
draw.polygon(shadow, fill=(0, 0, 0, 60))
# White arrow
draw.polygon(poly, fill=(255, 255, 255, 255))

# Subtle darker right-half to give dimension (like the filled compass needle)
right_half = [tip, right, notch]
rh = [(center[0] + p[0] * scale, center[1] + p[1] * scale) for p in right_half]
draw.polygon(rh, fill=(230, 240, 238, 90))

import os
_out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                    "TripForge", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png")
img.save(_out, "PNG")
print("wrote", _out)
