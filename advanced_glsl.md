# Advanced GLSL: LearnOpenGL mapped to Sokol + Zig

This is a compact, standalone map of the
[LearnOpenGL Advanced GLSL chapter](https://learnopengl.com/Advanced-OpenGL/Advanced-GLSL)
to this project.

Run the scene:

```bash
zig build run-advanced-glsl
```

WASM:

```bash
zig build run-advanced-glsl -Dtarget=wasm32-emscripten
```

Press `F` to toggle the chapter's `gl_FragCoord` split-screen effect. The
right half becomes grayscale.

## 1. The whole idea

This chapter is a toolbox, not one new rendering technique:

```text
built-in variables   information already supplied by the GPU
interface blocks     labelled parcels sent between shader stages
uniform blocks       related CPU inputs packed into one parcel
```

With Sokol, shader code goes through `sokol-shdc`:

```text
advanced_glsl.glsl
        │
        │ sokol-shdc
        ▼
GLSL + HLSL + Metal + WGSL shader source
        +
Zig structs, binding slots and shader descriptions
```

That generated layer replaces much of the manual OpenGL querying and prevents
the Zig and shader layouts from silently disagreeing.

## 2. Quick OpenGL → Sokol map

| OpenGL / GLSL                         | Sokol + Zig                                               |
|---------------------------------------|-----------------------------------------------------------|
| Compile GLSL directly                 | Compile portable shader source with `sokol-shdc`          |
| `glUseProgram`                        | `sg.applyPipeline()`                                      |
| `gl_Position`                         | Same spelling in shdc source                              |
| `gl_VertexID`                         | `gl_VertexIndex` in shdc's portable source dialect        |
| `gl_FragCoord`                        | Same spelling in shdc source                              |
| `gl_FrontFacing`                      | Same spelling; winding comes from `sg.Pipeline`           |
| `gl_FragDepth`                        | Same basic idea, with portability/performance caveats     |
| GLSL interface block                  | Interface block in the `.glsl` file; shdc translates it   |
| `layout(std140) uniform ...`          | shdc uniform block plus generated Zig parameter struct    |
| `glGetUniformBlockIndex`              | Generated `shd.UB_name` constant                          |
| `glUniformBlockBinding`               | `layout(binding = N)` in the shdc source                  |
| `glBindBufferBase/Range` for a UBO    | Usually no direct call; use `sg.applyUniforms()`          |
| Upload a uniform block                | `sg.applyUniforms(slot, sg.asRange(&params))`             |

## 3. Built-in shader variables

Built-ins are like **automatic fields in the GPU's job description**. You do
not add them to a vertex buffer or uniform block.

### `gl_Position`

The vertex shader must write the vertex's clip-space position:

```glsl
gl_Position = view_projection * model * vec4(position, 1.0);
```

```text
vertex shader ── gl_Position ──► clipping ──► rasterization
```

This is the same concept as ordinary GLSL. `sokol-shdc` translates it to the
appropriate output for each backend.

### `gl_VertexID` → `gl_VertexIndex`

This is the number/index of the vertex currently running through the vertex
shader. It is useful for small generated patterns or for looking up data
without storing an extra ID attribute.

Portable shdc source spells it `gl_VertexIndex`:

```glsl
float marker_id = floor(float(gl_VertexIndex) / 3.0);
```

The five small triangles across the top of the scene derive their colours
from this built-in. The generated desktop GLSL uses `gl_VertexID`; Metal,
HLSL, and WGSL receive their native equivalents.

### `gl_PointSize`

For a point primitive, OpenGL lets a vertex shader choose its square size in
pixels:

```glsl
gl_PointSize = 12.0;
```

Mental model: **one vertex becomes a square stamp instead of a triangle
corner.** Sokol can draw `.POINTS`, and its OpenGL backend enables programmable
point size. However, variable point size is not portable to every shdc target;
WebGPU/WGSL only accepts `1.0`. Cross-platform particle renderers usually draw
small camera-facing quads instead.

### `gl_FragCoord`

This describes the fragment's location in the render target:

```text
gl_FragCoord.x  horizontal pixel coordinate
gl_FragCoord.y  vertical pixel coordinate
gl_FragCoord.z  depth in the 0...1 depth-buffer range
gl_FragCoord.w  perspective-related reciprocal W
```

The scene compares `x` with half the current window width:

```glsl
if (gl_FragCoord.x >= viewport_size.x * 0.5) {
    // right half
}
```

```text
0                    width / 2                    width
├──── normal colour ────┼──── optional grayscale ────┤
```

Backend screen origins can differ, so be careful when effects depend on the
meaning of the vertical `y` direction. This horizontal split avoids that issue.

### `gl_FrontFacing`

Rasterization decides whether a triangle is front-facing from its winding:

```glsl
vec3 result = gl_FrontFacing ? color.rgb : color.rgb * 0.25;
```

```text
triangle winding + pipeline face_winding ──► gl_FrontFacing
pipeline cull_mode                          ──► discard a side or keep it
```

The example uses `.cull_mode = .NONE`, so both sides are allowed to reach the
fragment shader. If back faces were culled, the shader would normally never
see them.

### `gl_FragDepth`

A fragment normally keeps `gl_FragCoord.z`. Writing `gl_FragDepth` overrides
the value stored/tested as depth:

```glsl
gl_FragDepth = gl_FragCoord.z + 0.05;
```

Mental model: **the fragment shader moves its depth ticket after
rasterization.** This can disable early depth testing because the GPU must run
the shader before knowing the final depth. OpenGL's conservative-depth
qualifiers can recover some early testing, but they are not uniformly portable
across every backend generated by shdc. The scene therefore does not write
custom depth merely for demonstration.

## 4. Interface blocks

Individual varyings are separate envelopes:

```text
vertex shader ── position ──► fragment shader
              ── normal   ──►
              ── uv       ──►
```

An interface block puts them into one labelled parcel:

```glsl
out VS_OUT {
    vec3 local_position;
} vs_out;
```

The next stage receives a block with the same block name and member layout:

```glsl
in VS_OUT {
    vec3 local_position;
} vs_out;
```

```text
vertex stage                          fragment stage
VS_OUT parcel ──────────────────────► VS_OUT parcel
└── local_position                    └── local_position
```

Plain GLSL permits different instance names at each stage. For portable shdc
output, use the same name too: some targets flatten a block member into a
varying name, so matching names avoid a WebGL link mismatch. The block name and
member layout must always match. Sokol itself does not configure this
connection; `sokol-shdc` translates it while compiling the shader.

## 5. Uniform blocks and `std140`

Uniforms carry CPU-provided values that remain constant during a draw. A
uniform block groups related values:

```glsl
layout(binding = 0) uniform cube_vs_params {
    mat4 mvp;
};
```

Mental model: **a uniform block is one padded shipping box. Both Zig and the
shader must agree where every item sits inside it.**

`std140` supplies predictable alignment rules. Common rules are:

| Type                  | Useful mental rule                                    |
|-----------------------|-------------------------------------------------------|
| `float`, `int`, bool  | One 4-byte value                                      |
| `vec2`                | Starts on an 8-byte boundary                          |
| `vec3` / `vec4`       | Starts on a 16-byte boundary                          |
| Array element         | Usually receives a 16-byte slot                       |
| `mat4`                | Four 16-byte column vectors: 64 bytes                 |
| Struct/block          | Padded so its final size satisfies required alignment |

Do not manually guess this layout in the project. shdc generates the matching
Zig types, including padding:

```zig
const params = shd.CubeFsParams{
    .color = .{ 1.0, 0.15, 0.12, 1.0 },
    .viewport_size = .{ sapp.widthf(), sapp.heightf() },
    .split_enabled = 0.0,
};
```

The generated struct is the packing contract between Zig and every generated
shader backend.

## 6. OpenGL UBOs versus Sokol uniforms

The chapter creates a persistent OpenGL UBO, attaches it to a binding point,
and lets several programs read it:

```text
OpenGL UBO ── binding point 0 ──► shader A Matrices
                              └─► shader B Matrices
```

Core `sokol_gfx` presents a simpler portable interface:

```zig
sg.applyUniforms(shd.UB_cube_vs_params, sg.asRange(&vertex));
```

Sokol copies those bytes into its internal per-frame uniform upload storage
and binds them for subsequent draws. You do not create or bind a user-visible
uniform-buffer resource.

The closest mappings are:

```text
OpenGL uniform-block binding point  ◄──► generated shd.UB_* slot
OpenGL UBO contents                 ◄──► generated Zig params + applyUniforms
```

This is not identical to a persistent UBO shared automatically across several
OpenGL programs. After changing to a pipeline with required uniforms, apply
the compatible blocks that pipeline needs.

## 7. Group uniforms by update frequency

The four cubes share one camera but have different transforms and colours:

```text
calculated once          combined/uploaded per cube
view_projection          MVP + colour
       │                  │  │  │  │
       └─────────────────►■  ■  ■  ■
```

The scene expresses that directly:

```zig
const view_projection = Mat4.mul(projection, view);

drawCube(view_projection, top_left, red);
drawCube(view_projection, top_right, green);
drawCube(view_projection, bottom_left, blue);
drawCube(view_projection, bottom_right, yellow);
```

Each `drawCube` uploads only its per-draw blocks before `sg.draw()`:

```zig
sg.applyUniforms(shd.UB_cube_vs_params, sg.asRange(&vertex));
sg.applyUniforms(shd.UB_cube_fs_params, sg.asRange(&fragment));
sg.draw(0, cube_indices.len, 1);
```

This update-frequency grouping is the durable lesson behind the chapter's UBO
example, even though Sokol's API is different.

## 8. Final mental model

```text
Zig
├── sg.Pipeline       chooses compiled shaders and fixed GPU rules
├── sg.Bindings       supplies vertex/index/texture resources
└── sg.applyUniforms  sends constant data for upcoming draws
          │
          ▼
shader stages
├── built-ins         GPU-supplied context
├── uniform blocks    CPU-supplied constants
└── interface blocks  stage-to-stage parcels
```

## Quick source map

| Lesson concept                    | Project location                                 |
|-----------------------------------|--------------------------------------------------|
| Built-in variables                | `src/advanced_glsl.glsl`                         |
| Vertex-to-fragment interface      | `VS_OUT`                                         |
| Shared camera calculation         | `view_projection` in `frame()`                   |
| Per-draw uniform blocks           | `cube_vs_params`, `cube_fs_params`, `drawCube()` |
| Explicit uniform binding slots    | `layout(binding = N)`                            |
| Fragment-coordinate comparison    | `split_enabled` branch in `cube_fs`              |
| Generated uniform packing         | `src/generated/advanced_glsl_shader.zig`         |
