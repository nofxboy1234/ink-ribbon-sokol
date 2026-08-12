# Instancing: LearnOpenGL mapped to Sokol + Zig

This is a concise, standalone map of the
[LearnOpenGL Instancing chapter](https://learnopengl.com/Advanced-OpenGL/Instancing)
to this project.

Run the scene:

```bash
zig build run-instancing
```

WASM:

```bash
zig build run-instancing -Dtarget=wasm32-emscripten
```

| Key | Scene                                                       |
|-----|-------------------------------------------------------------|
| `1` | Grid positions calculated from the instance index           |
| `2` | Offset, colour, and scale read from an instance buffer      |

## 1. The whole idea

Without instancing, 100 identical meshes might require 100 draw commands:

```text
CPU: draw quad 0
CPU: draw quad 1
CPU: draw quad 2
... 97 more commands
```

With instancing:

```text
CPU: draw this quad 100 times
                    │
                    ▼
GPU creates the 100 copies
```

Mental model: **send one rubber stamp and a list of places to stamp it.**

The mesh may be tiny, but repeatedly asking the GPU to begin another draw has
CPU and driver overhead. Instancing reduces those commands when many objects
share the same mesh, pipeline, and resources.

## 2. OpenGL → Sokol map

| OpenGL                                      | Sokol + Zig                                      |
|---------------------------------------------|--------------------------------------------------|
| `glDrawArraysInstanced(..., count)`         | `sg.draw(base, elements, count)`                 |
| `glDrawElementsInstanced(..., count)`       | Same `sg.draw`; pipeline has an index type       |
| `gl_InstanceID`                             | `gl_InstanceIndex` in portable shdc source       |
| Instance VBO                                | `sg.Buffer` in another vertex-buffer slot        |
| `glVertexAttribPointer`                     | `sg.PipelineDesc.layout.attrs[]`                 |
| `glVertexAttribDivisor(attribute, 1)`       | Buffer layout `.step_func = .PER_INSTANCE`       |
| Attribute divisor greater than one          | `.step_rate`                                     |
| Bind mesh and instance VBOs                 | `sg.Bindings.vertex_buffers[0]` and `[1]`        |

The important Sokol call is:

```zig
sg.draw(0, quad.len, instance_count);
```

Its arguments mean:

```text
start at mesh element 0
read 6 mesh vertices per copy
make 100 copies
```

## 3. Two counters advance at different speeds

The scene binds two buffers:

```text
buffer 0: mesh vertices       advances every vertex
buffer 1: instance records    advances every instance
```

For a six-vertex quad:

```text
vertex invocation   mesh record   instance record
0                   vertex 0      instance 0
1                   vertex 1      instance 0
...                 ...           instance 0
5                   vertex 5      instance 0
6                   vertex 0      instance 1
7                   vertex 1      instance 1
```

Every corner of one copy receives the same offset, colour, and scale. The mesh
counter then returns to vertex zero while the instance counter advances.

## 4. Using the instance index

Mode `1` needs no instance buffer. The vertex shader uses the current copy's
number:

```glsl
int column = gl_InstanceIndex % 10;
int row = gl_InstanceIndex / 10;
```

```text
instance 0  → row 0, column 0
instance 9  → row 0, column 9
instance 10 → row 1, column 0
instance 99 → row 9, column 9
```

OpenGL calls this built-in `gl_InstanceID`. Portable `sokol-shdc` source uses
`gl_InstanceIndex`, which it translates for GLSL, HLSL, Metal, and WGSL.

The chapter uses the ID to index a uniform array of offsets. Calculating this
regular grid directly is simpler, but the mental model is identical:

```text
instance number ──► find this copy's unique data ──► position the copy
```

An ID is useful for regular patterns, random-number seeds, or indexing another
GPU data source. It becomes awkward when every instance needs much structured
data, and uniform storage is limited.

## 5. Instanced vertex buffers

Mode `2` stores 100 records:

```zig
const Instance = extern struct {
    offset: [2]f32,
    color: [3]f32,
    scale: f32,
};
```

```text
instance buffer
├── record 0: offset, colour, scale
├── record 1: offset, colour, scale
├── record 2: offset, colour, scale
└── ...
```

The pipeline marks the entire second buffer as per-instance:

```zig
layout.buffers[1] = .{
    .stride = @sizeOf(Instance),
    .step_func = .PER_INSTANCE,
};
```

Each shader attribute then points into that record:

```zig
layout.attrs[offset_attribute] = .{
    .buffer_index = 1,
    .offset = @offsetOf(Instance, "offset"),
    .format = .FLOAT2,
};
```

Mental model:

```text
stride = distance from one complete instance record to the next
offset = location of one field inside that record
```

The shader receives ordinary-looking attributes:

```glsl
in vec2 instance_offset;
in vec3 instance_color;
in float instance_scale;
```

Sokol's pipeline layout—not the shader declaration alone—makes them advance
per instance.

## 6. Why a divisor exists

OpenGL's divisor `1` means “advance once per instance.” In Sokol:

```zig
.step_func = .PER_INSTANCE,
.step_rate = 1,
```

`step_rate` normally defaults to the useful rate for per-instance data. A rate
of `2` would reuse one record for two consecutive instances:

```text
instances 0,1 → record 0
instances 2,3 → record 1
```

Most instancing uses a rate of one.

## 7. Per-instance transformation matrices

An asteroid needs more than a 2D offset. It usually gets one model matrix:

```text
instance 0 → model matrix 0
instance 1 → model matrix 1
...
```

A GPU vertex attribute holds at most one four-component vector. A `mat4` is
four column vectors, so it occupies four consecutive attributes:

```text
matrix column 0 → FLOAT4 attribute
matrix column 1 → FLOAT4 attribute
matrix column 2 → FLOAT4 attribute
matrix column 3 → FLOAT4 attribute
```

All four come from the same `.PER_INSTANCE` buffer and use byte offsets `0`,
`16`, `32`, and `48`. The Box3D example uses this pattern for its transform
rows plus colour in `displayInstancedLayout()`.

The vertex shader conceptually computes:

```glsl
gl_Position = projection * view * instance_model * vec4(position, 1.0);
```

## 8. The asteroid-field mapping

The chapter changes this:

```text
for every asteroid:
    upload model matrix
    issue draw
```

into this:

```text
one rock mesh buffer
one array of asteroid model matrices
one instanced draw per rock submesh
```

The planet is a different mesh, so it remains a separate draw. If the rock
model contains several submeshes/materials, each compatible submesh normally
needs its own instanced draw.

Instancing reduces draw-command overhead; it does not make vertices free:

```text
100,000 copies × 576 mesh vertices = 57,600,000 vertex-shader invocations
```

The GPU still performs the work, but receives far fewer commands from the CPU.

## 9. When instancing helps

Good fits:

- Grass, trees, rocks, particles, crowds, repeated props
- One mesh and pipeline with compact per-instance differences
- Enough copies that draw-call overhead matters

Less helpful when instances require different meshes, shaders, materials, or
large unique resource sets. Those differences can force separate batches.

If instance transforms change each frame, create the instance buffer with
`.stream_update = true` and refresh it using `sg.updateBuffer()`. Static data,
like this scene's grid, uses the default immutable buffer.

## Final mental model

```text
shared per-vertex stream       per-instance stream
one quad's six corners         100 unique records
          │                           │
          └──────────┬────────────────┘
                     ▼
               vertex shader
                     │
                     ▼
        sg.draw(0, 6, 100): one command
```

## Quick source map

| Lesson concept                 | Project location                          |
|--------------------------------|-------------------------------------------|
| Shared six-vertex quad         | `quad`                                    |
| Instance-index grid            | `index_vs`                                |
| Per-instance record            | `Instance`                                |
| Instance buffer                | `state.bindings.vertex_buffers[1]`        |
| Per-instance stepping          | `makeBufferPipeline()`                    |
| One 100-instance draw          | `sg.draw()` in `frame()`                  |
| Production instancing example  | `displayInstancedLayout()` in `box3d.zig` |
