"""Rebuild the TrustworthySDM hex logo, favicons, and prove nothing spills out.

Why this exists: the first logo put the wordmark at a baseline where the
hexagon is only +/-64 px wide, while "TrustworthySDM" at 50 px is +/-211 px.
The M was clipped. The wordmark is now two lines, sized to fit, and this
script FAILS if any ink lands outside the hexagon.

The wordmark is stored as glyph outlines (compressed below), not as a
font-family reference: this Mac has no DejaVu Sans, and a substituted font
would change the width and re-open the same bug.

Run from the repo root:   python3 dev/logo/relogo.py
"""
import base64, os, shutil, subprocess, sys, zlib

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
import hexgen as HX
import crayfish as CF

VARIANT = "D"          # <-- change to A, B or C to swap the design
W, H, CX = HX.W, HX.H, HX.CX

WORDMARK = zlib.decompress(base64.b64decode(
    "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"
)).decode()

DEFS = '''  <defs>
    <linearGradient id="bg" x1=".15" y1="0" x2=".75" y2="1">
      <stop offset="0%" stop-color="#14606F"/><stop offset="48%" stop-color="#0B3F4C"/>
      <stop offset="100%" stop-color="#05252E"/></linearGradient>
    <linearGradient id="river" x1=".5" y1="1" x2=".5" y2=".1">
      <stop offset="0%" stop-color="#3E9CB0"/><stop offset="50%" stop-color="#6FCEC9"/>
      <stop offset="100%" stop-color="#B4F0E2"/></linearGradient>
    <linearGradient id="shell" x1=".3" y1="0" x2=".7" y2="1">
      <stop offset="0%" stop-color="#FFB07A"/><stop offset="55%" stop-color="#FF8C50"/>
      <stop offset="100%" stop-color="#E0653A"/></linearGradient>
    <radialGradient id="glow" cx=".5" cy=".5" r=".5">
      <stop offset="0%" stop-color="#FF8C50" stop-opacity=".6"/>
      <stop offset="60%" stop-color="#FF8C50" stop-opacity=".18"/>
      <stop offset="100%" stop-color="#FF8C50" stop-opacity="0"/></radialGradient>
    <linearGradient id="scrim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#04222A" stop-opacity="0"/>
      <stop offset="45%" stop-color="#04222A" stop-opacity=".8"/>
      <stop offset="100%" stop-color="#04222A" stop-opacity=".94"/></linearGradient>
    <clipPath id="hc"><path d="__CLIP__"/></clipPath>
  </defs>'''


def build_svg(variant, seed=8):
    segs, kept, dropped = HX.build(seed)
    outer = HX.path_of(HX.hex_pts(0))
    inner = HX.path_of(HX.hex_pts(11))
    clipp = HX.path_of(HX.hex_pts(8))

    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
         DEFS.replace("__CLIP__", clipp),
         f'  <path d="{outer}" fill="url(#bg)"/>', '  <g clip-path="url(#hc)">']

    for r, op in ((330, .07), (262, .06), (196, .05), (132, .045), (74, .04)):
        o.append(f'    <ellipse cx="{CX}" cy="{HX.CY+62:.0f}" rx="{r}" ry="{r*.8:.0f}" '
                 f'fill="none" stroke="#9EE4E8" stroke-opacity="{op}" stroke-width="2"/>')

    def net(shadow=True, op=1.0):
        out = []
        if shadow:
            out.append('    <g fill="none" stroke="#04222A" stroke-linecap="round" stroke-opacity=".55">')
            out += [f'      <path d="{d}" stroke-width="{w+5:.1f}"/>' for w, d in segs]
            out.append("    </g>")
        out.append(f'    <g fill="none" stroke="url(#river)" stroke-linecap="round" opacity="{op}">')
        out += [f'      <path d="{d}" stroke-width="{w:.1f}"/>' for w, d in segs]
        out.append("    </g>")
        return out

    def points():
        out = ['    <g fill="#0A3A46" stroke="#63A3B0" stroke-width="3">']
        out += [f'      <circle cx="{x:.1f}" cy="{y:.1f}" r="8.5"/>' for x, y in dropped]
        out.append("    </g>")
        out += [f'    <circle cx="{x:.1f}" cy="{y:.1f}" r="30" fill="url(#glow)"/>' for x, y in kept]
        out.append('    <g fill="#FF8C50" stroke="#08303B" stroke-width="2.4">')
        out += [f'      <circle cx="{x:.1f}" cy="{y:.1f}" r="11"/>' for x, y in kept]
        out.append("    </g>")
        return out

    if variant == "A":                       # network only
        o += net(); o += points()
    elif variant == "B":                     # crayfish as a shadow under the network
        o.append(CF.render(scale=268, tx=CX, ty=150, fill="#031C24", opacity=.72))
        o.append(CF.render(scale=260, tx=CX, ty=152, fill="#0B4655", opacity=.85))
        o += net(); o += points()
    elif variant == "C":                     # coral crayfish, hero
        o += net(shadow=False, op=.55)
        o.append(CF.render(scale=268, tx=CX, ty=150, fill="#052029", opacity=.6))
        o.append(CF.render(scale=260, tx=CX, ty=148, fill="url(#shell)"))
        o += points()
    else:                                    # D: light crayfish, coral dots carry the story
        o += net(op=.85)
        o.append(CF.render(scale=268, tx=CX, ty=150, fill="#04222A", opacity=.55))
        o.append(CF.render(scale=260, tx=CX, ty=148, fill="#CFF2EA", opacity=.93))
        o += points()

    o.append(f'    <rect x="0" y="415" width="{W}" height="185" fill="url(#scrim)"/>')
    o.append("  </g>")
    o.append(f'  <path d="{outer}" fill="none" stroke="#062831" stroke-width="16"/>')
    o.append(f'  <path d="{inner}" fill="none" stroke="#8FE3D3" stroke-width="5" stroke-opacity=".92"/>')
    o.append(WORDMARK)
    o.append("</svg>")
    return "\n".join(o)


