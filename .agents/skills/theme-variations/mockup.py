"""Mockup page for theme candidates: My shelf and an album entry per theme,
with bright test covers. Usage: python3 mockup.py <themes.json> <out.html>
The JSON: {"title", "intro", "themes": [...]}; see example.json for the keys."""
import json, sys

COVERS = [  # (title, artist, art css, rating in half stars)
  ("Kid A", "Radiohead", "linear-gradient(160deg,#e9e4dc 0 40%,#d23a2c 40% 46%,#2b3a55 46%)", 9),
  ("Discovery", "Daft Punk", "radial-gradient(circle at 30% 30%,#ffd84a,#f2732c 45%,#3a1660 80%)", 8),
  ("Blue", "Joni Mitchell", "linear-gradient(180deg,#1d4f8a,#0e2a4d)", 10),
  ("Promises", "Floating Points", "linear-gradient(135deg,#f4f1e8 0 60%,#1aa38c 60%)", 7),
  ("Lemonade", "Beyoncé", "linear-gradient(200deg,#f5d23a,#e0a11b 60%,#7a3e12)", 0),
  ("Currents", "Tame Impala", "conic-gradient(from 200deg at 40% 60%,#5b2a86,#e0457b,#f39b3a,#5b2a86)", 6),
  ("Titanic Rising", "Weyes Blood", "linear-gradient(180deg,#1b6f8f,#7fc3c9 55%,#e8d7b8)", 8),
  ("Vespertine", "Björk", "linear-gradient(160deg,#fafafa,#cfd6dd 50%,#9aa6b2)", 0),
  ("Ys", "Joanna Newsom", "linear-gradient(140deg,#c78a3b,#6b3d1e 55%,#2d4a2e)", 9),
]

def css(t):
    v = ";".join(f"--{k}:{t[k]}" for k in ["bg","surface","faceA","faceB","side","sideR","contact","text","muted","line","off","teak","accent","primarySide","onPrimary","pressedA","pressedB"])
    engrave = "#ffffffb0" if t.get("light") else "#0006"
    tint = "0%" if t["leds"] else ("10%" if t.get("light") else "14%")
    return v + f";--primary:{t['primary']};--meter:{t['meter']};--glow:{t.get('glow','transparent')};--engrave:{engrave};--tint:{tint}"

def key(label, on=False, primary=False, led=False, extra="", cls=""):
    led_html = f'<i class="led{" lit" if on else ""}"></i>' if led else ""
    return (f'<div class="k{" on" if on else ""}{" pri" if primary else ""} {cls}"><div class="f">'
            f'{led_html}<span>{label}</span>{extra}</div></div>')

def meter(n):
    out = []
    for i in range(5):
        full = n >= (i + 1) * 2; half = n == i * 2 + 1
        out.append(f'<i class="{"on" if full else "half" if half else ""}"></i>')
    return '<div class="meter">' + "".join(out) + "</div>"

def shelf(t):
    leds = t["leds"]
    tabs = [("All", 9, True), ("Own", 6, False), ("Want", 3, False), ("To listen", 4, False), ("Listened", 5, False)]
    labels = "".join(f"<span>{n}</span>" for n, _, _ in tabs)
    keys = "".join(key(f"{c}", on=o, led=leds, cls="tab") for n, c, o in tabs)
    rows = []
    for r in range(3):
        cells = COVERS[r*3:(r+1)*3]
        covers = "".join(f'<div class="cv" style="background:{a}"></div>' for _, _, a, _ in cells)
        labs = "".join(f'<div><div class="tt">{ti}</div><div class="ar">{ar}</div>{meter(n) if n else ""}</div>' for ti, ar, _, n in cells)
        rows.append(f'<div class="covers">{covers}</div><div class="board"></div><div class="labels">{labs}</div>')
    return f'''<div class="phone" style="{css(t)}"><div class="sb">9:41</div>
<div class="head"><h2 class="x">My shelf</h2><span class="count">9 albums</span></div>
<div class="filter"><div class="flabels">{labels}</div><div class="fkeys">{keys}</div><div class="fboard"></div></div>
<div class="shelf">{"".join(rows)}</div>
<div class="bar">{key('<svg viewBox="0 0 20 20"><path d="M3 3h6v6H3zM11 3h6v6h-6zM3 11h6v6H3zM11 11h6v6h-6z"/></svg>', on=True, cls="ic")}{key('<svg viewBox="0 0 20 20"><path d="M3 5h14M3 10h14M3 15h14"/></svg>', cls="ic")}{key("+ Add album", primary=True, cls="grow")}</div></div>'''

