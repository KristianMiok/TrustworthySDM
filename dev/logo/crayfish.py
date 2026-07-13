"""Crayfish silhouette, built from primitives (ellipses + strokes) rather than
freehand beziers, because freehand beziers do not converge.

Head up. Unit box: x in [-0.5, 0.5], y = 0 at the rostrum tip, y = 1 at the
tail. Caller scales and places it.
"""


def _ell(cx, cy, rx, ry, rot=0):
    return f'<ellipse cx="{cx:.4f}" cy="{cy:.4f}" rx="{rx:.4f}" ry="{ry:.4f}" transform="rotate({rot} {cx:.4f} {cy:.4f})"/>'


def _tri(p1, p2, p3):
    return f'<path d="M {p1[0]:.4f},{p1[1]:.4f} L {p2[0]:.4f},{p2[1]:.4f} L {p3[0]:.4f},{p3[1]:.4f} Z"/>'


def parts():
    """Return (filled_shapes, stroke_paths_with_width)."""
    F, S = [], []

    # ---- carapace: broad shield, widest a third of the way down -------------
    F.append(_ell(0, 0.245, 0.125, 0.175))
    F.append(_ell(0, 0.135, 0.082, 0.090))          # head, narrower
    F.append(_tri((-0.026, 0.085), (0.026, 0.085), (0, -0.035)))  # rostrum

    # ---- abdomen: six segments, tapering ------------------------------------
    seg = [
        (0.420, 0.118, 0.048),
        (0.505, 0.110, 0.048),
        (0.588, 0.100, 0.046),
        (0.668, 0.089, 0.044),
        (0.744, 0.077, 0.042),
        (0.812, 0.064, 0.038),
    ]
    for cy, rx, ry in seg:
        F.append(_ell(0, cy, rx, ry))

    # ---- tail fan: telson + two pairs of uropods ----------------------------
    F.append(_ell(0, 0.918, 0.058, 0.092))                       # telson
    for s in (1, -1):
        F.append(_ell(0.078 * s, 0.905, 0.052, 0.096, rot=18 * s))   # inner uropod
        F.append(_ell(0.150 * s, 0.872, 0.048, 0.090, rot=44 * s))   # outer uropod

    # ---- chelae: the claws. A crayfish is mostly claws ----------------------
    for s in (1, -1):
        shoulder = (0.100 * s, 0.215)
        elbow = (0.235 * s, 0.115)
        wrist = (0.268 * s, 0.020)
        # arm, as a thick round-capped stroke
        S.append((f"M {shoulder[0]:.4f},{shoulder[1]:.4f} Q {0.195*s:.4f},0.195 "
                  f"{elbow[0]:.4f},{elbow[1]:.4f} Q {0.268*s:.4f},0.075 "
                  f"{wrist[0]:.4f},{wrist[1]:.4f}", 0.052))
        # palm (propodus): a fat ellipse angled outward and forward
        F.append(_ell(0.310 * s, -0.055, 0.070, 0.098, rot=-22 * s))
        # fixed finger: outer, long, curving inward at the tip
        F.append(_ell(0.378 * s, -0.215, 0.021, 0.115, rot=-9 * s))
        F.append(_tri((0.345 * s, -0.105), (0.392 * s, -0.125), (0.372 * s, -0.300)))
        # movable finger (dactyl): inner. The V between them is the pincer.
        F.append(_ell(0.258 * s, -0.200, 0.020, 0.108, rot=11 * s))
        F.append(_tri((0.240 * s, -0.100), (0.288 * s, -0.112), (0.268 * s, -0.290)))

    # ---- walking legs -------------------------------------------------------
    for (ax, ay), (bx, by), (cx_, cy_) in [
        ((0.105, 0.245), (0.200, 0.290), (0.255, 0.375)),
        ((0.110, 0.300), (0.215, 0.365), (0.258, 0.462)),
        ((0.105, 0.352), (0.198, 0.435), (0.226, 0.528)),
        ((0.092, 0.398), (0.172, 0.488), (0.186, 0.580)),
    ]:
        for s in (1, -1):
            S.append((f"M {ax*s:.4f},{ay:.4f} Q {bx*s:.4f},{by:.4f} {cx_*s:.4f},{cy_:.4f}", 0.020))

    # ---- antennae -----------------------------------------------------------
    for s in (1, -1):
        S.append((f"M {0.045*s:.4f},0.115 C {0.150*s:.4f},0.010 {0.235*s:.4f},-0.130 "
                  f"{0.255*s:.4f},-0.320", 0.014))
        S.append((f"M {0.028*s:.4f},0.095 C {0.075*s:.4f},0.010 {0.098*s:.4f},-0.070 "
                  f"{0.096*s:.4f},-0.160", 0.011))
    return F, S


def render(scale=1.0, tx=0.0, ty=0.0, fill="#0A3540", opacity=1.0):
    F, S = parts()
    g = [f'<g transform="translate({tx},{ty}) scale({scale})" opacity="{opacity}">']
    g.append(f'  <g fill="none" stroke="{fill}" stroke-linecap="round" stroke-linejoin="round">')
    for d, w in S:
        g.append(f'    <path d="{d}" stroke-width="{w:.4f}"/>')
    g.append("  </g>")
    g.append(f'  <g fill="{fill}" stroke="{fill}" stroke-width="0.006" stroke-linejoin="round">')
    for d in F:
        g.append("    " + d)
    g.append("  </g>")
    g.append("</g>")
    return "\n".join(g)


if __name__ == "__main__":
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="620" height="760" viewBox="0 0 620 760">'
           '<rect width="620" height="760" fill="#F2F7F6"/>'
           + render(scale=560, tx=310, ty=210, fill="#0E4A57") + "</svg>")
    open("crayfish_test.svg", "w").write(svg)
    print("wrote")
