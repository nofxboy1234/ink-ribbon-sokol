The chapter explains how a vertex travels from coordinates relative to its own model all the way to a pixel on the screen. The original is [LearnOpenGL — Coordinate Systems](https://learnopengl.com/Getting-started/Coordinate-Systems).

The main flow is:

```text
local space
    ↓ model matrix
world space
    ↓ view matrix
camera/view space
    ↓ projection matrix
clip space
    ↓ perspective division
normalized device coordinates
    ↓ viewport transformation
screen coordinates
```

Your cube example already implements nearly all of this.

## OpenGL-to-Sokol mapping

| LearnOpenGL | This Sokol/Zig project |
|---|---|
| GLM vector/matrix math | [cube_math.zig](/home/dylan/repos/ink-ribbon-sokol/src/cube_math.zig) |
| `glm::mat4` | `Mat4` |
| `glm::rotate` | `Mat4.rotate` |
| `glm::translate` | `Mat4.translate` |
| `glm::perspective` | `Mat4.persp` |
| Camera/view construction | `Mat4.lookat` |
| `projection * view * model` | `Mat4.mul(Mat4.mul(proj, view), model)` |
| Three `mat4` uniforms | One combined `mvp` uniform |
| `glUniformMatrix4fv` | `sg.applyUniforms` |
| `glEnable(GL_DEPTH_TEST)` | Pipeline `.depth.compare` |
| Enable depth writes | Pipeline `.depth.write_enabled` |
| `glClear(GL_DEPTH_BUFFER_BIT)` | Render-pass depth clear |
| `glViewport` | Default pass viewport or `sg.applyViewport` |
| `glDrawArrays` / `glDrawElements` | `sg.draw` |

# 1. What is a coordinate system?

A coordinate system gives numbers a frame of reference.

The position:

```text
(2, 1, 0)
```

does not have a complete meaning by itself. You also need to know:

```text
Two units from which origin?
Along which X axis?
Which direction is positive Y?
```

For example, an object can have its own coordinate axes:

```text
object's local coordinates

             local +Y
                ↑
                │
          ┌─────●─────┐
         /             \
        └───────────────┘
                └────────→ local +X
```

The world has a separate coordinate system:

```text
world +Y
    ↑
    │                         object
    │                       ┌─────┐
    │                       │  ●  │
    │                       └─────┘
    ●────────────────────────────────→ world +X
world origin
```

The object might be centred on its own local origin while that local origin is at world position `(10, 0, 5)`.

# 2. Why use several coordinate spaces?

Different calculations are easier in different spaces.

```text
local space:
    define and modify an object's shape

world space:
    compare different objects' positions

view space:
    reason about positions relative to the camera

clip space:
    decide what is inside the camera's visible region

screen space:
    determine where pixels appear
```

You could construct one enormous direct local-to-screen operation, but keeping the stages conceptually separate makes scenes easier to understand and control.

# 3. The five main spaces

```text
┌─────────────┐
│ Local space │  coordinates relative to the object
└──────┬──────┘
       │ model matrix
       ▼
┌─────────────┐
│ World space │  coordinates relative to the world
└──────┬──────┘
       │ view matrix
       ▼
┌─────────────┐
│ View space  │  coordinates relative to the camera
└──────┬──────┘
       │ projection matrix
       ▼
┌─────────────┐
│ Clip space  │  homogeneous coordinates used for clipping
└──────┬──────┘
       │ perspective division
       ▼
┌─────────────┐
│ NDC         │  small normalized coordinate range
└──────┬──────┘
       │ viewport transformation
       ▼
┌─────────────┐
│ Screen      │  window pixel coordinates
└─────────────┘
```

# 4. Local space

Local space is the coordinate system in which the model’s vertices were originally created.

Your cube’s vertices range from approximately `-1` to `+1`:

```text
                   local +Y
                      ↑
                 +1 ┌───────┐
                   /│      /│
                  └───────┘ │
                  │ │  ●  │ │────→ local +X
                  │ └─────│─┘
                  └───────┘
                     -1  +1

                       ● = local origin (0,0,0)
```

A vertex might be:

```text
local vertex = (1, 1, 1)
```

That means:

> This vertex is one unit along each of the cube’s local axes from the cube’s local origin.

It does not yet tell you where the cube is in the complete game world.

The same cube geometry can be reused for many objects:

```text
one local cube mesh
       ├── model matrix A → cube A in world
       ├── model matrix B → cube B in world
       └── model matrix C → cube C in world
```

# 5. World space

World space is the shared coordinate system in which all objects are placed.

```text
world
  +Y
   ↑
   │      cube A
   │      ┌───┐
   │      └───┘
   │                        cube B
   │                        ┌───┐
   │                        └───┘
   ●────────────────────────────────→ +X
world origin
```

The **model matrix** converts local coordinates into world coordinates:

```text
world_position = model * local_position
```

A model matrix can contain:

```text
scale:
    how large is the object?

rotation:
    which way is it oriented?

translation:
    where is it in the world?
```

Usually:

```text
model = translation * rotation * scale
```

Applied right to left:

```text
local vertex
    ↓ scale
scaled local offset
    ↓ rotate
oriented local offset
    ↓ translate
world position
```

## This project’s model matrix

The cube creates two rotation matrices:

```zig
const rxm = mat4.rotate(rx, .{
    .x = 1.0,
    .y = 0.0,
    .z = 0.0,
});

const rym = mat4.rotate(ry, .{
    .x = 0.0,
    .y = 1.0,
    .z = 0.0,
});
```

It combines them:

```zig
const model = mat4.mul(rxm, rym);
```

See [cube.zig](/home/dylan/repos/ink-ribbon-sokol/src/cube.zig:367).

This model matrix contains rotation but no translation or scale. Therefore:

```text
cube's world origin = world origin
cube rotates around its own centre
```

# 6. View space

View space expresses the world relative to the camera.

Another name for it is:

```text
camera space
eye space
```

Conceptually, the camera sits at the view-space origin:

```text
camera/view space

                +Y
                 ↑
                 │
                 ● camera
                /
              view direction
```

Instead of literally moving the camera through the scene, the view matrix moves the entire world in the opposite direction.

```text
camera moves right
        ≡
world moves left
```

Example:

```text
desired camera position = (0, 0, 5)
```

The equivalent view transformation moves the world by:

```text
(0, 0, -5)
```

Diagram:

```text
Before view transformation:

world origin ●────────────── camera at +5 Z


After view transformation:

camera at origin ●────────── world moved to -5 Z
```

That is why a view matrix can be understood as the inverse of the camera’s world transformation.

## This project’s camera

The cube creates its view matrix with:

```zig
const view = mat4.lookat(
    .{ .x = 0.0, .y = 1.5, .z = 6.0 },
    .{ .x = 0.0, .y = 0.0, .z = 0.0 },
    .{ .x = 0.0, .y = 1.0, .z = 0.0 },
);
```

The arguments mean:

```text
eye:
    camera position = (0, 1.5, 6)

center:
    point being observed = (0, 0, 0)

up:
    world-up direction = (0, 1, 0)
```

Diagram:

```text
                  camera (0,1.5,6)
                         ●
                        /
                       /
                      ↓ looking toward origin

world origin         ● (0,0,0)
                     ↑
                  up = +Y
```

See [Mat4.lookat](/home/dylan/repos/ink-ribbon-sokol/src/cube_math.zig:120).

# 7. View space is not the screen

After the view matrix, the scene is relative to the camera, but it is still 3D:

```text
view-space position = (x, y, z)
```

It has not yet been projected onto the flat screen.

```text
3D view space
      ↓ projection
2D-looking screen result
```

The projection matrix handles that next step.

# 8. Clip space

The vertex shader must output a four-component clip-space position:

```glsl
gl_Position = mvp * position;
```

The result is:

```text
clip_position = (x, y, z, w)
```

These are not yet ordinary normalized 3D coordinates. Before perspective division, the visible clip volume is described relative to `w`.

For X and Y, the visible range is conceptually:

```text
-w ≤ x ≤ w
-w ≤ y ≤ w
```

The depth convention varies between graphics backends, which is important for portable Sokol code.

Anything outside the clip volume is clipped.

```text
camera frustum

              far plane
          ┌───────────────┐
         /                 \
        /                   \
       /                     \
camera ●────── near plane ────┐
       \                     /
        \                   /
         \                 /
          └───────────────┘
```

A triangle can be partially inside. The GPU clips it and constructs the visible portion rather than necessarily throwing away the whole triangle.

```text
clip boundary
        │
        │    /\
        │   /  \
        │──/────\── visible part
        │ /
        │/
```

# 9. Projection matrix

The projection matrix converts from view space to clip space:

```text
clip_position = projection * view_position
```

It also defines the visible region, called the **view frustum**.

Two common projection types are:

```text
orthographic
perspective
```

# 10. Orthographic projection

An orthographic view uses a rectangular visible box:

```text
             far plane
        ┌──────────────┐
        │              │
        │              │
        │              │
        └──────────────┘
        ┌──────────────┐
        │  near plane  │
        └──────────────┘
             camera
```

The sides remain parallel:

```text
near object:    ┌────┐
far object:     ┌────┐

same apparent size
```

Distance from the camera does not make an object appear smaller.

This is useful for:

- 2D rendering
- User interfaces
- CAD and engineering views
- Some strategy-game cameras
- Shadow maps

LearnOpenGL uses:

```cpp
glm::ortho(
    left,
    right,
    bottom,
    top,
    near,
    far
);
```

`cube_math.zig` does not currently have an orthographic helper. An equivalent local function would need to create an appropriate `Mat4`.

Sokol itself does not provide `ortho`; just like OpenGL, it leaves matrix mathematics to your math library.

# 11. Perspective projection

Perspective projection makes distant objects appear smaller:

```text
near cube                 far cube

┌───────────┐               ┌───┐
│           │               │   │
└───────────┘               └───┘
```

The visible region is shaped like a truncated pyramid:

```text
                         far plane
                   ┌─────────────────┐
                  /                   \
                 /                     \
camera ●────────┌──── near plane ───────┐
                 \                     /
                  \                   /
                   └─────────────────┘
```

This shape is called a **perspective frustum**.

Your project constructs one with:

```zig
const proj = mat4.persp(
    60.0,
    aspect,
    0.01,
    10.0,
);
```

The arguments mean:

```text
60.0   = field of view in degrees
aspect = framebuffer width / height
0.01   = near clipping distance
10.0   = far clipping distance
```

See [Mat4.persp](/home/dylan/repos/ink-ribbon-sokol/src/cube_math.zig:108).

# 12. Field of view

Field of view, or FOV, controls how wide the camera sees:

```text
narrow FOV:

camera ●─────<     >─────
          narrow view


wide FOV:

camera ●──<             >──
          wide view
```

A narrower FOV:

```text
objects appear larger
scene looks zoomed in
less of the world is visible
```

A wider FOV:

```text
objects appear smaller
scene looks zoomed out
more of the world is visible
perspective distortion becomes stronger
```

Your cube uses:

```zig
60.0
```

which is a moderately wide field of view.

# 13. Aspect ratio

Aspect ratio is:

```text
width / height
```

Your project calculates:

```zig
const aspect =
    sapp.widthf() / sapp.heightf();
```

For an `800 × 600` window:

```text
aspect = 800 / 600
       ≈ 1.333
```

The projection matrix uses the aspect ratio to compensate for the rectangular window:

```text
without compensation       with compensation

     stretched circle          proper circle
        ______                    ____
      /        \                /      \
     │          │              │        │
      \________/                \______/
```

# 14. Near and far clipping planes

The perspective frustum has two depth limits:

```text
camera
   ●
   │   near                 far
   │    │                    │
   └────│====================│
        visible region
```

Your project uses:

```text
near = 0.01
far  = 10.0
```

Anything closer than the near plane is clipped:

```text
camera ●── object ── near plane
           ↑
        too close
```

Anything beyond the far plane is clipped:

```text
camera ●── near ───────── far ── object
                                ↑
                             too far
```

A very small near value relative to a very large far value can reduce depth-buffer precision. This may cause **z-fighting**, where two nearby surfaces flicker as the GPU struggles to decide which is in front.

# 15. The `w` component and perspective

Perspective projection changes `w` based on depth.

After projection:

```text
clip position = (x, y, z, w)
```

The GPU performs perspective division:

```text
ndc.x = x / w
ndc.y = y / w
ndc.z = z / w
```

Farther positions generally produce a larger positive magnitude for `w`. Dividing by a larger value makes X and Y smaller:

```text
near:
    x = 2
    w = 2
    x/w = 1

far:
    x = 2
    w = 10
    x/w = 0.2
```

Diagram:

```text
same original horizontal amount

near:  2 / 2  = 1.0  ──────────→ appears far from centre
far:   2 / 10 = 0.2  ──→         appears near centre
```

That is how distant geometry appears smaller.

The vertex shader does not manually divide by `w`:

```glsl
gl_Position = mvp * position;
```

The GPU performs perspective division automatically after the vertex shader.

# 16. Normalized device coordinates

After perspective division, the position is in normalized device coordinates, or NDC:

```text
ndc = (clip.x/clip.w, clip.y/clip.w, clip.z/clip.w)
```

For OpenGL, visible X and Y are in:

```text
-1 to +1
```

```text
NDC

                +Y
                 ↑ +1
                 │
        -1 ──────●────── +1 → +X
                 │
                 ↓ -1
```

For example:

```text
(-1, -1) = lower-left edge
( 0,  0) = centre
( 1,  1) = upper-right edge
```

A portability caveat: graphics APIs differ in their NDC depth conventions. LearnOpenGL describes OpenGL’s convention. Sokol can target OpenGL, Metal, D3D11, WebGPU, and other backends, so portable projection math and generated shaders must use conventions compatible with the selected backend.

This project’s current Linux and WASM paths use OpenGL/GLES/WebGL-style rendering, and its local `Mat4.persp` is written for that style.

# 17. Viewport transformation

NDC still does not contain pixel positions. The viewport transformation maps NDC to the render target.

For an `800 × 600` window:

```text
NDC (-1,+1)                    screen (0,0)
       ┌──────────┐                ┌──────────┐
       │          │                │          │
       │          │       →        │  pixels  │
       │          │                │          │
       └──────────┘                └──────────┘
   (-1,-1)                    approximately 800×600
```

A simplified X conversion is:

```text
screen_x = (ndc_x + 1) * 0.5 * width
```

For the centre:

```text
ndc_x = 0

screen_x = (0 + 1) * 0.5 * 800
         = 400
```

Raw OpenGL configures this with:

```cpp
glViewport(0, 0, width, height);
```

With a normal Sokol swapchain pass, the full render-target viewport is used automatically. To set a custom viewport:

```zig
sg.applyViewport(
    x,
    y,
    width,
    height,
    origin_top_left,
);
```

Most simple Sokol programs do not need to call it explicitly.

# 18. Putting model, view, and projection together

The complete equation is:

```text
clip_position =
    projection *
    view *
    model *
    local_position
```

Shortened:

```text
clip = P * V * M * local
```

Because this project uses column vectors, read it right to left:

```text
local position
      ↓ model
world position
      ↓ view
camera/view position
      ↓ projection
clip position
```

Diagram:

```text
local
  │
  │ M
  ▼
world
  │
  │ V
  ▼
view
  │
  │ P
  ▼
clip
```

# 19. Three uniforms versus one MVP uniform

LearnOpenGL sends three separate matrices:

```glsl
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

gl_Position =
    projection *
    view *
    model *
    vec4(aPos, 1.0);
```

Your project combines them on the CPU:

```zig
const mvp = mat4.mul(
    mat4.mul(proj, state.view),
    model,
);
```

It uploads one matrix:

```zig
return shd.VsParams{
    .mvp = mvp,
};
```

The shader uses:

```glsl
layout(binding = 0) uniform vs_params {
    mat4 mvp;
};

void main() {
    gl_Position = mvp * position;
}
```

See [cube.glsl](/home/dylan/repos/ink-ribbon-sokol/src/cube.glsl:4).

Both approaches perform the same mathematical transformation:

```text
separate in shader:
    P * V * M * position

combined on CPU:
    MVP * position
```

The combined version saves the vertex shader from multiplying the three matrices for every vertex.

You may still keep them separate when the shader needs world-space or view-space positions for lighting.

# 20. Uploading MVP with Sokol

LearnOpenGL:

```cpp
glUniformMatrix4fv(
    model_location,
    1,
    GL_FALSE,
    glm::value_ptr(model)
);
```

Sokol:

```zig
const vs_params = computeVsParams(
    state.rx,
    state.ry,
);

sg.applyUniforms(
    shd.UB_vs_params,
    sg.asRange(&vs_params),
);
```

Mapping:

```text
glGetUniformLocation
    → generated shd.UB_vs_params

glUniformMatrix4fv
    → sg.applyUniforms

glm::value_ptr
    → sg.asRange

GLM matrix
    → local Mat4
```

Sokol-shdc generates `shd.VsParams` and `shd.UB_vs_params` from the shader.

# 21. Right-handed coordinates

This project uses a right-handed, Y-up convention:

```text
             +Y
              ↑
              │
              │
              ●──────→ +X
             /
           +Z
```

A useful right-hand relationship is:

```text
X × Y = Z
```

The camera is on positive Z and looks toward the origin:

```text
origin ●────────────── camera at +Z
        camera looks ←
```

Objects in front of the camera therefore lie generally toward negative camera-space Z.

Sokol itself does not force your game-world axes to use one particular convention. Your math library, projection matrices, shaders, and assets must agree.

# 22. Going from a plane to a cube

The chapter first rotates a flat textured rectangle so it appears to lie in 3D:

```text
before:

┌──────────┐
│ rectangle│
└──────────┘


after X rotation:

     __________
   /          /
  /__________/
```

The model matrix performs the tilt. The view matrix places it relative to the camera. The projection matrix creates perspective.

Your project directly uses a cube containing:

```text
6 faces
2 triangles per face
3 indices per triangle

6 × 2 × 3 = 36 indices
```

It draws them with:

```zig
sg.draw(0, 36, 1);
```

# 23. Why depth testing is necessary

Without depth testing, whichever fragment is processed later may overwrite an earlier one, even when it belongs to a surface farther from the camera.

```text
camera → front face → back face

Correct:
    front face visible
    back face hidden

Without depth test:
    later back-face fragment might overwrite front face
```

A depth buffer stores the nearest depth written at each pixel:

```text
screen pixel
├── colour: current visible colour
└── depth: nearest recorded distance
```

When a new fragment arrives:

```text
new fragment closer?
    yes → write colour and new depth
    no  → discard fragment
```

# 24. OpenGL depth mapping

LearnOpenGL enables depth testing with:

```cpp
glEnable(GL_DEPTH_TEST);
```

It clears colour and depth every frame:

```cpp
glClear(
    GL_COLOR_BUFFER_BIT |
    GL_DEPTH_BUFFER_BIT
);
```

Sokol puts depth-test rules into the pipeline:

```zig
.depth = .{
    .compare = .LESS_EQUAL,
    .write_enabled = true,
},
```

See [cube.zig](/home/dylan/repos/ink-ribbon-sokol/src/cube.zig:214).

This means:

```text
.compare = .LESS_EQUAL
    accept a fragment if its depth is nearer or equal

.write_enabled = true
    store the accepted fragment's depth
```

Sokol’s default render-pass action clears depth to `1.0`, representing the far end of the depth range:

```text
start of frame:
    every depth value = farthest possible

drawing:
    nearer fragments replace it
```

The cube explicitly sets its colour clear, while the depth action remains at Sokol’s default clear behaviour:

```zig
state.pass_action.colors[0] = .{
    .load_action = .CLEAR,
    .clear_value = .{
        .r = 0.25,
        .g = 0.5,
        .b = 0.75,
        .a = 1.0,
    },
};
```

# 25. Drawing multiple cubes

The chapter draws the same cube geometry many times with a different model matrix.

The shared state is:

```text
vertex buffer
index buffer
shader
pipeline
view matrix
projection matrix
```

Each cube has its own:

```text
position
rotation
scale
model matrix
```

Conceptually:

```zig
const cube_positions = [_]vec3{
    .{ .x = -2.0, .y = 0.0, .z = 0.0 },
    .{ .x = 2.0, .y = 0.0, .z = 0.0 },
};

const projection_view =
    mat4.mul(projection, view);

for (cube_positions, 0..) |position, index| {
    const translation =
        mat4.translate(position);

    const rotation = mat4.rotate(
        @floatFromInt(index * 20),
        .{ .x = 1.0, .y = 0.3, .z = 0.5 },
    );

    const model =
        mat4.mul(translation, rotation);

    const params = shd.VsParams{
        .mvp = mat4.mul(
            projection_view,
            model,
        ),
    };

    sg.applyUniforms(
        shd.UB_vs_params,
        sg.asRange(&params),
    );

    sg.draw(0, 36, 1);
}
```

The sequence is:

```text
upload cube A's MVP
    ↓
draw shared cube mesh

upload cube B's MVP
    ↓
draw shared cube mesh again
```

Calling `sg.draw` twice with the same geometry and unchanged MVP would draw both copies in exactly the same position.

For many objects, instanced rendering can provide model transformations per instance and reduce the number of draw calls.

# 26. What Sokol does and does not do

Sokol handles:

```text
creating GPU resources
configuring the graphics pipeline
binding buffers and textures
uploading uniforms
starting render passes
issuing draw commands
normalizing differences between graphics APIs
```

Your math code handles:

```text
model matrices
view matrices
projection matrices
matrix multiplication
vector operations
coordinate-space conversions
```

The division is:

```text
cube_math.zig
    calculates MVP
        ↓
sg.applyUniforms
    uploads MVP
        ↓
vertex shader
    calculates clip position
        ↓
GPU
    clips, divides by w, maps to viewport,
    rasterizes and depth-tests
```

# Complete flow through `cube.zig`

Initialization:

```text
create local-space cube vertices
    ↓
create vertex and index buffers
    ↓
create shader and pipeline
    ↓
configure depth testing
    ↓
create fixed view matrix
```

Each frame:

```text
update rotation angles
    ↓
create model matrix
    ↓
create projection matrix
    ↓
calculate MVP = P * V * M
    ↓
begin render pass
    ↓
apply pipeline
    ↓
apply bindings
    ↓
upload MVP
    ↓
draw cube
    ↓
GPU transforms and rasterizes
    ↓
end and commit pass
```

The shortest mental model is:

```text
model:
    puts an object into the world

view:
    expresses the world from the camera's perspective

projection:
    converts the camera's 3D view into clip coordinates

perspective division:
    makes distant objects appear smaller

viewport:
    maps normalized coordinates to window pixels

depth test:
    keeps nearer surfaces in front
```

And the central formula is:

```text
clip_position =
    projection *
    view *
    model *
    local_position
```
