import io
import struct
import sys

from PIL import Image


def save(im, fmt, **kw):
    buf = io.BytesIO()
    im.save(buf, fmt, **kw)
    return buf.getvalue()


def solid(w, h, color=(200, 30, 60), mode="RGB"):
    return Image.new(mode, (w, h), color)


def gradient(w, h):
    im = Image.new("RGB", (w, h))
    px = im.load()
    for y in range(h):
        for x in range(w):
            px[x, y] = ((x * 37) % 256, (y * 53) % 256, ((x + y) * 29) % 256)
    return im


def bmp_os2(w, h):
    row = (w * 3 + 3) // 4 * 4
    data = bytes([0x20, 0x40, 0x80] * w + [0] * (row - w * 3)) * h
    head = b"BM" + struct.pack("<IHHI", 14 + 12 + len(data), 0, 0, 14 + 12)
    dib = struct.pack("<IHHHH", 12, w, h, 1, 24)
    return head + dib + data


def bmp_topdown(w, h):
    data = save(gradient(w, h), "BMP")
    fixed = bytearray(data)
    fixed[22:26] = struct.pack("<i", -h)
    return bytes(fixed)


def heic_like(w, h):
    def box(kind, payload):
        return struct.pack(">I", 8 + len(payload)) + kind + payload

    ispe = box(b"ispe", b"\0\0\0\0" + struct.pack(">II", w, h))
    thumb = box(b"ispe", b"\0\0\0\0" + struct.pack(">II", 8, 6))
    ipco = box(b"ipco", thumb + ispe)
    iprp = box(b"iprp", ipco)
    meta = box(b"meta", b"\0\0\0\0" + iprp)
    ftyp = box(b"ftyp", b"heic" + b"\0\0\0\0" + b"mif1heic")
    mdat = box(b"mdat", b"\x11" * 40)
    return ftyp + meta + mdat


def mp4_like():
    def box(kind, payload):
        return struct.pack(">I", 8 + len(payload)) + kind + payload

    return box(b"ftyp", b"isom" + b"\0\0\2\0" + b"isomiso2mp41") + box(b"mdat", b"\x00" * 30)


def svg_text(body, prolog=False, bom=False):
    out = ""
    if prolog:
        out += '<?xml version="1.0" encoding="UTF-8"?>\n'
    out += body
    data = out.encode("utf-8")
    if bom:
        data = b"\xef\xbb\xbf" + data
    return data


F = {}


def add(name, data, fmt, w=None, h=None, via=None):
    F[name] = dict(data=data, format=fmt, width=w, height=h, via=via)


add("png_rgb_3x2", save(gradient(3, 2), "PNG"), "png", 3, 2)
add("png_rgba_1x1", save(Image.new("RGBA", (1, 1), (1, 2, 3, 4)), "PNG"), "png", 1, 1)
add("png_solid_256", save(solid(256, 256), "PNG"), "png", 256, 256)
add("png_wide_300x100", save(gradient(300, 100), "PNG", optimize=True), "png", 300, 100)

add("jpeg_baseline_8x8", save(gradient(8, 8), "JPEG", quality=80), "jpeg", 8, 8)
add("jpeg_progressive_16x16", save(gradient(16, 16), "JPEG", progressive=True, quality=70), "jpeg", 16, 16)
add("jpeg_gray_5x7", save(gradient(5, 7).convert("L"), "JPEG"), "jpeg", 5, 7)
add("jpeg_comment_12x9", save(gradient(12, 9), "JPEG", comment=b"hello " * 120), "jpeg", 12, 9)
ex = Image.Exif()
ex[0x010F] = "Atsuko"
ex[0x0110] = "Test camera"
add("jpeg_exif_10x6", save(gradient(10, 6), "JPEG", exif=ex.tobytes()), "jpeg", 10, 6)

add("gif_static_5x4", save(gradient(5, 4).convert("P"), "GIF"), "gif", 5, 4)
add("gif_animated_6x6", save(solid(6, 6), "GIF", save_all=True, append_images=[solid(6, 6, (0, 0, 255)), solid(6, 6, (0, 255, 0))], duration=100, loop=0), "gif", 6, 6)

add("bmp_24_3x2", save(gradient(3, 2), "BMP"), "bmp", 3, 2)
add("bmp_8_4x4", save(gradient(4, 4).convert("P"), "BMP"), "bmp", 4, 4)
add("bmp_topdown_3x2", bmp_topdown(3, 2), "bmp", 3, 2)
add("bmp_os2_2x2", bmp_os2(2, 2), "bmp", 2, 2)

add("webp_lossy_8x8", save(gradient(8, 8), "WEBP", quality=60), "webp", 8, 8)
add("webp_lossless_8x8", save(gradient(8, 8), "WEBP", lossless=True), "webp", 8, 8)
add("webp_lossless_100x37", save(gradient(100, 37), "WEBP", lossless=True), "webp", 100, 37)
add("webp_alpha_9x7", save(Image.new("RGBA", (9, 7), (10, 20, 30, 128)), "WEBP", quality=60), "webp", 9, 7)
add("webp_anim_8x8", save(solid(8, 8), "WEBP", save_all=True, append_images=[solid(8, 8, (0, 0, 255))], duration=100), "webp", 8, 8)

