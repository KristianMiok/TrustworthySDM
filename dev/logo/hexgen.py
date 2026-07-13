"""Hex logo for TrustworthySDM.

The picture is the finding, not decoration. A dendritic river network; the
retained (high-quality) records sit upstream in the headwaters, the discarded
ones near the outlet. That is the crayfish diagnostic, drawn.

Constraint that drives every choice below: pkgdown shows this at ~139 px tall.
Fine detail turns to mush. Bold trunk, few levels, big dots.
"""
import math
import random

W, H = 520, 600
CX, CY = W / 2, H / 2
A, B = W / 2, H / 2


def hex_pts(inset=0.0):
    a, b = A - inset, B - inset
    return [
        (CX, CY - b),
        (CX + a, CY - b / 2),
        (CX + a, CY + b / 2),
        (CX, CY + b),
        (CX - a, CY + b / 2),
        (CX - a, CY - b / 2),
    ]


def path_of(pts):
    return "M " + " L ".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"


def inside(x, y, margin=34):
    """Pointy-top hexagon: |u| <= a AND |v|/b + |u|/(2a) <= 1."""
    a, b = A - margin, B - margin
    u, v = abs(x - CX), abs(y - CY)
    return u <= a and (v / b + u / (2 * a)) <= 1.0


class Node:
    __slots__ = ("x", "y", "parent", "children", "depth", "dist", "leaves")

    def __init__(self, x, y, parent=None, depth=0, dist=0.0):
        self.x, self.y = x, y
        self.parent = parent
        self.children = []
        self.depth = depth
        self.dist = dist
        self.leaves = 0


def grow(seed, max_depth=5):
    rng = random.Random(seed)
    root = Node(CX, CY + B - 40)
    queue = [(root, -math.pi / 2, 118.0)]
    nodes = [root]

    while queue:
        node, ang, ln = queue.pop(0)
        if node.depth >= max_depth:
            continue
        n_child = 2 if rng.random() < 0.78 else 3
        spread = math.radians(rng.uniform(46, 68))
        for i in range(n_child):
            t = (i / (n_child - 1)) - 0.5
            base = ang + t * spread + rng.uniform(-0.10, 0.10)
            l = ln * rng.uniform(0.70, 0.84)
            for attempt in range(7):  # nudge the branch rather than drop it
                a = base + attempt * (0.17 if t >= 0 else -0.17)
                a = max(-math.pi * 0.97, min(-math.pi * 0.03, a))
                nx = node.x + l * math.cos(a)
                ny = node.y + l * math.sin(a)
                if inside(nx, ny):
                    child = Node(nx, ny, node, node.depth + 1, node.dist + l)
                    node.children.append(child)
                    nodes.append(child)
                    queue.append((child, a, l))
                    break
                l *= 0.87
    return root, nodes


def count_leaves(n):
    n.leaves = 1 if not n.children else sum(count_leaves(c) for c in n.children)
    return n.leaves


def curved(p, c, bow):
    mx, my = (p.x + c.x) / 2, (p.y + c.y) / 2
    dx, dy = c.x - p.x, c.y - p.y
    L = math.hypot(dx, dy) or 1.0
    px, py = -dy / L, dx / L
    return f"M {p.x:.1f},{p.y:.1f} Q {mx+px*bow:.1f},{my+py*bow:.1f} {c.x:.1f},{c.y:.1f}"


def build(seed):
    rng = random.Random(seed + 900)
    root, nodes = grow(seed)
    count_leaves(root)
    maxd = max(n.dist for n in nodes)

    segs = []
    for n in nodes:
        if n.parent is None:
            continue
        w = 3.6 + 13.5 * (n.leaves / root.leaves) ** 0.55
        L = math.hypot(n.x - n.parent.x, n.y - n.parent.y)
        segs.append((w, curved(n.parent, n, rng.uniform(-0.15, 0.15) * L)))
    segs.sort(key=lambda s: s[0])

    kept, dropped = [], []
    for n in nodes:
        if n.parent is None:
            continue
        u = n.dist / maxd
        if not n.children and u > 0.45:
            kept.append((n.x, n.y))
        elif rng.random() < 0.30 * (u**2):
            kept.append((n.x, n.y))
        elif u < 0.45 and rng.random() < 0.60:
            dropped.append((n.x, n.y))
    return segs, kept, dropped


