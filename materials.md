Implemented the LearnOpenGL Materials chapter as a separate example, preserving the earlier lessons.

Run natively:

```bash
zig build run-materials
```

Run as WASM:

```bash
zig build run-materials -Dtarget=wasm32-emscripten
```

Added:

- [`materials.zig`](/home/dylan/repos/ink-ribbon-sokol/src/examples/materials.zig)
- [`materials.glsl`](/home/dylan/repos/ink-ribbon-sokol/src/examples/materials.glsl)
- [`materials_shader.zig`](/home/dylan/repos/ink-ribbon-sokol/src/examples/generated/materials_shader.zig)

It is also integrated with native builds, WASM builds, tests, and ZLS.

# 1. What is a material?

A material describes how an object reacts to light.

For example:

```text
Steel       strong, sharp reflection
Plastic     medium reflection
Clay        weak, broad reflection
Wood        mostly diffuse reflection
```

The previous example had one general object color. The Materials chapter separates the surface into four properties. [LearnOpenGL: Materials](https://learnopengl.com/Lighting/Materials)

```text
Material
├── ambient color
├── diffuse color
├── specular color
└── shininess
```

# 2. Material properties

The example uploads:

```zig
.material_ambient = .{ 1.0, 0.5, 0.31, 1.0 },
.material_diffuse = .{ 1.0, 0.5, 0.31, 1.0 },
.material_specular = .{ 0.5, 0.5, 0.5, 1.0 },
.material_properties = .{ 32.0, 0.0, 0.0, 0.0 },
```

## Ambient material color

```text
material ambient = (1.0, 0.5, 0.31)
```

This says how the material reflects ambient or indirect light.

The coral color remains visible in shadowed areas.

## Diffuse material color

```text
material diffuse = (1.0, 0.5, 0.31)
```

This says how the material reflects direct light.

For this material, the main body color is coral.

## Specular material color

```text
material specular = (0.5, 0.5, 0.5)
```

This controls the color and strength of the shiny highlight.

The equal RGB components make it neutral gray:

```text
red   = 0.5
green = 0.5
blue  = 0.5
```

It is not strongly tinted coral.

## Shininess

```text
shininess = 32
```

This controls the highlight’s size:

```text
Low shininess                 High shininess

broad, soft highlight         small, sharp highlight
      █████                         ██
    █████████                       ██
```

It is used as an exponent:

```glsl
float specular_amount = pow(
    max(dot(view_direction, reflected_direction), 0.0),
    shininess
);
```

# 3. The light also has properties

A material describes the surface. A light describes what reaches that surface.

```text
Material                         Light
how the surface reacts           what the source emits

ambient reflection      ×        ambient intensity
diffuse reflection      ×        diffuse intensity
specular reflection     ×        specular intensity
```

The example uploads:

```zig
.light_ambient = .{ 0.2, 0.2, 0.2, 1.0 },
.light_diffuse = .{ 0.5, 0.5, 0.5, 1.0 },
.light_specular = .{ 1.0, 1.0, 1.0, 1.0 },
```

Meaning:

```text
Ambient light     weak:          20%
Diffuse light     medium:        50%
Specular light    full strength: 100%
```

Ambient is deliberately weak so it does not wash out the scene.

# 4. Material and light work together

Ambient:

```glsl
vec3 ambient =
    light_ambient.rgb *
    material_ambient.rgb;
```

Diffuse:

```glsl
vec3 diffuse =
    light_diffuse.rgb *
    (diffuse_amount * material_diffuse.rgb);
```

Specular:

```glsl
vec3 specular =
    light_specular.rgb *
    (specular_amount * material_specular.rgb);
```

Finally:

```glsl
frag_color = vec4(
    ambient + diffuse + specular,
    1.0
);
```

Diagram:

```text
light ambient  × material ambient  ──► ambient result
light diffuse  × material diffuse  ──► diffuse result
light specular × material specular ──► specular result
                                             │
               ┌─────────────────────────────┘
               ▼
     ambient + diffuse + specular
               │
               ▼
        final fragment color
```

# 5. A numerical ambient example

The light’s ambient intensity is:

```text
(0.2, 0.2, 0.2)
```

The material’s ambient reflection is:

```text
(1.0, 0.5, 0.31)
```

Multiply components:

```text
red:    0.2 × 1.0  = 0.2
green:  0.2 × 0.5  = 0.1
blue:   0.2 × 0.31 = 0.062
```

Result:

```text
ambient result = (0.2, 0.1, 0.062)
```

This creates a dark coral base color even where diffuse light is absent.

# 6. Difference from Basic Lighting

Basic Lighting used:

```glsl
vec3 result =
    (ambient + diffuse + specular) *
    object_color.rgb;
```

One object color affected everything.

Materials uses separate controls:

```glsl
ambient  = light_ambient  * material_ambient;
diffuse  = light_diffuse  * diffuse_amount * material_diffuse;
specular = light_specular * specular_amount * material_specular;
```

That means you could create:

```text
red body with white highlight
blue body with yellow highlight
dark diffuse surface with a strong reflection
bright diffuse surface with almost no reflection
```

# 7. GLSL structs versus Sokol uniform blocks

LearnOpenGL defines:

```glsl
struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};
```

OpenGL then sets fields using string names:

```cpp
shader.setVec3("material.ambient", ...);
shader.setFloat("material.shininess", ...);
```

The Sokol shader uses a uniform block:

```glsl
layout(binding = 1) uniform materials_fs_params {
    vec4 material_ambient;
    vec4 material_diffuse;
    vec4 material_specular;
    vec4 material_properties;
    vec4 light_position;
    vec4 light_ambient;
    vec4 light_diffuse;
    vec4 light_specular;
    vec4 view_position;
};
```

Sokol-shdc generates a matching Zig type:

```zig
const materials_fs_params = shd.MaterialsFsParams{
    .material_ambient = ...,
    .material_diffuse = ...,
    .material_specular = ...,
    .material_properties = ...,
    .light_position = ...,
    .light_ambient = ...,
    .light_diffuse = ...,
    .light_specular = ...,
    .view_position = ...,
};
```

Then the complete block is uploaded at once:

```zig
sg.applyUniforms(
    shd.UB_materials_fs_params,
    sg.asRange(&materials_fs_params),
);
```

This avoids runtime string lookups such as:

```text
"material.ambient"
"material.diffuse"
"light.specular"
```

Misspelled Zig field names become compile errors.

# 8. Why use `vec4` for three-component values?

The shader needs only RGB for most properties, but it stores them as `vec4`:

```glsl
vec4 material_ambient;
```

This gives every field a simple 16-byte alignment across GLSL, Metal, HLSL, WGSL, and Zig.

Only RGB is used:

```glsl
material_ambient.rgb
```

The fourth value is padding or convenient extra storage.

Shininess is stored in the first component of:

```glsl
vec4 material_properties;
```

Uploaded as:

```zig
.material_properties = .{ 32.0, 0.0, 0.0, 0.0 },
```

Read in the shader:

```glsl
float shininess = material_properties.x;
```

# 9. OpenGL → Sokol-Zig mapping

| LearnOpenGL/OpenGL | Sokol-Zig |
|---|---|
| `struct Material` uniform | Fields in `MaterialsFsParams` |
| `struct Light` uniform | Fields in `MaterialsFsParams` |
| `shader.setVec3(...)` | Fill a typed Zig uniform field |
| `shader.setFloat(...)` | Fill `material_properties.x` |
| Upload individual uniforms | One `sg.applyUniforms()` call |
| `glUseProgram()` | `sg.applyPipeline()` |
| Bind VAO | `sg.applyBindings()` plus pipeline layout |
| VBO | `sg.makeBuffer()` in `vertex_buffers[0]` |
| EBO | Index buffer with `.index_buffer = true` |
| `glVertexAttribPointer()` | `PipelineDesc.layout` |
| `glDrawElements()` | `sg.draw(0, 36, 1)` |
| Compile/link GLSL | `sokol-shdc` and `sg.makeShader()` |

# 10. What stayed the same

The example retains the previous lesson’s:

- Position and normal vertex data
- World-space lighting
- Normal matrix
- Diffuse dot product
- Reflection calculation
- Fixed camera
- White lamp marker
- Two rendering pipelines

What changed is how the light and surface properties are represented and combined.

# 11. Rendering flow

```text
CPU fills material properties
CPU fills light properties
CPU builds MVP and model matrices
             │
             ▼
sg.applyPipeline(object pipeline)
sg.applyBindings(cube mesh)
sg.applyUniforms(vertex parameters)
sg.applyUniforms(material/light parameters)
             │
             ▼
GPU transforms vertices
GPU interpolates positions and normals
GPU calculates ambient/diffuse/specular
GPU writes final material color
             │
             ▼
switch to lamp pipeline
reuse cube mesh
draw small white lamp
```

Verification passed:

```text
zig build test
zig build -Dtarget=wasm32-emscripten
git diff --check
```

I also loaded the WASM page in headless Chrome and confirmed the material-shaded coral cube and white lamp marker render correctly. ZLS go-to-definition for Sokol symbols in `materials.zig` was also verified. Restart ZLS with `:LspRestart` if Neovim was already open when the new module was added.
