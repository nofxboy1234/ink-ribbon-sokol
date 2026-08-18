Implemented the LearnOpenGL Colors scene as a new Sokol-Zig example.

Run it natively:

```bash
zig build run-colors
```

Run it in the browser:

```bash
zig build run-colors -Dtarget=wasm32-emscripten
```

The scene contains:

```text
                     white lamp cube
                             □

                 coral object cube
                       ███
                       ███
```

The static camera is slightly farther back than the tutorial’s initial camera so both objects are visible immediately.

Files added:

- [`colors.zig`](/home/dylan/repos/ink-ribbon-sokol/src/examples/colors.zig)
- [`colors.glsl`](/home/dylan/repos/ink-ribbon-sokol/src/examples/colors.glsl)
- [`colors_shader.zig`](/home/dylan/repos/ink-ribbon-sokol/src/examples/generated/colors_shader.zig)

The build integration is in [`build.zig`](/home/dylan/repos/ink-ribbon-sokol/build.zig:141).

## 1. Representing colors

Computer colors are commonly represented with red, green and blue components:

```zig
const coral = .{
    1.0,  // red
    0.5,  // green
    0.31, // blue
    1.0,  // alpha
};
```

Each RGB component normally ranges from `0.0` to `1.0`:

```text
0.0 = none of that color
1.0 = maximum amount of that color
```

Some examples:

```text
red     = (1, 0, 0)
green   = (0, 1, 0)
blue    = (0, 0, 1)
white   = (1, 1, 1)
black   = (0, 0, 0)
yellow  = (1, 1, 0)
```

The fourth component is alpha:

```text
RGBA
   ↑
opacity
```

The new shader always outputs alpha `1.0`, meaning fully opaque.

## 2. Object color as reflected light