def rasterise(svg_path, png_path, w, h):
    """rsvg-convert if present, else cairosvg. Both handle gradients + clips."""
    if shutil.which("rsvg-convert"):
        subprocess.run(["rsvg-convert", "-w", str(w), "-h", str(h),
                        svg_path, "-o", png_path], check=True)
        return "rsvg-convert"
    try:
        import cairosvg
    except ImportError:
        sys.exit("Need a rasteriser. Either:  brew install librsvg\n"
                 "                       or:  pip install cairosvg  (+ brew install cairo)")
    cairosvg.svg2png(url=svg_path, write_to=png_path, output_width=w, output_height=h)
    return "cairosvg"


def escaped_ink(png_path):
    """Furthest any inked pixel sits outside the hexagon. The border stroke is
    16 px wide and centred on the boundary, so up to ~8 px is legitimate."""
    import numpy as np
    from PIL import Image
    im = np.array(Image.open(png_path).convert("RGBA"))
    h, w = im.shape[:2]
    a, b = w / 2.0, h / 2.0
    ys, xs = np.mgrid[0:h, 0:w]
    U, V = np.abs(xs - a), np.abs(ys - b)
    d = np.maximum(U - a, (b * U + 2 * a * V - 2 * a * b) / (b ** 2 + 4 * a ** 2) ** 0.5)
    e = d[im[:, :, 3] > 12]
    return float(e.max()), int((e > 12).sum())


def favicons(logo_png):
    from PIL import Image
    m = Image.open(logo_png).convert("RGBA")
    side = max(m.size)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(m, ((side - m.width) // 2, (side - m.height) // 2), m)
    out = "pkgdown/favicon"
    os.makedirs(out, exist_ok=True)
    for name, px in [("favicon-16x16.png", 16), ("favicon-32x32.png", 32),
                     ("apple-touch-icon-60x60.png", 60), ("apple-touch-icon-76x76.png", 76),
                     ("apple-touch-icon-120x120.png", 120), ("apple-touch-icon-152x152.png", 152),
                     ("apple-touch-icon-180x180.png", 180), ("apple-touch-icon.png", 180)]:
        sq.resize((px, px), Image.LANCZOS).save(os.path.join(out, name))
    sq.resize((48, 48), Image.LANCZOS).save(os.path.join(out, "favicon.ico"),
                                            sizes=[(16, 16), (32, 32), (48, 48)])


if __name__ == "__main__":
    os.makedirs("man/figures", exist_ok=True)
    os.makedirs("dev/logo", exist_ok=True)

    for v in "ABCD":
        open(f"dev/logo/hex_{v}.svg", "w").write(build_svg(v))
        rasterise(f"dev/logo/hex_{v}.svg", f"dev/logo/hex_{v}.png", 600, 692)

    engine = rasterise(f"dev/logo/hex_{VARIANT}.svg", "man/figures/logo.png", 600, 692)
    from PIL import Image
    Image.open("man/figures/logo.png").save("man/figures/logo.png", optimize=True)
    favicons("man/figures/logo.png")

    print(f"rasterised with {engine}; variant {VARIANT} mounted\n")
    print("containment test -- ink outside the hexagon:")
    fail = False
    for v in "ABCD":
        mx, n = escaped_ink(f"dev/logo/hex_{v}.png")
        ok = mx <= 12
        fail |= not ok
        print(f"  hex_{v}   furthest {mx:5.1f} px   stray {n:4d}   {'pass' if ok else 'FAIL'}")
    if fail:
        sys.exit("\nFAIL: ink is escaping the hexagon. Do not commit this.")
    print("\nAll clear. logo.png + favicons written.")
