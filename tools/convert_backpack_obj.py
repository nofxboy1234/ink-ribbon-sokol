#!/usr/bin/env python3
"""Convert LearnOpenGL's triangulated backpack OBJ to interleaved GPU vertices.

Output vertex layout: position.xyz, normal.xyz, uv.xy as eight little-endian
32-bit floats. The runtime can upload this file directly to a Sokol buffer.
"""
import pathlib
import struct

root = pathlib.Path(__file__).resolve().parent.parent
source = root / "src/assets/backpack/backpack.obj"
destination = root / "src/assets/backpack/vertices.bin"

positions = []
normals = []
uvs = []
vertex_count = 0

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
                vertex_count += 1

print(f"wrote {vertex_count} vertices ({destination.stat().st_size} bytes)")
