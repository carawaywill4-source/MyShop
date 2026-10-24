"""Edge-pads (dilates) Tripo part textures so mipmaps don't bleed black UV gutters into paint.

Usage: python3 scripts/dev/pad_textures.py assets/models/tripo/<vehicle_id>_
Every *_basecolor.jpg, *_normal.jpg and *_rm.png starting with that prefix is padded in place.
Gutter texels are near-black (all channels < 6) in the basecolor; the same mask is applied to
that part's normal and roughness/metal maps.
"""
import glob
import sys

import numpy as np
from PIL import Image

PASSES = 24


def dilate(img: np.ndarray, mask: np.ndarray) -> np.ndarray:
    out = img.astype(np.float32)
    filled = ~mask
    for _ in range(PASSES):
        if filled.all():
            break
        acc = np.zeros_like(out)
        cnt = np.zeros(filled.shape, np.float32)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)):
            shifted = np.roll(np.roll(out, dy, 0), dx, 1)
            ok = np.roll(np.roll(filled, dy, 0), dx, 1)
            acc += shifted * ok[..., None]
            cnt += ok
        grow = (~filled) & (cnt > 0)
        out[grow] = acc[grow] / cnt[grow][:, None]
        filled = filled | grow
    return out.clip(0, 255).astype(np.uint8)


def main(prefix: str) -> None:
    for base_path in sorted(glob.glob(prefix + "*_basecolor.jpg")):
        stem = base_path[: -len("_basecolor.jpg")]
        base = np.array(Image.open(base_path).convert("RGB"))
        mask = base.max(axis=2) < 6
        if not mask.any():
            continue
        Image.fromarray(dilate(base, mask)).save(base_path, quality=94)
        for suffix in ("_normal.jpg", "_rm.png"):
            path = stem + suffix
            try:
                other = Image.open(path)
            except FileNotFoundError:
                continue
            arr = np.array(other.convert("RGB"))
            m = mask
            if arr.shape[:2] != mask.shape:
                m = np.array(Image.fromarray(mask.astype(np.uint8) * 255).resize(arr.shape[1::-1])) > 127
            padded = Image.fromarray(dilate(arr, m))
            if path.endswith(".jpg"):
                padded.save(path, quality=94)
            else:
                padded.save(path)
        print("padded", base_path.split("/")[-1], f"{mask.mean() * 100:.0f}% gutter")


if __name__ == "__main__":
    main(sys.argv[1])
