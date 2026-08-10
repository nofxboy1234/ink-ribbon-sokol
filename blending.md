# Blending: LearnOpenGL mapped to Sokol + Zig

This lesson maps the [LearnOpenGL blending chapter](https://learnopengl.com/Advanced-OpenGL/Blending)
to this project's Sokol + Zig setup.

Run it natively:

```bash
zig build run-blending
```

Run the WASM version:

```bash
zig build run-blending -Dtarget=wasm32-emscripten
```

Controls:

| Key | Scene                                                         |
|-----|---------------------------------------------------------------|
| `1` | Grass using alpha testing and `discard`                       |
| `2` | Semi-transparent windows drawn in the wrong, unsorted order   |
| `3` | Semi-transparent windows sorted from farthest to nearest      |

Mode `3` is the chapter's final result and the default.

## 1. What blending means

An opaque fragment completely replaces the old framebuffer colour:

```text
old pixel: blue
new opaque fragment: red

result: red
```

A transparent fragment combines its colour with the colour already there:

```text
transparent green glass
          +
red object behind it
          ↓
mixed green/red pixel
```

This combination is **blending**.

## 2. Alpha

An RGBA colour has four components:

```text
(red, green, blue, alpha)
```

Alpha normally describes how much of the new fragment contributes:

```text
alpha = 1.0  → completely opaque
alpha = 0.5  → partly transparent
alpha = 0.0  → completely transparent
```

The window and grass PNG files contain an alpha value for each texel. The
example decodes every texture to RGBA and creates a Sokol `.RGBA8` image:

```zig
const pixels = model_image.model_image_decode_rgba(...);

const image = sg.makeImage(.{
    .pixel_format = .RGBA8,
    .data = image_data,
});
```

This maps the chapter's RGBA `glTexImage2D` upload to Sokol resource creation.

## 3. Fully transparent cutouts

Grass is represented by a rectangular quad:

```text
the actual geometry
┌────────────────┐
│ transparent    │
│    grass       │
│ transparent    │
└────────────────┘
```

We want only the grass-shaped texels. The cutout fragment shader samples the
texture and discards almost-transparent fragments:

```glsl
vec4 texel = texture(sampler2D(tex, smp), uv);
if (texel.a < 0.1) {
    discard;
}
frag_color = texel;
```

`discard` stops that fragment:

```text
sample texture
      ↓
alpha below 0.1? ── yes ──► no colour write and no depth write
      │
      no
      ↓
draw the texel normally
```

OpenGL and Sokol use the same GLSL `discard` operation here. This is not
partial transparency: each fragment is either kept or removed.

## 4. Clamp alpha textures at their edges

With repeating texture coordinates, filtering near one edge can sample the
opposite edge:

```text
right edge ── filtering wraps around ──► left edge
```

For alpha textures, this can create a faint coloured border. The chapter uses
`GL_CLAMP_TO_EDGE`. In Sokol that sampler state is:

```zig
sg.makeSampler(.{
    .wrap_u = .CLAMP_TO_EDGE,
    .wrap_v = .CLAMP_TO_EDGE,
});
```

The opaque marble and metal textures use `.REPEAT`, while grass and windows
use `.CLAMP_TO_EDGE`.

## 5. The blending equation

The common equation is:

```text
result = source × source_factor + destination × destination_factor
```

The names mean:

```text
source       = the fragment shader's new colour
destination  = the colour already in the framebuffer
```

For ordinary alpha blending:

```text
source_factor      = source alpha
destination_factor = 1 - source alpha
```

Therefore:

```text
result = source × alpha + destination × (1 - alpha)
```

For a green fragment with alpha `0.6` over a red pixel:

```text
result = green × 0.6 + red × 0.4
```

The new pixel contains 60% green and 40% red.

## 6. `glEnable(GL_BLEND)` in Sokol

OpenGL changes global state:

```cpp
glEnable(GL_BLEND);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
```

Sokol stores the equivalent state in a pipeline:

```zig
pipeline_desc.colors[0].blend = .{
    .enabled = true,
    .src_factor_rgb = .SRC_ALPHA,
    .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
    .op_rgb = .ADD,
    .src_factor_alpha = .SRC_ALPHA,
    .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
    .op_alpha = .ADD,
};
```

The mapping is:

| OpenGL                                                   | Sokol                                                       |
|----------------------------------------------------------|-------------------------------------------------------------|
| `glEnable(GL_BLEND)`                                     | `.colors[0].blend.enabled = true`                           |
| `glDisable(GL_BLEND)`                                    | `.colors[0].blend.enabled = false`                          |
| `GL_SRC_ALPHA`                                           | `.SRC_ALPHA`                                                |
| `GL_ONE_MINUS_SRC_ALPHA`                                 | `.ONE_MINUS_SRC_ALPHA`                                      |
| `glBlendEquation(GL_FUNC_ADD)`                           | `.op_rgb = .ADD`                                            |
| `glBlendFuncSeparate(...)`                               | Set the RGB and alpha factors separately                    |
| `glBlendColor(r, g, b, a)`                               | Set `PipelineDesc.blend_color`                              |

Sokol pipelines are immutable after creation. The scene creates an opaque
pipeline and a blended pipeline once, then selects one with:

```zig
sg.applyPipeline(state.blended_pipeline);
```

## 7. Blend factor names

The chapter's common factors map directly:

| OpenGL                        | Sokol                       |
|-------------------------------|-----------------------------|
| `GL_ZERO`                     | `.ZERO`                     |
| `GL_ONE`                      | `.ONE`                      |
| `GL_SRC_COLOR`                | `.SRC_COLOR`                |
| `GL_ONE_MINUS_SRC_COLOR`      | `.ONE_MINUS_SRC_COLOR`      |
| `GL_DST_COLOR`                | `.DST_COLOR`                |
| `GL_ONE_MINUS_DST_COLOR`      | `.ONE_MINUS_DST_COLOR`      |
| `GL_SRC_ALPHA`                | `.SRC_ALPHA`                |
| `GL_ONE_MINUS_SRC_ALPHA`      | `.ONE_MINUS_SRC_ALPHA`      |
| `GL_DST_ALPHA`                | `.DST_ALPHA`                |
| `GL_ONE_MINUS_DST_ALPHA`      | `.ONE_MINUS_DST_ALPHA`      |
| `GL_CONSTANT_COLOR`           | `.BLEND_COLOR`              |
| `GL_ONE_MINUS_CONSTANT_COLOR` | `.ONE_MINUS_BLEND_COLOR`    |
| `GL_CONSTANT_ALPHA`           | `.BLEND_ALPHA`              |
| `GL_ONE_MINUS_CONSTANT_ALPHA` | `.ONE_MINUS_BLEND_ALPHA`    |

## 8. Blend operations

The factor-weighted source and destination are normally added, but other
operations exist:

| OpenGL                    | Sokol                 | Result                         |
|---------------------------|-----------------------|--------------------------------|
| `GL_FUNC_ADD`             | `.ADD`                | source + destination           |
| `GL_FUNC_SUBTRACT`        | `.SUBTRACT`           | source - destination           |
| `GL_FUNC_REVERSE_SUBTRACT`| `.REVERSE_SUBTRACT`   | destination - source           |
| `GL_MIN`                  | `.MIN`                | smaller component              |
| `GL_MAX`                  | `.MAX`                | larger component               |

Normal transparency uses `.ADD`.

## 9. Why transparent objects need sorting

Blending uses the colour already in the framebuffer, so draw order changes the
calculation:

```text
draw far glass, then near glass  → near blends over far → correct
draw near glass, then far glass  → far may fail depth   → incorrect
```

Depth testing does not understand transparency. A transparent window fragment
can still write an ordinary depth value:

```text
draw near window
      ↓
its depth is stored
      ↓
draw far window
      ↓
far fragment fails LESS depth test, even through transparent glass
```

Press `2` to see the original unsorted order and its missing/incorrect window
layers.

## 10. The standard rendering order

The usual simple approach is:

```text
1. Draw all opaque objects
2. Sort transparent objects from farthest to nearest
3. Draw the transparent objects in that order
```

This scene first draws the two cubes and floor:

```zig
sg.applyPipeline(state.opaque_pipeline);
// draw cubes and floor
```

It then sorts the five window positions by squared distance from the camera:

```zig
const positions = sortBackToFront(transparent_positions);
```

Squared distance is sufficient because squaring preserves the order and avoids
an unnecessary square root:

```zig
const from_camera = Vec3.sub(position, camera_position);
return Vec3.dot(from_camera, from_camera);
```

Finally, it draws the farthest window first:

```zig
sg.applyPipeline(state.blended_pipeline);
sg.applyBindings(state.window_bindings);
drawTransparentObjects(view_projection, &positions);
```

## 11. What Sokol does and does not do

Sokol configures the backend's blending state, but it does not automatically
sort scene objects. Sorting is application/engine work because only the
application understands its objects and camera.

The five-position distance sort works for this lesson, but it is not a complete
solution for intersecting or unusually shaped transparent geometry. More
advanced renderers may use order-independent transparency or specialized
multi-pass techniques.

## 12. Zoomed-out frame flow

```text
begin render pass
      ↓
apply opaque pipeline
      ↓
draw cubes and floor, writing colour + depth
      ↓
choose lesson mode
      ├── 1: discard transparent grass texels
      ├── 2: blend windows in wrong order
      └── 3: sort, then blend far-to-near
      ↓
end pass and commit
```
