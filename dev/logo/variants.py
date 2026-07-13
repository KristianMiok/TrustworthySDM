import hexgen as HX
import crayfish as CF

def make(seed, variant):
    segs, kept, dropped = HX.build(seed)
    outer  = HX.path_of(HX.hex_pts(0))
    inner  = HX.path_of(HX.hex_pts(11))
    clipp  = HX.path_of(HX.hex_pts(8))
    CX, W, H = HX.CX, HX.W, HX.H

    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">']
    o.append(f'''  <defs>
    <linearGradient id="bg" x1="0.15" y1="0" x2="0.75" y2="1">
      <stop offset="0%" stop-color="#14606F"/><stop offset="48%" stop-color="#0B3F4C"/>
      <stop offset="100%" stop-color="#05252E"/>
    </linearGradient>
    <linearGradient id="river" x1="0.5" y1="1" x2="0.5" y2="0.1">
      <stop offset="0%" stop-color="#3E9CB0"/><stop offset="50%" stop-color="#6FCEC9"/>
      <stop offset="100%" stop-color="#B4F0E2"/>
    </linearGradient>
    <linearGradient id="shell" x1="0.3" y1="0" x2="0.7" y2="1">
      <stop offset="0%" stop-color="#FFB07A"/><stop offset="55%" stop-color="#FF8C50"/>
      <stop offset="100%" stop-color="#E0653A"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0%" stop-color="#FF8C50" stop-opacity="0.6"/>
      <stop offset="60%" stop-color="#FF8C50" stop-opacity="0.18"/>
      <stop offset="100%" stop-color="#FF8C50" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="scrim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#04222A" stop-opacity="0"/>
      <stop offset="100%" stop-color="#04222A" stop-opacity="0.85"/>
    </linearGradient>
    <clipPath id="hc"><path d="{clipp}"/></clipPath>
  </defs>''')
    o.append(f'  <path d="{outer}" fill="url(#bg)"/>')
    o.append('  <g clip-path="url(#hc)">')

    for r, op in ((330,0.07),(262,0.06),(196,0.05),(132,0.045),(74,0.04)):
        o.append(f'    <ellipse cx="{CX}" cy="{HX.CY+62:.0f}" rx="{r}" ry="{r*0.80:.0f}" fill="none" stroke="#9EE4E8" stroke-opacity="{op}" stroke-width="2"/>')

    def network(shadow=True, op=1.0):
        out = []
        if shadow:
            out.append(f'    <g fill="none" stroke="#04222A" stroke-linecap="round" stroke-opacity="0.55">')
            for w, d in segs: out.append(f'      <path d="{d}" stroke-width="{w+5:.1f}"/>')
            out.append("    </g>")
        out.append(f'    <g fill="none" stroke="url(#river)" stroke-linecap="round" opacity="{op}">')
        for w, d in segs: out.append(f'      <path d="{d}" stroke-width="{w:.1f}"/>')
        out.append("    </g>")
        return out

    def points():
        out = ['    <g fill="#0A3A46" stroke="#63A3B0" stroke-width="3">']
        for x, y in dropped: out.append(f'      <circle cx="{x:.1f}" cy="{y:.1f}" r="8.5"/>')
        out.append("    </g>")
        for x, y in kept: out.append(f'    <circle cx="{x:.1f}" cy="{y:.1f}" r="30" fill="url(#glow)"/>')
        out.append('    <g fill="#FF8C50" stroke="#08303B" stroke-width="2.4">')
        for x, y in kept: out.append(f'      <circle cx="{x:.1f}" cy="{y:.1f}" r="11"/>')
        out.append("    </g>")
        return out

    if variant == "A":
        o += network(); o += points()
    elif variant == "B":
        # crayfish as a shadow under the surface; the network runs over it
        o.append(CF.render(scale=302, tx=CX, ty=178, fill="#031C24", opacity=0.72))
        o.append(CF.render(scale=294, tx=CX, ty=180, fill="#0B4655", opacity=0.85))
        o += network(); o += points()
    elif variant == "C":
        o += network(shadow=False, op=0.55)
        o.append(CF.render(scale=286, tx=CX, ty=182, fill="#052029", opacity=0.6))
        o.append(CF.render(scale=278, tx=CX, ty=180, fill="url(#shell)", opacity=1.0))
        o += points()
    elif variant == "D":
        # crayfish in light shell over a dark network: the dots stay the only warm thing
        o += network(shadow=True, op=0.85)
        o.append(CF.render(scale=290, tx=CX, ty=180, fill="#04222A", opacity=0.55))
        o.append(CF.render(scale=282, tx=CX, ty=178, fill="#CFF2EA", opacity=0.92))
        o += points()

    o.append(f'    <rect x="0" y="{H-150}" width="{W}" height="150" fill="url(#scrim)"/>')
    o.append("  </g>")
    o.append(f'  <path d="{outer}" fill="none" stroke="#062831" stroke-width="16"/>')
    o.append(f'  <path d="{inner}" fill="none" stroke="#8FE3D3" stroke-width="5" stroke-opacity="0.92"/>')
    o.append(f'  <text x="{CX}" y="{H-56}" text-anchor="middle" font-family="DejaVu Sans Condensed, DejaVu Sans" font-size="50">'
             '<tspan fill="#D8F5EE" font-weight="400">Trustworthy</tspan>'
             '<tspan fill="#FF8C50" font-weight="700">SDM</tspan></text>')
    o.append("</svg>")
    return "\n".join(o)

if __name__ == "__main__":
    import cairosvg
    for v in ("A","B","C","D"):
        open(f"hex_{v}.svg","w").write(make(8, v))
        cairosvg.svg2png(url=f"hex_{v}.svg", write_to=f"hex_{v}.png", output_width=520, output_height=600)
    print("ok")