def svg(seed):
    segs, kept, dropped = build(seed)
    outer, inner, clipp = path_of(hex_pts(0)), path_of(hex_pts(11)), path_of(hex_pts(8))

    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">']
    o.append(f'''  <defs>
    <linearGradient id="bg" x1="0.15" y1="0" x2="0.75" y2="1">
      <stop offset="0%"   stop-color="#14606F"/>
      <stop offset="48%"  stop-color="#0B3F4C"/>
      <stop offset="100%" stop-color="#05252E"/>
    </linearGradient>
    <linearGradient id="river" x1="0.5" y1="1" x2="0.5" y2="0.1">
      <stop offset="0%"   stop-color="#3E9CB0"/>
      <stop offset="50%"  stop-color="#6FCEC9"/>
      <stop offset="100%" stop-color="#B4F0E2"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0%"   stop-color="#FF8C50" stop-opacity="0.60"/>
      <stop offset="60%"  stop-color="#FF8C50" stop-opacity="0.18"/>
      <stop offset="100%" stop-color="#FF8C50" stop-opacity="0"/>
    </radialGradient>
    <clipPath id="hc"><path d="{clipp}"/></clipPath>
  </defs>''')

    o.append(f'  <path d="{outer}" fill="url(#bg)"/>')
    o.append('  <g clip-path="url(#hc)">')

    for r, op in ((330, 0.07), (262, 0.06), (196, 0.05), (132, 0.045), (74, 0.04)):
        o.append(
            f'    <ellipse cx="{CX}" cy="{CY+62:.0f}" rx="{r}" ry="{r*0.80:.0f}" fill="none" '
            f'stroke="#9EE4E8" stroke-opacity="{op}" stroke-width="2"/>'
        )

    o.append('    <g fill="none" stroke="#04222A" stroke-linecap="round" stroke-opacity="0.55">')
    for w, d in segs:
        o.append(f'      <path d="{d}" stroke-width="{w+5:.1f}"/>')
    o.append("    </g>")
    o.append('    <g fill="none" stroke="url(#river)" stroke-linecap="round">')
    for w, d in segs:
        o.append(f'      <path d="{d}" stroke-width="{w:.1f}"/>')
    o.append("    </g>")

    o.append('    <g fill="#0A3A46" stroke="#63A3B0" stroke-width="3">')
    for x, y in dropped:
        o.append(f'      <circle cx="{x:.1f}" cy="{y:.1f}" r="8.5"/>')
    o.append("    </g>")

    for x, y in kept:
        o.append(f'    <circle cx="{x:.1f}" cy="{y:.1f}" r="30" fill="url(#glow)"/>')
    o.append('    <g fill="#FF8C50" stroke="#08303B" stroke-width="2.4">')
    for x, y in kept:
        o.append(f'      <circle cx="{x:.1f}" cy="{y:.1f}" r="11"/>')
    o.append("    </g>")
    o.append("  </g>")

    o.append(f'  <path d="{outer}" fill="none" stroke="#062831" stroke-width="16"/>')
    o.append(f'  <path d="{inner}" fill="none" stroke="#8FE3D3" stroke-width="5" stroke-opacity="0.92"/>')
    o.append(
        f'  <text x="{CX}" y="{H-58}" text-anchor="middle" '
        'font-family="DejaVu Sans Condensed, DejaVu Sans" font-size="50">'
        '<tspan fill="#D8F5EE" font-weight="400">Trustworthy</tspan>'
        '<tspan fill="#FF8C50" font-weight="700">SDM</tspan>'
        "</text>"
    )
    o.append("</svg>")
    return "\n".join(o)


if __name__ == "__main__":
    import sys

    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 11
    out = sys.argv[2] if len(sys.argv) > 2 else "logo.svg"
    open(out, "w").write(svg(seed))
    print("wrote", out)
