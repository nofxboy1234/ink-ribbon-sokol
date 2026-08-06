Implemented the three Model Loading chapters as a new Sokol + Zig backpack scene.

I interpreted the duplicated Mesh link as:

1. [Assimp](https://learnopengl.com/Model-Loading/Assimp)
2. [Mesh](https://learnopengl.com/Model-Loading/Mesh)
3. [Model](https://learnopengl.com/Model-Loading/Model)

Run it with:

```bash
zig build run-model-loading
```

WASM:

```bash
zig build run-model-loading -Dtarget=wasm32-emscripten
```

Main files:

- [model_loading.zig](/home/dylan/repos/ink-ribbon-sokol/src/model_loading.zig)
- [model_loading.glsl](/home/dylan/repos/ink-ribbon-sokol/src/model_loading.glsl)
- [OBJ conversion tool](/home/dylan/repos/ink-ribbon-sokol/tools/convert_backpack_obj.py)
- [backpack assets](/home/dylan/repos/ink-ribbon-sokol/src/assets/backpack)
- [generated shader](/home/dylan/repos/ink-ribbon-sokol/src/generated/model_loading_shader.zig)

## Zoomed-out view

The complete flow is:

```text
backpack.obj
     │
     │ parse positions, normals, UVs and faces
     ▼
interleaved Vertex values
     │
     │ upload
     ▼
Sokol vertex buffer
     │
     ├── diffuse texture
     ├── specular texture
     └── graphics pipeline
              │
              ▼
          sg.draw(...)
              │
              ▼
       rendered backpack
```

## Chapter 1: Assimp

### The problem

Different model formats store data differently:

```text
OBJ
glTF
FBX
Collada
3DS
...
```

Writing a separate complete loader for every format is a lot of work.

Assimp—Open Asset Import Library—reads many formats and converts them into one common representation:

```text
OBJ ─────┐
FBX ─────┤
Collada ─┼──► Assimp scene ──► your renderer
3DS ─────┤
... ─────┘
```

The common Assimp structure is approximately:

```text
Scene
└── Root node
    ├── Child node
    │   ├── Mesh reference
    │   └── Mesh reference
    └── Child node
        └── Mesh reference

Scene also owns:
├── Meshes
└── Materials
```

A node does not normally contain all the vertex data itself. It refers to meshes stored by the scene.

### Sokol mapping

Sokol does not have an Assimp equivalent built in.

```text
Assimp/cgltf/OBJ parser     Sokol
──────────────────────     ───────────────────
reads model files          uploads GPU buffers
understands file formats   configures pipelines
extracts materials         binds textures
builds mesh data           submits draw commands
```

Sokol deliberately concentrates on rendering. You pair it with an asset-format library or your own loader.

## What the upstream Sokol C example does

The relevant upstream example is [`cgltf-sapp.c`](https://github.com/floooh/sokol-samples/blob/master/sapp/cgltf-sapp.c).

It uses:

- `cgltf` to parse glTF
- `sokol_fetch` to load files asynchronously
- An image decoder for textures
- One Sokol buffer/binding arrangement per model primitive
- Shared Sokol pipelines for compatible primitives
- One draw call per primitive

Conceptually:

```text
sokol_fetch
    │
    ▼
cgltf parser
    │
    ▼
glTF meshes and materials
    │
    ├──► sg.makeBuffer()
    ├──► sg.makeImage()
    ├──► sg.makeSampler()
    └──► sg.Bindings
              │
              ▼
           sg.draw()
```

That is the idiomatic division of responsibilities: the loader understands the asset; Sokol receives GPU-ready resources.

## Why this example does not use cgltf

The requested backpack is an OBJ model, not glTF.

Using `cgltf` to open it would not work. Instead, this example includes a deliberately small OBJ importer demonstrating the same conversion process.

For a larger game, I would generally recommend converting source assets to glTF and using `cgltf`, or adopting another dedicated model-loading library.

## Chapter 2: Mesh

A mesh is one independently drawable piece of geometry.

It minimally needs:

```text
Mesh
├── vertices
│   ├── positions
│   ├── normals
│   └── texture coordinates
├── optional indices
└── material
    ├── diffuse texture
    └── specular texture
```

A model can contain multiple meshes:

```text
character model
├── body mesh
├── clothing mesh
├── hair mesh
└── weapon mesh
```

### The vertex structure

LearnOpenGL uses:

```cpp
struct Vertex {
    glm::vec3 Position;
    glm::vec3 Normal;
    glm::vec2 TexCoords;
};
```

The Zig equivalent is in [model_loading.zig](/home/dylan/repos/ink-ribbon-sokol/src/model_loading.zig):

```zig
const Vertex = extern struct {
    position: [3]f32,
    normal: [3]f32,
    uv: [2]f32,
};
```

Its memory is:

```text
position             normal                UV
x    y    z          x    y    z           u    v
│    │    │          │    │    │           │    │
▼    ▼    ▼          ▼    ▼    ▼           ▼    ▼
[f32 f32 f32]       [f32 f32 f32]        [f32 f32]

3 floats + 3 floats + 2 floats = 8 floats
8 × 4 bytes = 32 bytes per vertex
```

`extern struct` gives this structure a predictable C-compatible field layout.

### VBO mapping

LearnOpenGL:

```cpp
glBindBuffer(GL_ARRAY_BUFFER, VBO);
glBufferData(...);
```

Sokol + Zig:

```zig
state.bindings.vertex_buffers[0] = sg.makeBuffer(.{
    .data = sg.asRange(vertex_bytes),
});
```

### Vertex attribute mapping

LearnOpenGL uses three `glVertexAttribPointer` calls.

The Sokol equivalent is:

```zig
desc.layout.buffers[0].stride = @sizeOf(Vertex);

desc.layout.attrs[shd.ATTR_model_position].format = .FLOAT3;
desc.layout.attrs[shd.ATTR_model_normal0].format = .FLOAT3;
desc.layout.attrs[shd.ATTR_model_texcoord0].format = .FLOAT2;
```

Because the attributes are sequential, Sokol derives their offsets:

```text
position offset = 0 bytes
normal offset   = 12 bytes
UV offset       = 24 bytes
stride          = 32 bytes
```

### VAO mapping

LearnOpenGL stores vertex-buffer and attribute configuration in a VAO.

Sokol divides that state between:

```zig
sg.Pipeline
sg.Bindings
```

The pipeline describes how to interpret vertices:

```zig
state.pipeline = sg.makePipeline(desc);
```

Bindings select the actual buffer and textures:

```zig
sg.applyBindings(state.bindings);
```

### EBO/index-buffer difference

The OBJ file uses separate indices for position, UV, and normal:

```obj
f 55/1/1 57/2/2 58/3/2
```

Read one corner as:

```text
55 / 1 / 1
 │   │   │
 │   │   └── normal 1
 │   └────── UV 1
 └────────── position 55
```

A GPU index normally selects one complete vertex, not three independently indexed attribute arrays.

For simplicity, the converter expands each OBJ face corner into one complete `Vertex`:

```text
OBJ position index ─┐
OBJ normal index ───┼──► complete Vertex
OBJ UV index ───────┘
```

That means this first loader uses a non-indexed Sokol draw:

```zig
sg.draw(0, state.vertex_count, 1);
```

A production converter could deduplicate identical `(position, normal, UV)` tuples and generate a Sokol index buffer.

## Chapter 3: Model

A model owns or refers to all the meshes and materials needed to render one imported asset.

Conceptually:

```zig
const Model = struct {
    meshes: []Mesh,
    textures: []Texture,
};
```

Drawing it normally means:

```zig
for (model.meshes) |mesh| {
    mesh.draw();
}
```

The backpack’s OBJ/MTL combination resolves to one material and one GPU-ready expanded mesh, so this lesson needs one draw call.

The same architecture naturally extends to multiple meshes:

```zig
for (model.meshes) |mesh| {
    sg.applyBindings(mesh.bindings);
    sg.draw(mesh.base_element, mesh.num_elements, 1);
}
```

## Model parsing code

The educational Zig OBJ parser is:

```zig
fn parseObj(
    allocator: std.mem.Allocator,
    source: []const u8,
) ![]Vertex
```

It handles:

```obj
v  ...    # position
vn ...    # normal
vt ...    # texture coordinate
f  ...    # triangle face
```

For every face corner, it produces:

```zig
.{
    .position = positions.items[corner.position],
    .normal = normals.items[corner.normal],
    .uv = uvs.items[corner.uv],
}
```

This is the equivalent of the Model chapter’s Assimp conversion stage:

```text
importer-specific data
        ↓
your own Vertex representation
```

A focused test demonstrates this with one tiny OBJ triangle.

## Runtime asset preprocessing

Parsing nearly 7 MB of textual floating-point data during browser startup was unnecessarily slow. The converter therefore creates:

[vertices.bin](/home/dylan/repos/ink-ribbon-sokol/src/assets/backpack/vertices.bin)

Its format is simply repeated `Vertex` bytes:

```text
position.xyz normal.xyz uv.xy
position.xyz normal.xyz uv.xy
position.xyz normal.xyz uv.xy
...
```

At runtime:

```zig
const vertex_bytes =
    @embedFile("assets/backpack/vertices.bin");

state.bindings.vertex_buffers[0] = sg.makeBuffer(.{
    .data = sg.asRange(vertex_bytes),
});
```

This makes WASM startup immediate while leaving the import algorithm visible and tested.

Regenerate it with:

```bash
python3 tools/convert_backpack_obj.py
```

## Materials and textures

The backpack’s MTL file identifies:

```mtl
map_Kd diffuse.jpg
map_Ks specular.jpg
map_Bump normal.png
```

The lesson currently uses:

```text
map_Kd → diffuse texture
map_Ks → specular texture
```

The normal map is intentionally not used because normal mapping is introduced in a later LearnOpenGL chapter.

The two maps become Sokol image views:

```zig
state.bindings.views[shd.VIEW_diffuse_texture] =
    makeTextureView(diffuse_pixels);

state.bindings.views[shd.VIEW_specular_texture] =
    makeTextureView(specular_pixels);
```

One sampler describes how both images are sampled:

```zig
state.bindings.samplers[shd.SMP_texture_sampler] =
    sg.makeSampler(...);
```

The original textures were 4096×4096. The runtime teaching copies are 512×512 RGBA, which keeps the WASM download and GPU upload manageable while retaining sufficient detail at an 800×600 window.

The model’s original attribution file is preserved in the asset directory.

## Shader flow

The vertex shader receives each imported vertex:

```glsl
in vec4 position;
in vec3 normal0;
in vec2 texcoord0;
```

It calculates:

```glsl
gl_Position = mvp * position;
fragment_position = (model * position).xyz;
world_normal = mat3(transpose(inverse(model))) * normal0;
uv = texcoord0;
```

The fragment shader then:

1. Samples the imported diffuse map.
2. Samples the imported specular map.
3. Uses the imported normal.
4. Calculates ambient, diffuse, and specular lighting.
5. Produces the final fragment colour.

## OpenGL → Sokol summary

| LearnOpenGL/OpenGL | Sokol + Zig |
|---|---|
| Assimp | External parser/conversion tool |
| `Model` class | Collection of mesh GPU resources |
| `Mesh` class | Buffers, bindings, element range and material |
| `Vertex` struct | Zig `extern struct` |
| VAO | `sg.Pipeline` + `sg.Bindings` |
| VBO | `sg.Buffer` in `vertex_buffers` |
| EBO | `sg.Buffer` with `.index_buffer = true` |
| `glBufferData` | `sg.makeBuffer` |
| `glVertexAttribPointer` | Pipeline vertex layout |
| OpenGL texture ID | `sg.Image`/`sg.View` |
| Texture sampling state | `sg.Sampler` |
| `glUseProgram` | `sg.applyPipeline` |
| Bind VAO/textures | `sg.applyBindings` |
| Set uniforms | `sg.applyUniforms` |
| `glDrawElements` | `sg.draw` with indexed pipeline |
| `glDrawArrays` | `sg.draw` without index buffer |

## Verification

Completed successfully:

- OBJ parser unit test
- Complete native test suite
- Complete WASM build
- Chrome/WebGL runtime test
- Visual verification of the rendered backpack
- ZLS build configuration validation

The WASM target has a larger initial heap and memory growth enabled because it embeds the model geometry and material maps.
