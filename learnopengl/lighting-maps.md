Implemented the LearnOpenGL Lighting Maps scene as a separate example.

Run natively:

```bash
zig build run-lighting-maps
```

Run as WASM:

```bash
zig build run-lighting-maps -Dtarget=wasm32-emscripten
```

Added:

- [`lighting_maps.zig`](/home/dylan/repos/ink-ribbon-sokol/src/examples/lighting_maps.zig)
- [`lighting_maps.glsl`](/home/dylan/repos/ink-ribbon-sokol/src/examples/lighting_maps.glsl)
- [`lighting_maps_shader.zig`](/home/dylan/repos/ink-ribbon-sokol/src/examples/generated/lighting_maps_shader.zig)
- Exact LearnOpenGL texture assets under [`src/examples/assets/lighting_maps`](/home/dylan/repos/ink-ribbon-sokol/src/examples/assets/lighting_maps)

The camera was statically matched against the chapter’s [specular-map reference image](https://learnopengl.com/img/lighting/materials_specular_map.png).

# 1. What problem do lighting maps solve?

In `materials.zig`, one material applies to the whole cube:

```text
Entire cube
├── one ambient color
├── one diffuse color
├── one specular color
└── one shininess
```

That works for a simple object made from one material.

The wooden container contains different materials:

```text
Container
├── wooden boards
├── steel frame
├── dark cracks
└── metal screws/details
```

The wood and steel should not have the same reflection properties.

Lighting maps use textures to give each fragment different material values. [LearnOpenGL: Lighting maps](https://learnopengl.com/Lighting/Lighting-maps)

# 2. A lighting map is a texture

A texture stores a value at every texel:

```text
Texture image

┌─────────────────────────┐
│ texel texel texel texel │
│ texel texel texel texel │
│ texel texel texel texel │
└─────────────────────────┘
```

UV coordinates tell the shader which texel belongs to a fragment:

```text
mesh fragment
      │
      │ interpolated UV
      ▼
texture location
      │
      ▼
sampled material value
```

The example uses two maps:

```text
Diffuse map                Specular map

visible body colors        reflection strength
wood and steel image       mostly black and gray
```

# 3. Diffuse map

The diffuse map is the familiar wooden-container image:

```text
┌───────────────────────────┐
│ metal frame               │
│ ┌───────────────────────┐ │
│ │ wooden boards         │ │
│ │                       │ │
│ └───────────────────────┘ │
└───────────────────────────┘
```

Instead of one diffuse color:

```zig
.material_diffuse = .{ 1.0, 0.5, 0.31, 1.0 }
```

the shader samples the image:

```glsl
vec3 diffuse_sample = texture(
    sampler2D(diffuse_texture, texture_sampler),
    uv
).rgb;
```

Every fragment can receive a different color:

```text
wood fragment  → brown sample
metal fragment → gray sample
crack fragment → dark sample
```

# 4. Ambient also uses the diffuse map

The chapter treats ambient and diffuse surface colors as the same:

```glsl
vec3 ambient =
    light_ambient.rgb *
    diffuse_sample;
```

This keeps shadowed regions recognizable:

```text
wood remains dark brown
metal remains dark gray
```

Without it, the ambient term would be one flat color across the entire object.

# 5. Diffuse lighting with the map

The directional diffuse amount is still calculated from the normal and light direction:

```glsl
float diffuse_amount = max(
    dot(normal, light_direction),
    0.0
);
```

Then it is combined with the sampled body color:

```glsl
vec3 diffuse =
    light_diffuse.rgb *
    diffuse_amount *
    diffuse_sample;
```

Conceptually:

```text
How directly does
the surface face light?
          │
          ▼
    diffuse amount
          │
          ×
light diffuse intensity
          │
          ×
texture body color
          │
          ▼
 final diffuse color
```

# 6. Specular map

The specular map controls which parts may have shiny highlights.

It is mostly grayscale:

```text
black      no specular reflection
dark gray  weak reflection
light gray stronger reflection
white      full reflection
```

The wooden areas are mostly black:

```text
wood → no obvious shiny highlight
```

The steel frame is brighter:

```text
steel → visible highlight
```

The shader samples it:

```glsl
vec3 specular_sample = texture(
    sampler2D(specular_texture, texture_sampler),
    uv
).rgb;
```

Then:

```glsl
vec3 specular =
    light_specular.rgb *
    specular_amount *
    specular_sample;
```

Diagram:

```text
Phong specular calculation
          │
          ▼
 potential highlight
          │
          ×
specular-map value
          │
          ▼
wood:  multiplied by black → suppressed
metal: multiplied by gray  → visible
```

# 7. The specular map does not replace shininess

These are related but different:

```text
Specular map
    controls whether and how strongly each fragment reflects

Shininess
    controls how narrow or broad the highlight is
```

The example still uses:

```zig
.material_properties = .{ 32.0, 0.0, 0.0, 0.0 },
```

So:

```text
map brightness → highlight intensity
shininess 32   → highlight shape/size
```

The whole cube currently shares shininess `32`. A more advanced system could also store shininess in a texture.

# 8. UV texture coordinates

The vertex now has three attributes:

```zig
const Vertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
    uv: [2]f32,
};
```

```text
Position   where the vertex is
Normal     which way its surface faces
UV         where it lies on the texture
```

UV coordinates generally range from `0` to `1`:

```text
              U
       0 ───────────► 1

V  0   (0,0)         (1,0)
   │
   │
   ▼
   1   (0,1)         (1,1)
```

Each cube face maps the entire texture:

```zig
.uv = .{ 0.0, 0.0 }
.uv = .{ 1.0, 0.0 }
.uv = .{ 1.0, 1.0 }
.uv = .{ 0.0, 1.0 }
```

The vertex shader passes UVs onwards:

```glsl
uv = texcoord0;
```

The GPU interpolates them across every triangle:

```text
vertex UV (0,0) ●────────● vertex UV (1,0)
                 \      /
                  \    /
                   \  /
                    ●
               interpolated UV
```

# 9. OpenGL vertex layout → Sokol

LearnOpenGL’s vertices contain:

```text
3 position floats
3 normal floats
2 UV floats
```

Equivalent OpenGL calls configure three vertex attributes.

The Sokol pipeline describes them as:

```zig
desc.layout.buffers[0].stride = @sizeOf(Vertex);

desc.layout.attrs[shd.ATTR_object_position].format = .FLOAT3;
desc.layout.attrs[shd.ATTR_object_normal0].format = .FLOAT3;
desc.layout.attrs[shd.ATTR_object_texcoord0].format = .FLOAT2;
```

Memory layout:

```text
┌────────────────┬────────────────┬─────────────┐
│ position: vec3 │ normal: vec3   │ UV: vec2    │
└────────────────┴────────────────┴─────────────┘
```

# 10. Sokol separates images, views, and samplers

Modern Sokol represents texture-related concepts separately:

```text
Image
    owns the texel memory

View
    exposes that image to a shader

Sampler
    controls how UV lookups filter and wrap
```

The image is created with:

```zig
sg.makeImage(.{
    .width = 500,
    .height = 500,
    .pixel_format = .RGBA8,
    .data = ...,
});
```

A texture view exposes it:

```zig
sg.makeView(.{
    .texture = .{
        .image = image,
    },
});
```

The sampler is:

```zig
sg.makeSampler(.{
    .min_filter = .LINEAR,
    .mag_filter = .LINEAR,
    .wrap_u = .REPEAT,
    .wrap_v = .REPEAT,
});
```

# 11. What filtering means

With nearest filtering:

```text
choose one nearest texel
result may look blocky
```

With linear filtering:

```text
blend nearby texels
result looks smoother
```

The example uses linear filtering:

```zig
.min_filter = .LINEAR,
.mag_filter = .LINEAR,
```

# 12. OpenGL texture units → Sokol bindings

LearnOpenGL uses two texture units:

```cpp
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, diffuseMap);

glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, specularMap);
```

Sokol uses generated binding slots:

```zig
state.bind.views[shd.VIEW_diffuse_texture] =
    makeTextureView(diffuse_pixels);

state.bind.views[shd.VIEW_specular_texture] =
    makeTextureView(specular_pixels);

state.bind.samplers[shd.SMP_texture_sampler] =
    sg.makeSampler(...);
```

Then both are made active with:

```zig
sg.applyBindings(state.bind);
```

Mapping:

```text
OpenGL texture unit 0   → generated diffuse texture view slot
OpenGL texture unit 1   → generated specular texture view slot
OpenGL texture settings → Sokol sampler
```

# 13. GLSL sampler mapping

Traditional OpenGL GLSL combines the texture and sampling rules:

```glsl
uniform sampler2D diffuse;
```

Modern Sokol shader source keeps them separate:

```glsl
uniform texture2D diffuse_texture;
uniform sampler texture_sampler;
```

They are combined when sampled:

```glsl
texture(
    sampler2D(diffuse_texture, texture_sampler),
    uv
);
```

This maps naturally to graphics APIs such as Metal, D3D, and WebGPU, where textures and samplers are separate resources.

# 14. Why raw RGBA copies exist

The exact chapter assets are included as PNG files:

```text
container2.png
container2_specular.png
```

This project does not currently have a runtime PNG decoder. To keep the example focused on lighting maps rather than image decoding, the PNGs were converted once into raw RGBA files:

```text
container2.rgba
container2_specular.rgba
```

They are embedded at compile time:

```zig
const diffuse_pixels =
    @embedFile("assets/lighting_maps/container2.rgba");

const specular_pixels =
    @embedFile("assets/lighting_maps/container2_specular.rgba");
```

The compile-time checks verify their sizes:

```zig
std.debug.assert(
    diffuse_pixels.len == 500 * 500 * 4,
);
```

This works identically in native and WASM builds.

# 15. OpenGL → Sokol-Zig mapping

| LearnOpenGL/OpenGL | Sokol-Zig |
|---|---|
| `stbi_load()` | Preconverted RGBA plus `@embedFile()` |
| `glGenTextures()` | `sg.makeImage()` and `sg.makeView()` |
| Texture parameters | `sg.makeSampler()` |
| `GL_TEXTURE0` | Generated diffuse view binding |
| `GL_TEXTURE1` | Generated specular view binding |
| `glBindTexture()` | Fill `sg.Bindings.views` |
| Bind all draw resources | `sg.applyBindings()` |
| `sampler2D` | `texture2D` plus separate `sampler` |
| `texture(...)` | Same shader sampling operation |
| `glVertexAttribPointer` | Pipeline vertex layout |
| VBO | `sg.makeBuffer()` |
| VAO | Pipeline layout plus `sg.Bindings` |
| Shader uniforms | Typed structs plus `sg.applyUniforms()` |
| `glDrawElements()` | `sg.draw(0, 36, 1)` |

# 16. Progression from the previous lessons

```text
colors.zig
    one object color × one light color

basic_lighting.zig
    ambient + diffuse + specular

materials.zig
    separate material and light properties

lighting_maps.zig
    diffuse and specular properties vary per fragment
```

# 17. Whole rendering flow

```text
Embedded diffuse RGBA ──► Sokol image/view ──┐
                                             │
Embedded specular RGBA ─► Sokol image/view ──┤
                                             ▼
Vertex position + normal + UV          sg.applyBindings
                                             │
Material/light uniforms ─────────► sg.applyUniforms
                                             │
                                             ▼
                                      object draw call
                                             │
                                             ▼
                                 interpolate normal and UV
                                             │
                      ┌──────────────────────┴────────────────────┐
                      ▼                                           ▼
             sample diffuse map                         sample specular map
                      │                                           │
                      ▼                                           ▼
             ambient + diffuse                              specular
                      └──────────────────────┬────────────────────┘
                                             ▼
                                    final fragment color
```

Verification passed:

```text
zig build test
zig build -Dtarget=wasm32-emscripten
git diff --check
```

I also loaded the WebGL result in headless Chrome and matched its static camera against the chapter’s final specular-map scene. ZLS go-to-definition for Sokol symbols in `lighting_maps.zig` was verified; use `:LspRestart` in an already-open Neovim session.