add("ico_16_32", save(solid(32, 32), "ICO", sizes=[(16, 16), (32, 32)]), "ico", 32, 32)
add("ico_256", save(solid(256, 256), "ICO", sizes=[(256, 256)]), "ico", 256, 256)
add("ico_48", save(gradient(48, 48), "ICO", sizes=[(48, 48)]), "ico", 48, 48)

add("avif_8x8", save(gradient(8, 8), "AVIF"), "avif", 8, 8)
add("avif_rgba_6x4", save(Image.new("RGBA", (6, 4), (9, 8, 7, 100)), "AVIF"), "avif", 6, 4)
add("heic_like_64x48", heic_like(64, 48), "heic", 64, 48)

add("svg_wh", svg_text('<svg xmlns="http://www.w3.org/2000/svg" width="120" height="80"><rect width="120" height="80" fill="red"/></svg>'), "svg", 120, 80)
add("svg_units", svg_text('<svg xmlns="http://www.w3.org/2000/svg" width="64px" height="32.4px"><circle r="4"/></svg>'), "svg", 64, 32)
add("svg_viewbox", svg_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 16"><path d="M0 0"/></svg>'), "svg", 24, 16)
add("svg_percent", svg_text('<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 50 40"><path d="M0 0"/></svg>'), "svg", 50, 40)
add("svg_prolog", svg_text('<svg xmlns="http://www.w3.org/2000/svg" width="10" height="20"></svg>', prolog=True), "svg", 10, 20)
add("svg_bom", svg_text('  \n<svg xmlns="http://www.w3.org/2000/svg" width="7" height="9"></svg>', bom=True), "svg", 7, 9)
add("svg_selfclosed", svg_text('<svg xmlns="http://www.w3.org/2000/svg" width="3" height="3"/>'), "svg", 3, 3)
add("svg_stroke_width", svg_text('<svg xmlns="http://www.w3.org/2000/svg" stroke-width="9" width="30" height="15"></svg>'), "svg", 30, 15)

add("tga_raw_4x3", save(gradient(4, 3), "TGA"), "tga", 4, 3)
add("tga_rle_4x3", save(solid(4, 3), "TGA", compression="tga_rle"), "tga", 4, 3)

NOT = {
    "html_page": b"<!DOCTYPE html>\n<html><head><title>Expired</title></head><body>This link has expired</body></html>",
    "html_lower": b"<html><body>404</body></html>",
    "json_error": b'{"message": "You are being rate limited.", "retry_after": 1.5}',
    "json_list": b"[1, 2, 3]",
    "empty": b"",
    "text": b"just some words in a text file\nsecond line\n",
    "lua_source": b"local hub = AtsukoHub\nprint(hub)\n",
    "zip": b"PK\x03\x04\x14\x00\x00\x00\x08\x00" + b"\x00" * 30,
    "pdf": b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n1 0 obj\n",
    "random": bytes((i * 131 + 7) % 256 for i in range(200)),
    "ogg": b"OggS\x00\x02" + b"\x00" * 40,
    "mp3": b"ID3\x03\x00\x00\x00\x00\x00\x00" + b"\xff\xfb" * 20,
    "wav": b"RIFF\x24\x00\x00\x00WAVEfmt " + b"\x10\x00\x00\x00" * 4,
    "mp4": mp4_like(),
    "bm_text": b"BMW makes cars, this is a normal sentence of text.",
    "cur": b"\x00\x00\x02\x00\x01\x00\x10\x10\x00\x00\x01\x00\x20\x00\x30\x00\x00\x00\x16\x00\x00\x00" + b"\x00" * 60,
    "png_with_prefix": b"\xef\xbb\xbf" + save(gradient(2, 2), "PNG"),
    "zero_run": b"\x00" * 64,
}

for name, item in F.items():
    d = item["data"]
    if item["format"] in ("png", "jpeg", "gif", "bmp", "webp", "ico", "tga", "avif"):
        try:
            im = Image.open(io.BytesIO(d))
            if im.size != (item["width"], item["height"]):
                print("SIZE MISMATCH", name, im.size, item["width"], item["height"], file=sys.stderr)
                sys.exit(2)
        except Exception as e:
            print("CANNOT OPEN", name, e, file=sys.stderr)
            if item["format"] != "avif":
                sys.exit(3)

out = ["return {\n\tvalid = {\n"]
for name in sorted(F):
    item = F[name]
    out.append('\t\t%s = { hex = "%s", format = "%s", width = %s, height = %s },\n' % (name, item["data"].hex(), item["format"], item["width"], item["height"]))
out.append("\t},\n\tnot_images = {\n")
for name in sorted(NOT):
    out.append('\t\t%s = "%s",\n' % (name, NOT[name].hex()))
out.append("\t},\n}\n")
open(sys.argv[1], "w", encoding="utf-8").write("".join(out))
print("fixtures:", len(F), "not images:", len(NOT), "bytes:", sum(len(v["data"]) for v in F.values()))
