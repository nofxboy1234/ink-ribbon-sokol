# Cubemaps: LearnOpenGL mapped to Sokol + Zig

This is a compact, standalone mapping of the
[LearnOpenGL Cubemaps chapter](https://learnopengl.com/Advanced-OpenGL/Cubemaps)
to this project.

Run the example:

```bash
zig build run-cubemaps
```

WASM:

```bash
zig build run-cubemaps -Dtarget=wasm32-emscripten
```

Controls:

| Key     | Object material                |
|---------|--------------------------------|
| `1`     | Ordinary solid material        |
| `2`     | Reflect the cubemap            |
| `3`     | Refract the cubemap like glass |
| `Space` | Pause or resume rotation       |

## 1. The main idea

A 2D texture is sampled with a position on a flat image:

```text
vec2 UV ──► 2D texture ──► colour
```

A cubemap is sampled with a direction:

```text
vec3 direction ──► six-sided cubemap ──► colour
```

Imagine standing inside a cube and pointing:

```text
point right ──► sample +X face
point up    ──► sample +Y face
point back  ──► sample one Z face
```

The GPU looks at the direction's strongest axis to choose a face, then uses
the other two components to find a pixel on it. The direction's length is
unimportant:

```text
(1, 0, 0) and (20, 0, 0) both point at +X
```

## 2. Six images become one image

OpenGL uploads the faces with six `glTexImage2D` calls. Current Sokol expects
all six faces packed into one mip-level range:

```text
┌────┬────┬────┬────┬────┬────┐
│ +X │ -X │ +Y │ -Y │ +Z │ -Z │
└────┴────┴────┴────┴────┴────┘
```

```zig
var data: sg.ImageData = .{};
data.mip_levels[0] = sg.asRange(packed_pixels);

const image = sg.makeImage(.{
    .type = .CUBE,
    .width = face_width,
    .height = face_height,
    .pixel_format = .RGBA8,
    .data = data,
});
```

The exact Sokol order and chapter filenames are:

| Packed index | Cubemap face | File         |
|-------------:|--------------|--------------|
| `0`          | `+X`         | `right.jpg`  |
| `1`          | `-X`         | `left.jpg`   |
| `2`          | `+Y`         | `top.jpg`    |
| `3`          | `-Y`         | `bottom.jpg` |
| `4`          | `+Z`         | `front.jpg`  |
| `5`          | `-Z`         | `back.jpg`   |

All faces must have the same dimensions and format.
The `front` and `back` filenames are asset labels; the packed `+Z/-Z`
positions are the actual GPU convention.

## 3. Image, view, and sampler

Sokol separates the storage from how it is accessed:

```text
sg.Image    = the six stored pictures
sg.View     = lets a shader see them as a texture
sg.Sampler  = filtering and edge behaviour
```

```zig
const view = sg.makeView(.{
    .texture = .{ .image = image },
});

const sampler = sg.makeSampler(.{
    .min_filter = .LINEAR,
    .mag_filter = .LINEAR,
    .wrap_u = .CLAMP_TO_EDGE,
    .wrap_v = .CLAMP_TO_EDGE,
    .wrap_w = .CLAMP_TO_EDGE,
});
```

Clamping helps hide seams between faces. `wrap_w` is the third texture axis.

## 4. OpenGL → Sokol

| OpenGL                              | Sokol + Zig                                  |
|-------------------------------------|----------------------------------------------|
| `glGenTextures`                     | `sg.makeImage`                               |
| `GL_TEXTURE_CUBE_MAP`               | `sg.ImageDesc.type = .CUBE`                  |
| Six `glTexImage2D` calls            | Six packed surfaces in `mip_levels[0]`       |
| `glTexParameteri`                   | `sg.makeSampler`                             |
| `glBindTexture`                     | Put an `sg.View` in `sg.Bindings.views`      |
| Sampler integer / texture unit      | Generated view and sampler binding slots     |
| `glDepthFunc(GL_LEQUAL)`            | `.depth.compare = .LESS_EQUAL`               |
| `glDepthMask(GL_FALSE)`             | `.depth.write_enabled = false`               |
| Changing global render state        | Choose an immutable `sg.Pipeline`            |
| `glDrawArrays(..., 36)`             | `sg.draw(0, 36, 1)`                          |

## 5. Shader mapping

The chapter uses one combined OpenGL `samplerCube`. Sokol shaders declare the
texture and sampler separately:

```glsl
layout(binding=0) uniform textureCube environment_tex;
layout(binding=0) uniform sampler environment_smp;

vec3 colour = texture(
    samplerCube(environment_tex, environment_smp),
    direction
).rgb;
```

Zig binds both generated slots:

```zig
bindings.views[shd.VIEW_environment_tex] = cubemap_view;
bindings.samplers[shd.SMP_environment_smp] = cubemap_sampler;
```

## 6. The skybox

A skybox is a cube around the camera:

```text
┌─────────────────────────────┐
│ mountains and sky           │
│           ● camera          │
│                             │
└─────────────────────────────┘
```

You see the cube from inside. Its vertex positions already point from the
centre toward its faces, so they double as sampling directions:

```glsl
sample_direction = position;
```

No 2D UV coordinates are needed.

Those directions are interpolated across each triangle before the fragment
shader samples the cubemap. Because the camera is inside the cube, the example
keeps culling disabled:

```zig
.cull_mode = .NONE,
```

## 7. Remove camera translation

The skybox should turn when the camera turns, but it must not get closer when
the camera moves:

```text
camera rotation     keep
camera translation  remove
```

```zig
var skybox_view = view;
skybox_view.m[3][0] = 0;
skybox_view.m[3][1] = 0;
skybox_view.m[3][2] = 0;
```

Column `3` contains translation with this project's matrix convention.
Removing it makes the environment appear infinitely far away while preserving
camera rotation.

## 8. Draw the skybox last

The chapter first presents a valid simple approach:

```text
draw skybox first with depth writes disabled
                  ↓
draw scene objects over it
```

The final, more efficient approach used here is:

```text
draw object first ──► object writes depth
draw skybox last  ──► only uncovered background pixels pass
```

The skybox shader forces its depth to the far plane:

```glsl
vec4 pos = view_projection * vec4(position, 1.0);
gl_Position = pos.xyww;
```

After perspective division:

```text
depth = z / w = w / w = 1
```

Its pipeline therefore uses:

```zig
.depth = .{
    .compare = .LESS_EQUAL,
    .write_enabled = false,
},
```

`LESS_EQUAL` allows skybox depth `1` to pass against cleared depth `1`.
Disabling writes prevents the background from changing the useful depth buffer.

## 9. Reflection

A reflected viewing ray becomes the cubemap direction:

```text
camera ray ──► surface normal ──► bounced direction ──► cubemap
```

```glsl
vec3 I = normalize(world_position - camera_position);
vec3 R = reflect(I, normalize(world_normal));
vec3 colour = texture(
    samplerCube(environment_tex, environment_smp),
    R
).rgb;
```

Press `2`. The cube looks mirror-like because each fragment shows the part of
the environment found in its reflected direction.

The calculation only works when these are all in the same coordinate space:

```text
world_position
world_normal
camera_position
      └──────── all world space
```

The example only rotates the cube, so `mat3(model)` correctly transforms its
normals. Non-uniform scaling would require an inverse-transpose normal matrix.
Real materials commonly mix this cubemap colour with a base material; a
reflection map can control the mixture per fragment.

## 10. Refraction

Refraction bends the ray through a material:

```text
camera ray ──► glass surface ──► bent direction ──► cubemap
```

```glsl
float ratio = 1.0 / 1.52; // air into glass
vec3 R = refract(I, normalize(world_normal), ratio);
```

The ratio is the refractive index being left divided by the one being entered:

```text
air → water: 1.00 / 1.33
air → glass: 1.00 / 1.52
```

Press `3`. This is the chapter's simple, single-surface approximation; fully
physical glass would also model the ray leaving the other side.

## 11. Dynamic environment maps

The example uses a static cubemap. It contains the landscape but not nearby
moving objects.

A dynamic cubemap renders the scene six times:

```text
render +X, -X, +Y, -Y, +Z, -Z
                  ↓
          render-target cubemap
                  ↓
             reflective object
```

In Sokol, each pass would use a color-attachment view selecting one cubemap
`.slice`. This is expensive—six scene renders per update—so the chapter only
introduces the idea and this learning scene keeps the static version.

## 12. Whole frame at a glance

```text
load six JPEGs into one .CUBE image
                  ↓
draw rotating cube with ordinary / reflect / refract shader
                  ↓
draw skybox last at far depth
                  ↓
sg.endPass()
                  ↓
sg.commit()
```

The central mental model is simply:

```text
Cubemap = ask "what colour lies in this direction?"
```

## Quick source map

| Concept                         | Project location          |
|---------------------------------|---------------------------|
| Decode and pack six faces       | `makeCubemap()`           |
| Create image, view, and sampler | `init()`                  |
| Object and skybox pipelines     | `init()`                  |
| Remove view translation         | `frame()`                 |
| Draw object, then skybox        | `frame()`                 |
| Reflection and refraction       | `object_fs` in the GLSL   |
| Far-depth `xyww` trick          | `skybox_vs` in the GLSL   |

The implementation is in
[`src/cubemaps.zig`](src/cubemaps.zig) and
[`src/cubemaps.glsl`](src/cubemaps.glsl).
