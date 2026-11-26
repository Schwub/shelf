"""Scales tool/icon/icon.png and foreground.png (from render.js) into the
app's launcher icons for Android, iOS and the web. Run from app/."""
import json
import re
from pathlib import Path

from PIL import Image

here = Path(__file__).parent
icon = Image.open(here / 'icon.png').convert('RGB')  # iOS refuses transparency
foreground = Image.open(here / 'foreground.png').convert('RGBA')


def save(image, size, path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.LANCZOS).save(path, optimize=True)


# Android: the classic icon, and the adaptive one's foreground (108 dp).
res = Path('android/app/src/main/res')
for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    save(icon, round(48 * scale), res / f'mipmap-{density}/ic_launcher.png')
    save(foreground, round(108 * scale), res / f'mipmap-{density}/ic_launcher_foreground.png')

# iOS: every size the asset catalogue lists.
ios = Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
for image in json.loads((ios / 'Contents.json').read_text())['images']:
    size = float(image['size'].split('x')[0])
    scale = int(re.match(r'\d+', image['scale']).group())
    save(icon, round(size * scale), ios / image['filename'])

# Web.
save(icon, 32, 'web/favicon.png')
for size in (192, 512):
    save(icon, size, f'web/icons/Icon-{size}.png')
    save(icon, size, f'web/icons/Icon-maskable-{size}.png')
