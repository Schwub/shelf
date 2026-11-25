"""ShelfColors constants (app/lib/theme/shelf_colors.dart) for themes in the
mockup JSON, with pressed tints, side shades and meter steps derived.
Usage: python3 dart.py <themes.json> > out.dart.txt"""
import json, re, sys

def rgb(h):
    h = h.lstrip('#')
    return [int(h[i:i+2], 16) for i in (0, 2, 4)], (int(h[6:8], 16) if len(h) == 8 else 255)

def mix(a, b, t):  # t of b into a
    (ca, _), (cb, _) = rgb(a), rgb(b)
    return '#' + ''.join(f'{round(x*(1-t)+y*t):02X}' for x, y in zip(ca, cb))

def dart(h):
    c, alpha = rgb(h)
    return 'Color(0x%02X%02X%02X%02X)' % (alpha, *c)

def stops(v):
    m = re.findall(r'#[0-9A-Fa-f]{6}', v)
    return (m[0], m[-1]) if m else (v, v)

def emit(name, t, doc):
    light = t.get('light', False)
    start, end = stops(t['primary'])
    m0, m1 = stops(t['meter'])
    meter = [mix(m0, m1, i / 4) for i in range(5)]
    tint = 0.10 if light else 0.14
    accent = t['accent']
    f = {
        'brightness': 'Brightness.light' if light else 'Brightness.dark',
        'lights': 'false',
        'teak': dart(t['teak']),
        'primaryStart': dart(start), 'primaryEnd': dart(end),
        'primarySide': dart(t['primarySide']),
        'primarySideRight': dart(mix(t['primarySide'], '#000000', 0.15)),
        'primaryContact': dart(mix(t['primarySide'], '#000000', 0.5)),
        'primaryHighlight': dart(mix(start, '#FFFFFF', 0.35)),
        'bg': dart(t['bg']), 'surface': dart(t['surface']), 'text': dart(t['text']),
        'muted': dart(t['muted']), 'signal': dart(accent), 'line': dart(t['line']),
        'off': dart(t['off']), 'onAmber': dart(t['onPrimary']),
        'shadow': 'Color(0x265A3A1F)' if light else 'Color(0x59000000)',
        'faceTop': dart(t['faceA']), 'faceBottom': dart(t['faceB']),
        'pressedTop': dart(mix(t['pressedA'], accent, tint)),
        'pressedBottom': dart(mix(t['pressedB'], accent, tint)),
        'side': dart(t['side']), 'sideRight': dart(t['sideR']), 'contact': dart(t['contact']),
        'highlight': 'Color(0xFFFFFFFF)' if light else 'Color(0x1CFFFFFF)',
        'edge': 'Color(0x265A3A1F)' if light else 'Color(0x66000000)',
        'engrave': 'Color(0xCCFFFFFF)' if light else 'Color(0x99000000)',
        'engraveLight': 'Color(0x10000000)' if light else 'Color(0x14FFFFFF)',
        'window': 'Color(0x00000000)', 'windowGlow': 'Color(0x00000000)',
        'press': 'Color(0x445A3A1F)' if light else 'Color(0x88000000)',
    }
    body = ''.join(f'    {k}: {v},\n' for k, v in f.items())
    body += '    meter: [\n' + ''.join(f'      {dart(c)},\n' for c in meter) + '    ],\n'
    return f'  /// {doc}\n  static const {name} = ShelfColors(\n{body}  );\n'

for t in json.load(open(sys.argv[1]))["themes"]:
    name = re.sub(r"[^A-Za-z0-9]+(.)", lambda m: m.group(1).upper(), t["key"])
    print(emit(name, t, re.sub(r"^\d+ · ", "", t["name"])))
