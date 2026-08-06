#!/usr/bin/env python3
"""Convert LearnOpenGL's triangulated backpack OBJ to interleaved GPU vertices.

Output vertex layout: position.xyz, normal.xyz, uv.xy as eight little-endian
32-bit floats. The runtime can upload this file directly to a Sokol buffer.
"""
import pathlib
import json
import struct
import zlib

root = pathlib.Path(__file__).resolve().parent.parent
source = root / "src/assets/backpack/backpack.obj"
destination = root / "src/assets/backpack/vertices.bin"


def write_rgba_png(source_path, destination_path, width=512, height=512):
    """Wrap the existing raw RGBA teaching asset in a standard PNG file."""
    pixels = source_path.read_bytes()
    if len(pixels) != width * height * 4:
        raise ValueError(f"unexpected RGBA byte count in {source_path}")
    scanlines = b"".join(
        b"\0" + pixels[y * width * 4:(y + 1) * width * 4]
        for y in range(height)
    )

    def chunk(kind, payload):
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))

    destination_path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(scanlines, 9))
        + chunk(b"IEND", b"")
    )

positions = []
normals = []
uvs = []
vertex_count = 0
minimum = [float("inf")] * 3
maximum = [float("-inf")] * 3

with source.open("r", encoding="utf-8") as obj, destination.open("wb") as output:
    for line in obj:
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "v":
            positions.append(tuple(map(float, fields[1:4])))
        elif fields[0] == "vn":
            normals.append(tuple(map(float, fields[1:4])))
        elif fields[0] == "vt":
            uvs.append(tuple(map(float, fields[1:3])))
        elif fields[0] == "f":
            if len(fields) != 4:
                raise ValueError("the teaching converter expects triangulated OBJ faces")
            for reference in fields[1:]:
                position_index, uv_index, normal_index = (
                    int(index) - 1 for index in reference.split("/")
                )
                output.write(struct.pack(
                    "<8f",
                    *positions[position_index],
                    *normals[normal_index],
                    *uvs[uv_index],
                ))
                for axis, value in enumerate(positions[position_index]):
                    minimum[axis] = min(minimum[axis], value)
                    maximum[axis] = max(maximum[axis], value)
                vertex_count += 1

gltf = {
    "asset": {"version": "2.0", "generator": "ink-ribbon OBJ teaching converter"},
    "extensionsUsed": ["KHR_materials_specular"],
    "buffers": [{"uri": "vertices.bin", "byteLength": destination.stat().st_size}],
    "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": destination.stat().st_size, "byteStride": 32, "target": 34962}],
    "accessors": [
        {"bufferView": 0, "byteOffset": 0, "componentType": 5126, "count": vertex_count, "type": "VEC3", "min": minimum, "max": maximum},
        {"bufferView": 0, "byteOffset": 12, "componentType": 5126, "count": vertex_count, "type": "VEC3"},
        {"bufferView": 0, "byteOffset": 24, "componentType": 5126, "count": vertex_count, "type": "VEC2"},
    ],
    "images": [{"uri": "diffuse.png"}, {"uri": "specular.png"}],
    "samplers": [{"magFilter": 9729, "minFilter": 9729, "wrapS": 10497, "wrapT": 10497}],
    "textures": [{"sampler": 0, "source": 0}, {"sampler": 0, "source": 1}],
    "materials": [{
        "name": "backpack",
        "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0.0, "roughnessFactor": 0.5},
        "extensions": {"KHR_materials_specular": {"specularTexture": {"index": 1}}},
    }],
    "meshes": [{"name": "backpack", "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "material": 0, "mode": 4}]}],
    "nodes": [{"name": "backpack", "mesh": 0}],
    "scenes": [{"nodes": [0]}],
    "scene": 0,
}
(source.parent / "backpack.gltf").write_text(json.dumps(gltf, indent=2) + "\n", encoding="utf-8")
write_rgba_png(source.parent / "diffuse.rgba", source.parent / "diffuse.png")
write_rgba_png(source.parent / "specular.rgba", source.parent / "specular.png")
print(f"wrote {vertex_count} vertices ({destination.stat().st_size} bytes)")
