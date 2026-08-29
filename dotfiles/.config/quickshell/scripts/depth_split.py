#!/usr/bin/env python3
import sys
import numpy as np
from PIL import Image, ImageFilter
from transformers import pipeline

def split_by_depth(image_path, threshold=0.6, feather=20):
    image = Image.open(image_path).convert("RGB")

    pipe = pipeline("depth-estimation", model="depth-anything/Depth-Anything-V2-Small-hf")
    depth = np.array(pipe(image)["depth"], dtype=np.float32)

    # normalize 0-1, higher = closer
    depth = (depth - depth.min()) / (depth.max() - depth.min())

    # soft mask — blur edges so fg blends naturally
    mask = Image.fromarray((depth * 255).astype(np.uint8))
    mask = mask.filter(ImageFilter.GaussianBlur(radius=feather))
    mask_arr = np.array(mask, dtype=np.float32) / 255.0

    fg_mask = (mask_arr > threshold).astype(np.uint8) * 255
    fg_mask_img = Image.fromarray(fg_mask).filter(ImageFilter.GaussianBlur(radius=feather))

    img_arr = np.array(image)
    fg = np.zeros((img_arr.shape[0], img_arr.shape[1], 4), dtype=np.uint8)
    fg[:, :, :3] = img_arr
    fg[:, :, 3] = np.array(fg_mask_img)

    image.save("wallpaper_bg.png")
    Image.fromarray(fg, "RGBA").save("wallpaper_fg.png")
    print("Saved: wallpaper_bg.png, wallpaper_fg.png")

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "wallpaper.jpg"
    threshold = float(sys.argv[2]) if len(sys.argv) > 2 else 0.6
    split_by_depth(path, threshold)
