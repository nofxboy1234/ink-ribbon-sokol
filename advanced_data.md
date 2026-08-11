# Advanced Data: LearnOpenGL mapped to Sokol + Zig

This is a compact, standalone map of the
[LearnOpenGL Advanced Data chapter](https://learnopengl.com/Advanced-OpenGL/Advanced-Data)
to this project.

Run the scene:

```bash
zig build run-advanced-data
```

WASM:

```bash
zig build run-advanced-data -Dtarget=wasm32-emscripten
```

## 1. The whole idea

A GPU buffer is simply a numbered row of bytes:

```text
byte offset   0                                   size - 1
              ├────────────────────────────────────────┤
              │              GPU memory                │
              └────────────────────────────────────────┘
```

The bytes only gain meaning when you describe how they will be used:

```text
buffer + vertex layout + vertex-buffer binding = vertex data
buffer + index-buffer binding                  = vertex indices
```

Mental model: **the buffer is a warehouse; its usage and layout are the labels
that explain what is stored on each shelf.**

Sokol makes those labels explicit when creating a buffer, pipeline, and
bindings. It avoids OpenGL's mutable global binding targets.

## 2. Quick OpenGL → Sokol map

| OpenGL concept                         | Sokol + Zig                                                   |
|----------------------------------------|---------------------------------------------------------------|
| `glGenBuffers`                         | `sg.makeBuffer()`                                             |
| `glBufferData(..., data, usage)`       | `sg.makeBuffer(.{ .data = sg.asRange(&data), .usage = ... })` |
| `glBufferData(..., NULL, usage)`       | `sg.makeBuffer(.{ .size = byte_count, .usage = ... })`        |
| `GL_STATIC_DRAW`                       | `.usage = .{ .immutable = true }` (the default)               |
| `GL_DYNAMIC_DRAW`                      | `.usage = .{ .dynamic_update = true }`                        |
| `GL_STREAM_DRAW`                       | `.usage = .{ .stream_update = true }`                         |
| `glBufferSubData`                      | Usually `sg.updateBuffer()` or `sg.appendBuffer()`            |
| `glMapBuffer` / `glUnmapBuffer`        | No portable public equivalent in `sokol_gfx`                  |
| `glVertexAttribPointer`                | `sg.PipelineDesc.layout`                                      |
| Bind a VBO for drawing                 | `sg.Bindings.vertex_buffers[]`                                |
| `glCopyBufferSubData`                  | No portable public `sokol_gfx` equivalent                     |

## 3. Allocate now, fill later

OpenGL accepts `NULL` in `glBufferData` to reserve capacity. In Sokol, provide
`.size` and omit `.data`:

```zig
const vertex_buffer = sg.makeBuffer(.{
    .size = @sizeOf([3]Vertex),
    .usage = .{ .vertex_buffer = true, .stream_update = true },
});
```

```text
makeBuffer(size only)       updateBuffer(data)
┌────────────────────┐      ┌────────────────────┐
│ undefined capacity │ ───► │ useful vertex bytes│
└────────────────────┘      └────────────────────┘
```

Reserved memory is **not automatically zero-filled**. Do not draw bytes until
you have uploaded valid data for them.

The right triangle in `src/advanced_data.zig` demonstrates this. Its vertices
are replaced each frame, which makes the triangle move.

## 4. Updating buffer contents

`sg.updateBuffer()` replaces buffer data from byte offset zero:

```zig
sg.updateBuffer(vertex_buffer, sg.asRange(&vertices));
```

Important Sokol rules:

- Create the buffer with `.dynamic_update` or `.stream_update`.
- Call `updateBuffer` at most once per buffer per frame.
- The uploaded range may be smaller than the buffer, but it starts at zero.
- Do not mix `updateBuffer` and `appendBuffer` on the same buffer in one frame.

Unlike `glBufferSubData`, `sg.updateBuffer` does not accept an arbitrary
destination offset. For several chunks in one frame, use `sg.appendBuffer`:

```zig
const offset = sg.appendBuffer(stream_buffer, sg.asRange(&vertices));
bindings.vertex_buffer_offsets[0] = offset;
```

Mental model:

```text
updateBuffer = replace the writing at the start of the whiteboard
appendBuffer = add the next note after the notes already written this frame
```

`appendBuffer` returns the byte offset of the new chunk. Put that offset in
`sg.Bindings` so drawing begins at the correct bytes. Check
`sg.queryBufferWillOverflow()` when the amount of streamed data is uncertain.

## 5. Why Sokol has no `mapBuffer`

OpenGL's `glMapBuffer` exposes a pointer for writing mapped buffer memory.
`sokol_gfx` deliberately does not expose a portable mapping API. Different
backends handle CPU/GPU-visible memory differently.

Use ordinary Zig memory, then upload it:

```text
Zig array/struct ── sg.asRange() ── sg.updateBuffer() ──► GPU buffer
```

This may look less direct, but Sokol can choose a safe upload strategy for
OpenGL, Metal, D3D11, WebGPU, and WebGL.

## 6. Interleaved vertex attributes

Most examples in this project interleave attributes:

```text
vertex 0          vertex 1          vertex 2
P0 C0             P1 C1             P2 C2
└──── stride ────►└──── stride ────►
```

```zig
const Vertex = extern struct {
    position: [2]f32,
    color: [3]f32,
};
```

The pipeline explains how to decode each `Vertex`:

```zig
layout.buffers[0].stride = @sizeOf(Vertex);
layout.attrs[position_slot] = .{
    .format = .FLOAT2,
    .offset = @offsetOf(Vertex, "position"),
};
layout.attrs[color_slot] = .{
    .format = .FLOAT3,
    .offset = @offsetOf(Vertex, "color"),
};
```

Mental model: the GPU reads one complete **vertex record** at a time. This is
usually cache-friendly and is Sokol's normal style.

The left triangle uses this layout.

## 7. Grouped—or planar—attributes

The chapter also puts each attribute in one large block:

```text
all positions              all colours
P0 P1 P2                   C0 C1 C2
└── position region ───────┴── colour region ──►
```

The middle triangle stores both regions in one `sg.Buffer`. It binds that same
buffer into two slots, but starts the colour slot later:

```zig
bindings.vertex_buffers[0] = planar_buffer;
bindings.vertex_buffers[1] = planar_buffer;
bindings.vertex_buffer_offsets[1] = @offsetOf(PlanarData, "colors");
```

The pipeline connects shader inputs to those slots:

```zig
layout.attrs[position_slot].buffer_index = 0;
layout.attrs[color_slot].buffer_index = 1;
```

```text
shader position ◄── slot 0 ◄── buffer + position offset
shader colour   ◄── slot 1 ◄── same buffer + colour offset
```

Grouped data is convenient when a loader already supplies separate arrays.
Interleaved data is generally preferred when every vertex shader invocation
needs every attribute, because one vertex's data sits close together.

## 8. Copying buffers

`glCopyBufferSubData` copies bytes directly between GPU buffers. Core
`sokol_gfx` has no portable public buffer-to-buffer copy operation.

Choose based on why you need the copy:

```text
CPU already owns the data?       upload it to each destination
building streamed draw data?     append chunks into one stream buffer
GPU must produce/copy the data?   use a backend-specific or compute design
```

Do not call native OpenGL functions casually inside Sokol rendering: that
breaks portability and can desynchronize Sokol's state cache.

## 9. What the scene proves

All three triangles use the same vertex shader and produce the same kind of
pixels. Only their buffer organization differs:

```text
left                  middle                  right
interleaved           grouped                 reserved + updated
P0C0 P1C1 P2C2        P0P1P2 C0C1C2           ????? → P0C0 P1C1 P2C2
immutable             immutable               stream_update
```

The central lesson is:

> A buffer is bytes. The usage flags say how those bytes may change; the
> pipeline layout says how to interpret them; bindings say which buffer and
> byte offset to read for a draw.

## Quick source map

| Lesson concept                   | Project location                               |
|----------------------------------|------------------------------------------------|
| Immutable interleaved data       | `interleaved` in `init()`                      |
| Grouped attribute arrays         | `PlanarData` and `planarLayout()`              |
| Reserve without initial data     | `dynamic_bindings` buffer in `init()`          |
| Replace mutable data             | `sg.updateBuffer()` in `frame()`               |
| Attribute formats and offsets    | `interleavedLayout()` and `planarLayout()`     |
| Shader attribute inputs          | `src/advanced_data.glsl`                       |
