# Depth testing: LearnOpenGL mapped to Sokol + Zig

Run the example:

```bash
zig build run-depth-testing
```

WASM:

```bash
zig build run-depth-testing -Dtarget=wasm32-emscripten
```

Controls:

| Key | Result                                                   |
|-----|----------------------------------------------------------|
| `Z` | Toggle normal colour and linearized depth visualization  |
| `D` | Toggle the `LESS` and `ALWAYS` depth comparisons         |

## 1. Why a depth buffer is needed

After projection, several triangles can cover the same screen pixel:

```text
camera                       screen pixel
  ● ─── near cube ──────────────┐
   ╲                             ▼
    └────── far floor ──────── [ x ]
```

The GPU must decide which fragment is closest. It stores one depth value for
every framebuffer pixel:

```text
colour buffer                 depth buffer
┌──────────────┐              ┌──────────────┐
│ RGB colour   │              │ distance-like│
│ for pixel    │              │ value        │
└──────────────┘              └──────────────┘
```

The depth buffer is also called the **z-buffer**.

For each candidate fragment, the GPU approximately does this:

```text
new fragment depth
        │
        ▼
compare with stored depth
   │             │
 passes         fails
   │             │
   ▼             ▼
write colour    discard fragment
and new depth
```

## 2. Enabling depth testing

OpenGL uses global mutable state:

```cpp
glEnable(GL_DEPTH_TEST);
glDepthFunc(GL_LESS);
```

Sokol places the same information in immutable pipeline state:

```zig
const pipeline = sg.makePipeline(.{
    .depth = .{
        .compare = .LESS,
        .write_enabled = true,
    },
});
```

This says:

- Test a fragment against the stored depth.
- Pass when the new depth is less—closer to the camera.
- When it passes, write the new depth into the depth buffer.

The important mapping is:

```text
OpenGL global state          Sokol pipeline state
glEnable(GL_DEPTH_TEST)  →   .depth.compare is not ALWAYS
glDepthFunc(GL_LESS)     →   .depth.compare = .LESS
glDepthMask(GL_TRUE)     →   .depth.write_enabled = true
```

To test depth without changing it:

```cpp
glDepthMask(GL_FALSE);
```

maps to:

```zig
.depth = .{
    .compare = .LESS,
    .write_enabled = false,
}
```

That is useful for some transparent and multi-pass techniques.

## 3. Clearing depth every frame

OpenGL:

```cpp
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
```

Sokol:

```zig
state.pass_action.colors[0] = .{
    .load_action = .CLEAR,
    .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
};

state.pass_action.depth = .{
    .load_action = .CLEAR,
    .clear_value = 1.0,
};
```

Depth `1.0` represents the far end of the ordinary depth range. Clearing makes
the first visible fragment at each pixel able to pass.

Without a clear, this frame would inherit stale depths from the previous frame.

## 4. Depth comparison functions

| OpenGL        | Sokol            | Passes when new depth is...   |
|---------------|------------------|-------------------------------|
| `GL_NEVER`    | `.NEVER`         | never accepted                |
| `GL_LESS`     | `.LESS`          | less than stored depth        |
| `GL_EQUAL`    | `.EQUAL`         | equal to stored depth         |
| `GL_LEQUAL`   | `.LESS_EQUAL`    | less than or equal            |
| `GL_GREATER`  | `.GREATER`       | greater than stored depth     |
| `GL_NOTEQUAL` | `.NOT_EQUAL`     | different from stored depth   |
| `GL_GEQUAL`   | `.GREATER_EQUAL` | greater than or equal         |
| `GL_ALWAYS`   | `.ALWAYS`        | always accepted               |

Sokol pipelines are immutable after creation. The example therefore creates:

```zig
state.depth_pipeline  // .compare = .LESS
state.always_pipeline // .compare = .ALWAYS
```

Pressing `D` chooses which pipeline is applied:

```zig
sg.applyPipeline(
    if (state.depth_always)
        state.always_pipeline
    else
        state.depth_pipeline,
);
```

The scene draws both cubes first and the floor last:

```text
draw cube A
draw cube B
draw floor
```

With `LESS`, floor fragments behind the cubes fail:

```text
cube depth:  0.4  stored
floor depth: 0.7  0.7 < 0.4 is false → discard floor fragment
```

