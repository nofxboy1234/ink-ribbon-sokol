Implemented Basic Lighting as a separate example, leaving `colors.zig` unchanged as the simpler previous lesson.

Run natively:

```bash
zig build run-basic-lighting
```

Run as WASM:

```bash
zig build run-basic-lighting -Dtarget=wasm32-emscripten
```

Added:

- [`basic_lighting.zig`](/home/dylan/repos/ink-ribbon-sokol/src/basic_lighting.zig)
- [`basic_lighting.glsl`](/home/dylan/repos/ink-ribbon-sokol/src/basic_lighting.glsl)
- [`basic_lighting_shader.zig`](/home/dylan/repos/ink-ribbon-sokol/src/generated/basic_lighting_shader.zig)

The example is also registered in `build.zig` and the static ZLS configuration. Go-to-definition for Sokol symbols was verified successfully.

# 1. What this chapter adds

`colors.zig` calculates:

```text
visible color = light color × object color
```

Every fragment on a face receives essentially the same color.

Basic Lighting adds the three parts of the **Phong lighting model**:

```text
final lighting = ambient + diffuse + specular
```

```text
Ambient                    some light everywhere
Diffuse                    brightness from facing the light
Specular                   shiny reflected highlight
```

The LearnOpenGL chapter describes these as inexpensive approximations of real light. [LearnOpenGL: Basic Lighting](https://learnopengl.com/Lighting/Basic-Lighting)

# 2. Ambient lighting

Ambient light prevents unlit surfaces from becoming completely black:

```glsl
float ambient_strength = 0.1;
vec3 ambient = ambient_strength * light_color.rgb;
```

With white light:

```text
ambient = 0.1 × (1, 1, 1)
        = (0.1, 0.1, 0.1)
```

Think of it as a simple approximation of light bouncing around the environment:

```text
             weak background light
          ↘       ↓       ↙

              ┌─────┐
              │ cube│
              └─────┘
```

It is constant and does not care which way a surface faces.

# 3. Surface normals

A normal is a direction perpendicular to a surface:

```text
                   normal
                     ↑
                     │
              ┌──────┼──────┐
              │   surface   │
              └─────────────┘
```

Each cube face has its own normal:

```text
right face    +X
left face     -X
top face      +Y
bottom face   -Y
front face    +Z
back face     -Z
```

The vertex type stores both position and normal:

```zig
const Vertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
};
```

For example:

```zig
.{
    .position = .{ 0.5, 0.5, 0.5 },
    .normal = .{ 0.0, 0.0, 1.0 },
}
```

The position says where the vertex is. The normal says which way its surface faces.

## Why duplicate cube corners?

A geometric cube has eight corner positions, but one corner belongs to three faces:

```text
                  top normal
                      ↑
                     /|
                    / |
       side normal ←  ●──→ front normal
```

One shared vertex could only store one normal. The example therefore duplicates corners so each face can give that position its own normal.

# 4. Vertex layout mapping

LearnOpenGL uses:

```cpp
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
```

The approximate Sokol mapping is:

```zig
desc.layout.buffers[0].stride = @sizeOf(Vertex);

desc.layout.attrs[shd.ATTR_object_position].format = .FLOAT3;
desc.layout.attrs[shd.ATTR_object_normal0].format = .FLOAT3;
```

The buffer is interpreted like this:

```text
vertex 0
┌────────────────────┬────────────────────┐
│ position: 3 floats │ normal: 3 floats   │
└────────────────────┴────────────────────┘

vertex 1
┌────────────────────┬────────────────────┐
│ position: 3 floats │ normal: 3 floats   │
└────────────────────┴────────────────────┘
```

The stride is the distance from one vertex to the next:

```text
6 floats = 24 bytes
```

The lamp ignores normals but uses the same buffer. Its pipeline still needs the `24`-byte stride so it can find each following position correctly.

# 5. World-space fragment position

Lighting needs to know where the surface fragment is relative to the light.

The vertex shader calculates each vertex’s world position:

```glsl
fragment_position = (model * position).xyz;
```

The GPU then interpolates those positions across every triangle:

```text
vertex A position ●
                  |\
                  | \  interpolated positions
                  |  \ for all fragments
                  |   \
vertex B position ●────● vertex C position
```

By the time the fragment shader runs, each fragment receives its own approximate world position.

# 6. Diffuse lighting

Diffuse light asks:

> How directly does this surface face the light?

First, calculate the direction from the fragment to the light:

```glsl
vec3 light_direction =
    normalize(light_position.xyz - fragment_position);
```

```text
light ●
       \
        \ light direction
         \
          ● fragment
```

The surface normal points away from the surface:

```text
              normal
                 ↗
                /
        surface ●
```

The dot product compares these directions:

```glsl
float diffuse_amount = max(
    dot(normal, light_direction),
    0.0
);
```

## Directly facing the light

```text
normal          light direction
   ↗                  ↗

dot ≈ 1
bright
```

## Light arriving sideways

```text
normal ↑

surface ●────────→ light direction

dot = 0
no diffuse light
```

## Light behind the surface

```text
normal ←     → light direction

dot < 0
```

Negative light is not meaningful, so `max` clamps it:

```text
max(negative_value, 0.0) = 0.0
```

Then the diffuse color is:

```glsl
vec3 diffuse = diffuse_amount * light_color.rgb;
```

# 7. Why normalize the vectors?

The useful dot-product interpretation assumes unit vectors:

```text
dot(a, b) = cos(angle)
```

That only works directly when:

```text
length(a) = 1
length(b) = 1
```

Therefore:

```glsl
vec3 normal = normalize(world_normal);
vec3 light_direction = normalize(light_position.xyz - fragment_position);
```

Normalization keeps direction but changes length to `1`.

# 8. Transforming normals

Positions are transformed by the model matrix:

```glsl
model * position
```

Normals are directions, so translation must not affect them. Non-uniform scaling also requires special correction.

The shader uses a **normal matrix**:

```glsl
world_normal =
    mat3(transpose(inverse(model))) * normal0;
```

Conceptually:

```text
normal matrix =
    transpose(
        inverse(
            model's rotation-and-scale part
        )
    )
```

Why is this needed?

Imagine stretching an object only along X:

```text
Before scale               After non-uniform scale

       normal                    incorrect normal
         ↗                              ↗
        /                              /
   ────/────                     ────────────────
```

Transforming a normal like an ordinary direction can stop it being perpendicular to the stretched surface. The inverse-transpose corrects it.

This example’s object model is identity:

```zig
const object_model = mat4.identity();
```

So the normal matrix currently changes nothing. It is included because it is the generally correct method taught by the chapter.

# 9. Specular lighting

Specular lighting creates a shiny highlight.

It depends on:

```text
light direction
surface normal
reflected-light direction
direction towards the camera
```

Diagram:

```text
                       camera
                          ●
                         /
                        / view direction
                       /
              normal  ↑
                     /|
incoming light  ↘   / |   ↗ reflected light
                  \●──|──/
                   surface
```

The shader finds the direction towards the camera:

```glsl
vec3 view_direction =
    normalize(view_position.xyz - fragment_position);
```

It reflects the incoming light around the normal:

```glsl
vec3 reflected_direction =
    reflect(-light_direction, normal);
```

Why negate `light_direction`?

The current vector points:

```text
fragment → light
```

But `reflect()` expects the incoming direction:

```text
light → fragment
```

Therefore:

```text
incoming direction = -light_direction
```

# 10. Calculating the highlight

Compare the view direction with the reflected direction:

```glsl
dot(view_direction, reflected_direction)
```

```text
Directions closely aligned
        ↓
dot near 1
        ↓
bright specular highlight
```

The result is raised to a power:

```glsl
float specular_amount = pow(
    max(dot(view_direction, reflected_direction), 0.0),
    32.0
);
```

The exponent controls shininess:

```text
low exponent                  high exponent

broad soft highlight          small sharp highlight
     █████                          ██
   █████████                        ██
```

This example uses the chapter’s value:

```text
shininess = 32
```

The highlight strength is:

```glsl
float specular_strength = 0.5;

vec3 specular =
    specular_strength *
    specular_amount *
    light_color.rgb;
```

# 11. Combining the three components

The final fragment color is:

```glsl
vec3 result =
    (ambient + diffuse + specular) *
    object_color.rgb;
```

```text
ambient
   +
diffuse
   +
specular
   │
   ▼
total incoming light
   │
   × object reflection color
   ▼
visible fragment color
```

The coral object color remains:

```zig
.object_color = .{ 1.0, 0.5, 0.31, 1.0 },
```

The light remains white:

```zig
.light_color = .{ 1.0, 1.0, 1.0, 1.0 },
```

# 12. Why calculate this in the fragment shader?

The vertex shader runs only once per vertex:

```text
cube: relatively few vertex-shader executions
```

The fragment shader runs across the visible pixels:

```text
cube: potentially thousands of fragment-shader executions
```

Calculating lighting in the fragment shader is more expensive, but creates smooth, accurate highlights across large triangles.

```text
Per-vertex/Gouraud             Per-fragment/Phong

lighting only at corners       lighting at each fragment
then interpolate color         interpolate inputs, then light

less accurate                  smoother result
```

The example uses per-fragment Phong lighting, matching the chapter.

# 13. Uniform mapping

LearnOpenGL uses calls such as:

```cpp
lightingShader.setVec3("objectColor", ...);
lightingShader.setVec3("lightColor", ...);
lightingShader.setVec3("lightPos", ...);
lightingShader.setVec3("viewPos", ...);
```

Sokol-shdc generates a typed Zig struct:

```zig
const object_fs_params = shd.ObjectFsParams{
    .object_color = ...,
    .light_color = ...,
    .light_position = ...,
    .view_position = ...,
};
```

It is uploaded with:

```zig
sg.applyUniforms(
    shd.UB_object_fs_params,
    sg.asRange(&object_fs_params),
);
```

This provides:

- Compile-time field names
- Predictable binary layout
- Correct uniform binding slot
- Cross-backend shader compatibility

# 14. OpenGL → Sokol mapping

| LearnOpenGL/OpenGL | Sokol-Zig |
|---|---|
| VBO | `sg.makeBuffer()` in `vertex_buffers[0]` |
| EBO | Index buffer created with `.index_buffer = true` |
| `glVertexAttribPointer` | `PipelineDesc.layout` |
| VAO | Mostly `sg.Bindings` plus pipeline layout |
| Compile/link shaders | `sokol-shdc` plus `sg.makeShader()` |
| `glUseProgram` | `sg.applyPipeline()` |
| Set uniforms | Typed struct plus `sg.applyUniforms()` |
| Bind VAO/VBO/EBO | `sg.applyBindings()` |
| Enable depth testing | Pipeline `.depth` configuration |
| `glDrawElements` | `sg.draw(0, 36, 1)` |
| GLSL for one OpenGL version | Sokol-shdc source translated for each backend |

# 15. CPU and GPU responsibilities

```text
CPU / Zig
├── creates vertex and index buffers
├── creates pipelines
├── builds model, view and projection matrices
├── stores light and camera positions
├── uploads uniform data
└── submits draw calls

GPU / shaders
├── transforms each vertex
├── interpolates world positions and normals
├── calculates ambient light
├── calculates diffuse light
├── calculates specular light
└── writes final fragment colors
```

# 16. Drawing flow

```zig
sg.applyPipeline(state.object_pipeline);
sg.applyBindings(state.bind);
sg.applyUniforms(shd.UB_object_vs_params, ...);
sg.applyUniforms(shd.UB_object_fs_params, ...);
sg.draw(0, 36, 1);
```

Then the lamp is drawn using the white lamp pipeline:

```zig
sg.applyPipeline(state.lamp_pipeline);
sg.applyBindings(state.bind);
sg.applyUniforms(shd.UB_lamp_vs_params, ...);
sg.draw(0, 36, 1);
```

The lamp does not use the Phong calculation. It remains solid white to mark the light position.

Verification completed:

```text
zig build test
zig build -Dtarget=wasm32-emscripten
git diff --check
```

I also loaded the WASM result in headless Chrome and visually confirmed the coral cube has differently lit faces and the white lamp marker renders correctly.
