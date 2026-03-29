from PIL import Image
import numpy as np
import sys

META_FILE = "image.meta"


# Prepare image data for encryption by converting to bytes and padding to a multiple of 16
def prepare(input_path, mode='RGB'):
    img = Image.open(input_path).convert(mode)
    width, height = img.size

    data = np.array(img, dtype=np.uint8).tobytes()

    # Pad to multiple of 16
    pad_len = (16 - (len(data) % 16)) % 16
    data += b'\x00' * pad_len

    with open("image.bin", "wb") as f:
        f.write(data)

    # Save metadata
    with open(META_FILE, "w") as f:
        f.write(f"{width} {height} {mode}")

    print(f"Saved image.bin ({len(data)} bytes)")
    print(f"Dimensions: {width}x{height} {mode}")

# View the bin file as an image that is either encrypted or decrypted
def view(bin_path):
    # Load metadata
    with open(META_FILE, "r") as f:
        width, height, mode = f.read().split()
        width, height = int(width), int(height)

    with open(bin_path, "rb") as f:
        data = f.read()

    bpp = 3 if mode == 'RGB' else 1
    size = width * height * bpp

    arr = np.frombuffer(data[:size], dtype=np.uint8)

    if mode == 'RGB':
        arr = arr.reshape((height, width, 3))
    else:
        arr = arr.reshape((height, width))

    img = Image.fromarray(arr, mode)
    out = bin_path.replace(".bin", ".png")
    img.save(out)
    img.show()

    print(f"Saved {out}")


# Compare two bin files to ensure encryption/decryption worked correctly

def compare(file1, file2):
    d1 = open(file1, "rb").read()
    d2 = open(file2, "rb").read()

    print("Same size:", len(d1) == len(d2))
    print("Identical:", d1 == d2)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python script.py prepare image.png [--grey]")
        print("  python script.py view image.bin")
        print("  python script.py compare a.bin b.bin")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "prepare":
        mode = 'L' if '--grey' in sys.argv else 'RGB'
        prepare(sys.argv[2], mode)

    elif cmd == "view":
        view(sys.argv[2])

    elif cmd == "compare":
        compare(sys.argv[2], sys.argv[3])