def entry(t):
    leds = t["leds"]
    art = COVERS[0][2]
    x = '<svg class="xs" viewBox="0 0 20 20"><path d="M6 6l8 8M14 6l-8 8"/></svg>'
    star_on = '<svg viewBox="0 0 20 20" class="st on"><path d="M10 2.5l2.3 4.9 5.2.6-3.9 3.6 1.1 5.2L10 14.2 5.3 16.8l1.1-5.2L2.5 8l5.2-.6z"/></svg>'
    star_off = star_on.replace('st on', 'st')
    tracks = [("1", "Everything in Its Right Place", "4:11", True), ("2", "Kid A", "4:44", False), ("3", "The National Anthem", "5:50", False), ("4", "How to Disappear Completely", "5:56", True)]
    trows = "".join(f'<div class="tr"><span class="n">{n}</span><span class="tn">{ti}</span><span class="ln">{l}</span>{star_on if fav else star_off}</div>' for n, ti, l, fav in tracks)
    rate = "".join(f'<div class="k rk{" on" if i < 4 else ""}"><div class="f"><i class="rbar{" on" if i < 4 else ""}"></i></div></div>' for i in range(5))
    return f'''<div class="phone" style="{css(t)}"><div class="sb">9:41</div>
<div class="stage" style="--wall:#2b3a5544"><div class="big" style="background:{art}"></div><div class="board sb2"></div>
<div class="close">{key('<svg viewBox="0 0 20 20"><path d="M5 5l10 10M15 5L5 15"/></svg>', cls="ic")}</div></div>
<div class="panel"><h3 class="x">Kid A</h3><div class="by">Radiohead, 2000</div>
<div class="lbl"><span>Collection</span></div><div class="keys">{key("Want", led=leds)}{key("Own", on=True, led=leds)}</div>
<div class="sub"><div class="lbl"><span>Format</span></div><div class="wrap">{key("Vinyl", on=True, led=leds)}{key("CD", led=leds)}{key("File", led=leds)}</div></div>
<div class="lbl"><span>Genre</span><a>+ Add</a></div><div class="wrap">{key("Electronic", extra=x)}{key("Art rock", extra=x)}</div>
<div class="lbl"><span>Rating</span><span>4 of 5 stars</span></div><div class="rate">{rate}</div>
<div class="lbl"><span>Tracks</span><a>Edit tracks</a></div>{trows}
</div><div class="bar">{key("Cancel", cls="grow")}{key("Save", primary=True, cls="grow")}</div></div>'''