With `ALWAYS`, the floor passes regardless and overwrites the cubes where their
screen areas overlap. This demonstrates why draw order alone is not enough for
normal 3D opaque rendering.

## 5. Where the depth value comes from

The vertex shader writes clip-space position:

```glsl
gl_Position = mvp * vec4(position, 1.0);
```

The GPU then performs the perspective divide:

```text
clip position       normalized device coordinates
(x, y, z, w)   →    (x/w, y/w, z/w)
```

It converts the resulting z coordinate into the depth-buffer range. In the
fragment shader, that value is available as:

```glsl
gl_FragCoord.z
```

For the usual depth convention:

```text
near plane                               far plane
depth 0.0  ├─────────────────────────────┤ depth 1.0
```

## 6. Why perspective depth is non-linear

Perspective gives much more depth precision near the camera than far away:

```text
near                                               far
│ lots of precise depth steps │ fewer useful steps │
```

So a raw depth value of `0.5` does **not** mean halfway between the near and far
planes in world or view space.

This is useful: nearby surfaces are where small depth differences are most
noticeable. The cost is reduced precision far from the camera.

## 7. Visualizing depth with `Z`

The fragment shader can output depth as a grayscale colour:

```glsl
frag_color = vec4(vec3(gl_FragCoord.z), 1.0);
```

Raw perspective depth usually looks almost entirely white because values
quickly approach `1.0`. The example therefore converts it back to linear view
depth:

```glsl
float ndc_z = depth * 2.0 - 1.0;

float linear_depth =
    (2.0 * near_plane * far_plane)
    / (far_plane + near_plane - ndc_z * (far_plane - near_plane));
```

It divides by the far distance to create a displayable 0..1 value:

```glsl
float visible_depth = linear_depth / far_plane;
frag_color = vec4(vec3(visible_depth), 1.0);
```

The result is:

```text
dark grey  → closer
light grey → farther away
```

This does not replace the GPU's depth test. It only shows the fragment's depth
as colour so that we can inspect it.

## 8. Early depth testing

GPUs can often reject hidden fragments before running their fragment shader:

```text
triangle fragment
       ↓
early depth test ── fails ──► skip fragment shader
       │
      passes
       ▼
fragment shader
```

This can save considerable work. It is easiest for the GPU when the fragment
shader does not manually write a replacement depth value.

The example reads `gl_FragCoord.z` for visualization but does not write depth,
so it does not introduce a custom fragment depth.

## 9. Z-fighting

Z-fighting happens when two surfaces have nearly identical depth values:

```text
surface A ──────────────────
surface B ──────────────────  almost the same position
```

Small precision and rounding differences make different pixels choose
different surfaces, producing a flickering or speckled pattern.

Common fixes are:

1. Do not place surfaces at exactly or almost the same position.
2. Move the projection near plane farther from the camera when possible.
3. Use a higher-precision depth format when necessary.

The first fix is usually the simplest. For example, place a cube slightly above
a floor instead of making its bottom face exactly coplanar with the floor.

## 10. Complete OpenGL → Sokol mapping

| LearnOpenGL/OpenGL           | Sokol + Zig                                               |
|------------------------------|-----------------------------------------------------------|
| `glEnable(GL_DEPTH_TEST)`    | Configure depth testing in `sg.PipelineDesc.depth`        |
| `glDepthFunc(...)`           | `.depth.compare`                                          |
| `glDepthMask(...)`           | `.depth.write_enabled`                                    |
| Clear `GL_DEPTH_BUFFER_BIT`  | `sg.PassAction.depth.load_action = .CLEAR`                |
| Depth clear value            | `sg.PassAction.depth.clear_value`                         |
| Change depth function        | Apply a different pre-created `sg.Pipeline`               |
| `gl_FragCoord.z`             | The same GLSL built-in in the Sokol shader source         |
| Draw cubes and plane         | `sg.applyBindings`, `sg.applyUniforms`, `sg.draw`         |

The important mental model is:

```text
Pass action       says how the depth buffer starts this pass
Pipeline          says how each fragment is compared and whether it writes
Projection matrix determines how view-space distance maps to depth
Fragment shader   can read gl_FragCoord.z to visualize that result
```