The chapter presents an object’s color as the proportion of each incoming light color it reflects. [LearnOpenGL: Colors](https://learnopengl.com/Lighting/Colors)

The simplified formula is:

```text
visible color = light color × object color
```

This is component-wise multiplication:

```text
result.r = light.r × object.r
result.g = light.g × object.g
result.b = light.b × object.b
```

The shader implements it here:

```glsl
frag_color = vec4(
    light_color.rgb * object_color.rgb,
    1.0
);
```

## 3. White light on the coral cube

The example uploads:

```zig
.object_color = .{ 1.0, 0.5, 0.31, 1.0 },
.light_color = .{ 1.0, 1.0, 1.0, 1.0 },
```

The GPU calculates:

```text
light          object          result

(1, 1, 1)  ×  (1, 0.5, 0.31)  =  (1, 0.5, 0.31)
```

Per component:

```text
red:    1 × 1    = 1
green:  1 × 0.5  = 0.5
blue:   1 × 0.31 = 0.31
```

White contains the full amount of every RGB component, so it preserves the coral color.

## 4. What would green light do?

If you changed the light uniform to:

```zig
.light_color = .{ 0.0, 1.0, 0.0, 1.0 },
```

the result would be:

```text
(0, 1, 0) × (1, 0.5, 0.31)
    =
(0, 0.5, 0)
```

```text
red:    0 × 1    = 0
green:  1 × 0.5  = 0.5
blue:   0 × 0.31 = 0
```

The cube would appear dark green because the incoming light contains no red or blue to reflect.

## 5. This is not directional lighting yet

The large cube has one flat coral color. The shader does not yet consider:

```text
surface normals
light direction
distance from the light
camera direction
diffuse shading
specular highlights
shadows
```

That is why its visible faces have the same color.

The next LearnOpenGL chapter, Basic Lighting, introduces surface normals and starts calculating how directly each surface faces the light.

## 6. Why draw a white lamp cube?

The light’s actual data is just a position:

```zig
const light_position = vec3{
    .x = 1.2,
    .y = 1.0,
    .z = 2.0,
};
```

A position by itself is invisible. The small white cube is a visual marker placed at that position:

```text
light position data
       │
       ▼
small white cube
```

Its model matrix is:

```zig
const lamp_model = mat4.mul(
    mat4.translate(state.light_position),
    uniformScale(0.2),
);
```

With column vectors:

```text
model = translation × scale
```

Applied right to left:

```text
lamp vertex
     │
     ▼ scale to 20%
small cube
     │
     ▼ translate
light position
```

## 7. Why are there two shaders and pipelines?

The object cube uses this calculation:

```glsl
light_color.rgb * object_color.rgb
```

The lamp cube must remain white:

```glsl
frag_color = vec4(1.0);
```

If both used the future lighting shader, the lamp could shade itself and no longer appear like a bright source.

Therefore, the example creates two pipelines:

```zig
state.object_pipeline = makePipeline(
    sg.makeShader(shd.objectShaderDesc(sg.queryBackend())),
    shd.ATTR_object_position,
);

state.lamp_pipeline = makePipeline(
    sg.makeShader(shd.lampShaderDesc(sg.queryBackend())),
    shd.ATTR_lamp_position,
);
```

They share:

```text
vertex buffer
index buffer
vertex layout
depth settings
culling settings
vertex shader logic
```

They differ in their fragment shaders.

## 8. OpenGL → Sokol-Zig mapping

| LearnOpenGL/OpenGL | Sokol-Zig |
|---|---|
| `glGenBuffers` | `sg.makeBuffer()` |
| `glBindBuffer` | Store buffer in `sg.Bindings` |
| VBO | `state.bind.vertex_buffers[0]` |
| EBO | `state.bind.index_buffer` |
| `glVertexAttribPointer` | `pipeline.layout.attrs[...]` |
| VAO | Mostly `sg.Bindings` plus pipeline vertex layout |
| Compile/link shader program | `sokol-shdc` plus `sg.makeShader()` |
| `shader.use()` / `glUseProgram` | `sg.applyPipeline()` |
| Set matrix uniforms | `sg.applyUniforms()` |
| `glDrawArrays` | `sg.draw()` without an index buffer |
| `glDrawElements` | `sg.draw()` with an index buffer |
| GLFW window/events | `sokol_app` |
| `glm::vec3` | `Vec3` |
| `glm::mat4` | `Mat4` |
| `glm::lookAt` | `Mat4.lookat()` |
| `glm::perspective` | `Mat4.persp()` |
| Swap buffers | `sg.endPass()` followed by `sg.commit()` |

## 9. Vertex buffer and VAO mapping

The chapter creates a VBO and separate VAOs for the object and lamp.

This example creates one position-only vertex buffer:

```zig
state.bind.vertex_buffers[0] = sg.makeBuffer(.{
    .data = sg.asRange(&[_]f32{
        // Cube positions...
    }),
});
```

The pipeline describes how those bytes should be read:

```zig
value.attrs[position_attribute].format = .FLOAT3;
```

This corresponds approximately to:

```cpp
glVertexAttribPointer(
    0,
    3,
    GL_FLOAT,
    GL_FALSE,
    3 * sizeof(float),
    (void*)0
);
```

Meaning:

```text
attribute location = shader's position input
components         = 3
component type     = float
stride             = 3 floats
offset             = 0
```

Both objects can reuse the same geometry because both are cubes.

## 10. Separate matrices versus combined MVP

LearnOpenGL sends three matrices:

```glsl
gl_Position =
    projection *
    view *
    model *
    vec4(aPos, 1.0);
```

This project combines them on the CPU:

```zig
const mvp = mat4.mul(
    mat4.mul(projection, view),
    model,
);
```

The shader then uses:

```glsl
gl_Position = mvp * position;
```

These are mathematically equivalent:

```text
mvp × position
=
projection × view × model × position
```

Applied in this order:

```text
local position
      │ Model
      ▼
world position
      │ View
      ▼
camera position
      │ Projection
      ▼
clip position
```

## 11. Drawing the object

The object draw sequence is:

```zig
sg.applyPipeline(state.object_pipeline);
sg.applyBindings(state.bind);
sg.applyUniforms(shd.UB_vs_params, sg.asRange(&object_vs_params));
sg.applyUniforms(
    shd.UB_object_fs_params,
    sg.asRange(&object_fs_params),
);
sg.draw(0, 36, 1);
```

Mental model:

```text
choose object shader and rendering rules
                    │
                    ▼
bind cube geometry
                    │
                    ▼
upload MVP and colors
                    │
                    ▼
draw 36 indexed vertices
```

## 12. Drawing the lamp

The lamp reuses the geometry but changes pipeline and MVP:

```zig
sg.applyPipeline(state.lamp_pipeline);
sg.applyBindings(state.bind);
sg.applyUniforms(shd.UB_vs_params, sg.asRange(&lamp_vs_params));
sg.draw(0, 36, 1);
```

The new MVP places and scales the lamp. Its fragment shader always returns white.

## 13. Whole-frame flow

```text
Build projection and view matrices
                 │
                 ├─────────────────────────┐
                 ▼                         ▼
       object model matrix          lamp model matrix
           identity                translate × scale
                 │                         │
                 ▼                         ▼
          object MVP                   lamp MVP
                 │                         │
                 ▼                         ▼
      apply object pipeline          apply lamp pipeline
      apply cube bindings            reuse cube bindings
      upload MVP + colors            upload lamp MVP
      draw coral cube                draw white cube
                 │                         │
                 └────────────┬────────────┘
                              ▼
                         finish frame
```

Verification completed successfully:

```text
zig build test
zig build -Dtarget=wasm32-emscripten
git diff --check
```

I also loaded the generated WASM page in headless Chrome and confirmed that both the coral object cube and white lamp cube render correctly.
