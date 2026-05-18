#!/usr/bin/env python3
# /// script
# dependencies = [
#     "pillow>=12.2.0",
# ]
# ///

# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
"""
Fail if any given image file exceeds 4096px wide or 4096px high.
"""

import argparse
import sys

from PIL import Image, UnidentifiedImageError

# https://docs.godotengine.org/en/stable/tutorials/3d/3d_rendering_limitations.html
# “if you want your texture to display correctly on all platforms, you should
# avoid using textures larger than 4096×4096”
MAX_SIZE = 4096


def check(path) -> bool:
    try:
        with Image.open(path) as im:
            width, height = im.size
    except (UnidentifiedImageError, OSError) as e:
        print(f"{path}: could not read image ({e})", file=sys.stderr)
        return False

    if width > MAX_SIZE or height > MAX_SIZE:
        print(
            f"{path}: {width}x{height} exceeds {MAX_SIZE}x{MAX_SIZE}",
            file=sys.stderr,
        )
        return False

    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*")
    args = parser.parse_args()

    return not all([check(path) for path in args.files])


if __name__ == "__main__":
    sys.exit(main())
