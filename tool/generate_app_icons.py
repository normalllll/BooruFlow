"""Export the checked-in logo to the platform resources. Requires Pillow.

Run from any directory: python tool/generate_app_icons.py
The source artwork is preserved; only sizing, padding and platform backgrounds
are applied. Windows intentionally contains only the requested 256px image.
"""

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/app_icon_source.png"
BACKGROUND = (250, 248, 252, 255)
RESAMPLE = Image.Resampling.LANCZOS
DESKTOP_FRACTION = 0.96
IOS_FRACTION = 0.90
MAC_FRACTION = 0.82


def subject_bounds(image):
    # Ignore faint edge pixels and isolated specks when measuring the subject.
    # Filtering is for measurement only; the exported artwork is not filtered.
    mask = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    bounds = mask.filter(ImageFilter.MedianFilter(9)).getbbox()
    if bounds is None:
        raise ValueError("The source image has no visible subject")
    left, top, right, bottom = bounds
    return (max(0, left - 5), max(0, top - 5),
            min(image.width, right + 5), min(image.height, bottom + 5))


def adaptive_fraction(image):
    # Keep the artwork within the central 72dp circular launcher viewport,
    # with a 1dp inset. Manufacturer-specific masks still need visual review.
    mask = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    mask = mask.filter(ImageFilter.MedianFilter(9))
    cx, cy = (image.width - 1) / 2, (image.height - 1) / 2
    radius = max(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                 for y in range(image.height) for x in range(image.width)
                 if mask.getpixel((x, y)))
    return min(0.56, (35 / 108) * max(image.size) / radius)


def save(image, path):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def fit(image, size, fraction=1.0):
    result = Image.new("RGBA", (size, size))
    scale = size * fraction / max(image.size)
    artwork = image.resize((max(1, round(image.width * scale)),
                            max(1, round(image.height * scale))), RESAMPLE)
    result.alpha_composite(artwork, ((size - artwork.width) // 2,
                                     (size - artwork.height) // 2))
    return result


def apple_catalog(image, directory):
    catalog = ROOT / directory
    entries = json.loads((catalog / "Contents.json").read_text())["images"]
    for entry in entries:
        size = round(float(entry["size"].split("x")[0]) *
                     float(entry["scale"].removesuffix("x")))
        save(image.resize((size, size), RESAMPLE), catalog / entry["filename"])


def main():
    source = Image.open(SOURCE).convert("RGBA")
    source = source.crop(subject_bounds(source))
    desktop = fit(source, 1024, DESKTOP_FRACTION)
    save(desktop.resize((512, 512), RESAMPLE), "icon-512.png")
    ico = ROOT / "windows/runner/resources/app_icon.ico"
    desktop.save(ico, format="ICO", sizes=[(256, 256)])

    ios = Image.new("RGBA", (1024, 1024), BACKGROUND)
    ios.alpha_composite(fit(source, 1024, IOS_FRACTION))
    apple_catalog(ios.convert("RGB"), "ios/Runner/Assets.xcassets/AppIcon.appiconset")

    # The existing macOS asset catalog expects a rendered icon, including its
    # rounded background and transparent outer margin.
    mac = Image.new("RGBA", (1024, 1024))
    ImageDraw.Draw(mac).rounded_rectangle((50, 50, 974, 974), radius=205,
                                          fill=BACKGROUND)
    mac.alpha_composite(fit(source, 1024, MAC_FRACTION))
    apple_catalog(mac, "macos/Runner/Assets.xcassets/AppIcon.appiconset")

    # Use the colored shapes as a theme mask, retaining the picture window and
    # ear openings as negative space instead of producing a solid silhouette.
    red, green, blue, alpha = source.split()
    maximum = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    minimum = ImageChops.darker(ImageChops.darker(red, green), blue)
    color_mask = ImageChops.subtract(maximum, minimum).point(
        lambda value: min(255, max(0, (value - 12) * 6)))
    mono = Image.new("RGBA", source.size, (255, 255, 255, 0))
    mono.putalpha(ImageChops.multiply(alpha, color_mask))

    res = Path("android/app/src/main/res")
    foreground_fraction = adaptive_fraction(source)
    for density, scale in [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2),
                           ("xxhdpi", 3), ("xxxhdpi", 4)]:
        folder = res / f"mipmap-{density}"
        size = round(108 * scale)
        save(fit(source, size, foreground_fraction), folder / "ic_launcher_foreground.png")
        save(fit(mono, size, foreground_fraction), folder / "ic_launcher_monochrome.png")
        save(Image.new("RGB", (size, size), BACKGROUND[:3]),
             folder / "ic_launcher_background.png")
        save(ios.convert("RGB").resize((round(48 * scale),) * 2, RESAMPLE),
             folder / "ic_launcher.png")

    for size in [16, 24, 32, 48, 64, 128, 256, 512]:
        save(desktop.resize((size, size), RESAMPLE),
             f"linux/icons/hicolor/{size}x{size}/apps/booruflow.png")
    print("Exported Windows (256px only), Android, iOS, macOS and Linux icons.")


if __name__ == "__main__":
    main()