STYLE = r'''
*{box-sizing:border-box}body{margin:0;padding:28px;background:#cbc3b8;font-family:system-ui;color:#222}
h1{font:600 22px system-ui;margin:0 0 6px}p.intro{max-width:980px;font:14px/1.5 system-ui;margin:0 0 24px}
section{margin:0 0 40px}section h2{font:600 17px system-ui;margin:0 0 4px}section p{max-width:820px;font:13.5px/1.45 system-ui;margin:0 0 12px;color:#333}
.swatches{display:flex;gap:6px;margin:0 0 14px}.swatches i{width:28px;height:28px;border-radius:4px;box-shadow:0 0 0 1px #0002}
.row{display:flex;gap:28px;flex-wrap:wrap;align-items:flex-start}
.phone{width:390px;height:844px;border-radius:30px;overflow:hidden;position:relative;display:flex;flex-direction:column;box-shadow:0 0 0 2px #333;
 font-family:'IBM Plex Sans',sans-serif;color:var(--text);background:var(--bg)}
.sb{height:28px;font:12px system-ui;padding:8px 24px;opacity:.7;position:relative;z-index:2;flex:none}
.x{font-family:Archivo,sans-serif;font-stretch:125%}
.head{padding:12px 20px 0;display:flex;justify-content:space-between;align-items:baseline}
.head h2{font-size:24px;font-weight:700;margin:0}.head .count{font-size:13px;color:var(--muted)}
/* key: edge layer + face, light from the top left (C4) */
.k{height:44px;border-radius:4px;background:var(--side);padding:0 5px 6px 0;position:relative;
 box-shadow:inset 0 -1px 0 var(--contact),3px 4px 5px #0000004d,inset 0 0 0 1px var(--line);flex:none;cursor:default}
.k .f{height:100%;border-radius:4px;background:linear-gradient(160deg,var(--faceA),var(--faceB) 70%);display:flex;align-items:center;justify-content:center;gap:8px;
 padding:0 14px;font:600 13px Archivo,sans-serif;font-stretch:112%;white-space:nowrap;color:var(--text);
 box-shadow:inset 1px 1px 0 #ffffff14;text-shadow:0 1px 0 var(--engrave)}
.k.on{padding:0 2px 2.4px 0;margin-top:3.6px;margin-left:3px;height:40.4px;box-shadow:inset 0 -1px 0 var(--contact),1.2px 1.6px 2px #0000004d,inset 0 0 0 1px var(--line)}
.k.on .f{background:linear-gradient(160deg,color-mix(in srgb,var(--accent) var(--tint),var(--pressedA)),color-mix(in srgb,var(--accent) var(--tint),var(--pressedB)) 70%);color:var(--accent);box-shadow:inset 1px 1px 0 color-mix(in srgb,var(--accent) 45%,transparent)}
.k.pri{background:var(--primarySide)}.k.pri .f{background:var(--primary);color:var(--onPrimary);text-shadow:none;box-shadow:inset 1px 1px 0 #ffffff30}
.k.ic .f{width:39px;padding:0}.k svg{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.5}
.k.grow{flex:1}.k .xs{width:14px;height:14px;opacity:.7;margin-right:-4px}
.led{width:10px;height:6px;border-radius:2px;background:#0E0907;box-shadow:inset 0 1px 1px #000a;flex:none;margin-left:-4px}
.led.lit{background:linear-gradient(135deg,#F2B13A,#E8743A);box-shadow:0 0 6px 1px var(--glow)}
.k.on .f span{}
/* filter bar */
.filter{padding:16px 20px 0;position:relative}
.flabels,.fkeys{display:grid;grid-template-columns:repeat(5,1fr);gap:6px}
.flabels span{text-align:center;font:600 12px Archivo,sans-serif;font-stretch:112%;color:var(--muted);margin-bottom:6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.fkeys .k{min-width:0}.fkeys .f{padding:0 6px}
.fboard{height:4px;background:var(--teak);margin:8px -20px 0;box-shadow:inset 0 1px 0 #ffffff33,0 6px 10px -2px #0006}
/* shelf */
.shelf{flex:1;overflow:hidden;padding:0 20px}
.covers{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;padding-top:20px}
.cv{aspect-ratio:1;border-radius:2px;box-shadow:0 2px 2px -1px #0008}
.board{height:4px;background:var(--teak);margin:0 -20px;position:relative;box-shadow:inset 0 1px 0 #ffffff33}
.board:after{content:"";position:absolute;left:0;right:0;top:3px;height:10px;background:linear-gradient(#0005,#0000)}
.labels{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;padding-top:10px}
.tt{font:600 13px/1.2 'IBM Plex Sans';white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.ar{font-size:12px;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.meter{display:flex;gap:4px;margin-top:6px;height:6px;width:76px}.meter i{flex:1;background:var(--off);border-radius:1px;opacity:.6}
.meter i.on{background:var(--meter);opacity:1}.meter i.half{background:linear-gradient(90deg,var(--accent) 50%,var(--off) 50%);opacity:1}
.bar{margin-top:auto;padding:12px 20px 26px;background:var(--bg);box-shadow:0 -1px 0 var(--line);display:flex;gap:8px;flex:none}
/* entry */
.stage{position:relative;height:250px;flex:none;margin-top:-28px;background:radial-gradient(60% 60% at 50% 55%,var(--wall),#0000 75%)}
.stage .big{position:absolute;left:50%;top:52px;width:180px;height:180px;transform:translateX(-50%);border-radius:2px;box-shadow:0 20px 34px -16px #000b}
.stage .board{position:absolute;left:0;right:0;top:232px;margin:0}
.close{position:absolute;top:36px;right:20px}
.panel{flex:1;padding:14px 20px 0;overflow:hidden}
.panel h3{font-size:22px;font-weight:700;margin:0}.panel .by{font-size:13px;color:var(--muted);margin-top:2px}
.lbl{display:flex;justify-content:space-between;align-items:baseline;font:600 12px 'IBM Plex Sans';color:var(--muted);margin:12px 0 6px}
.lbl a{font:600 13px 'IBM Plex Sans';text-decoration:underline;text-underline-offset:3px}
.keys{display:flex;gap:8px}.keys .k{flex:1}.wrap{display:flex;gap:8px;flex-wrap:wrap}
.sub{margin-top:8px;padding-left:12px;box-shadow:inset 2px 0 0 var(--line)}.sub .lbl{margin-top:4px}
.rate{display:flex;gap:8px}.rate .k{flex:1}.rate .f{padding:0 10px}
.rbar{display:block;width:100%;height:6px;border-radius:1px;background:var(--off);opacity:.6}.rbar.on{background:var(--meter);opacity:1}
.tr{display:flex;align-items:center;gap:8px;height:40px;box-shadow:inset 0 -1px 0 var(--line);font-size:14px}
.tr .n{width:20px;font-size:12px;color:var(--muted)}.tr .tn{flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.tr .ln{font-size:12px;color:var(--muted)}
.st{width:18px;height:18px;fill:none;stroke:var(--muted);stroke-width:1.4;margin:0 4px}.st.on{fill:var(--accent);stroke:var(--accent)}
'''

def page():
    secs = []
    for t in THEMES:
        sw = "".join(f'<i style="background:{t[k]}" title="{k}"></i>' for k in ["bg", "surface", "teak", "accent", "muted", "text"])
        secs.append(f'<section><h2>{t["name"]}</h2><p>{t["note"]}</p><div class="swatches">{sw}</div><div class="row">{shelf(t)}{entry(t)}</div></section>')
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><title>{{TITLE}}</title>
<link href="https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,400..800&family=IBM+Plex+Sans:wght@400;600&display=block" rel="stylesheet">
<style>{STYLE}</style></head><body>
<h1>{{TITLE}}</h1>
<p class="intro">{{INTRO}}</p>
{"".join(secs)}</body></html>'''

spec = json.load(open(sys.argv[1]))
THEMES = spec["themes"]
open(sys.argv[2], "w").write(
    page().replace("{TITLE}", spec["title"]).replace("{INTRO}", spec["intro"])
)
