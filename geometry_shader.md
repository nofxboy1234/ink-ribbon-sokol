# Geometry shaders: LearnOpenGL mapped to Sokol + Zig

This is a concise, standalone map of the
[LearnOpenGL Geometry Shader chapter](https://learnopengl.com/Advanced-OpenGL/Geometry-Shader)
to this project.

Run the scene:

```bash
zig build run-geometry-shader
```

WASM:

```bash
zig build run-geometry-shader -Dtarget=wasm32-emscripten
```

Controls:

| Key | Scene                                                  |
|-----|--------------------------------------------------------|
| `1` | Four CPU-expanded houses                               |
| `2` | Cube faces animated outward like an exploding object   |
| `3` | Cube with its vertex-normal directions drawn as lines  |

## 1. The chapter's core idea

An OpenGL geometry shader is an optional stage between the vertex shader and
rasterization:

```text
vertex shader
      │ individual transformed vertices
      ▼
primitive assembly
      │ one complete point, line, or triangle
      ▼
geometry shader
      │ may emit zero, one, or many new primitives
      ▼
rasterization ──► fragment shader
```

Mental model: **the vertex shader edits individual ingredients; the geometry
shader receives one assembled shape and may rebuild it into other shapes.**

For example:

```text
one input point ──► one line
one input point ──► one five-vertex house strip
one triangle    ──► the same triangle moved along its face normal
one triangle    ──► three normal-debug lines
```

## 2. The important Sokol limitation

Core `sokol_gfx` does **not** expose classic geometry shaders:

```text
sg.ShaderDesc
├── vertex_func
├── fragment_func
└── compute_func

no geometry_func
```

This is intentional portability. Geometry shaders exist in desktop OpenGL,
but not in WebGL, Metal, or WebGPU. A direct implementation would prevent this
project from supporting all of its current backends.

The scene therefore demonstrates the same ideas using portable replacements:

| Chapter operation                 | Portable Sokol replacement                         |
|-----------------------------------|----------------------------------------------------|
| Point becomes a house             | Expand the point into triangles on the CPU         |
| Repeated small shape              | CPU expansion or instanced geometry                |
| Move a triangle by its face normal| Duplicate vertices per face; move in vertex shader |
| Draw vertex normals               | Build a line vertex buffer on the CPU              |
| Large GPU-generated geometry      | Often compute shader + storage buffers             |

## 3. Geometry-shader inputs and outputs

OpenGL declares which complete primitive enters the shader:

```glsl
layout(triangles) in;
```

Its input is an array because a triangle contains three vertices:

```text
gl_in[0] ── first triangle corner
gl_in[1] ── second triangle corner
gl_in[2] ── third triangle corner
```

Possible inputs include points, lines, triangles, and adjacency variants.
Adjacency inputs include neighbouring vertices so the shader can reason about
edges shared by nearby primitives.

The shader also declares its output shape and maximum output count:

```glsl
layout(triangle_strip, max_vertices = 5) out;
```

The output choices are points, line strips, and triangle strips. Those are
enough to construct many shapes.

In Sokol, `sg.Pipeline.primitive_type` chooses the primitives entering ordinary
rasterization:

```zig
.primitive_type = .LINES,
```

It does not create an intermediate geometry stage or change one primitive type
into another.

## 4. `EmitVertex` and `EndPrimitive`

In a geometry shader:

```glsl
gl_Position = new_position;
EmitVertex();
```

means:

> Copy the current output values into the next emitted vertex.

This includes `gl_Position` and any varying values such as colour or texture
coordinates. Changing a varying before the next `EmitVertex()` changes that
new vertex's attached data.

```glsl
EndPrimitive();
```

means:

> Finish the current point, line strip, or triangle strip.

Mental model:

```text
set outputs ─► stamp vertex ─► set outputs ─► stamp vertex ─► close strip
               EmitVertex                    EmitVertex       EndPrimitive
```

There is no Sokol equivalent because those functions belong specifically to a
geometry shader. The CPU replacement writes the final vertices into an array
before `sg.makeBuffer()`.

## 5. Building houses

The chapter sends four points and turns each point into five output vertices.
Those five vertices form a triangle strip containing three triangles:

```text
                    5 roof
                    ▲
                   / \
             3 ┌──/───\──┐ 4
               │         │
             1 └─────────┘ 2

strip order: 1, 2, 3, 4, 5
```

This project's portable version starts with the same four conceptual centres,
but `makeHouses()` expands each centre into an ordinary triangle list:

```text
4 house centres × 3 triangles × 3 corners = 36 vertices
```

The result is uploaded once:

```zig
state.house_bindings.vertex_buffers[0] = sg.makeBuffer(.{
    .data = sg.asRange(&house_vertices),
});
```

The roof apex is white, so rasterization interpolates from the wall colour to
white. This recreates the chapter's snow-coloured roof tip.

For thousands of repeated houses or grass blades, instancing is usually better
than storing every expanded copy. One small house mesh is reused while an
instance buffer supplies each centre, colour, scale, or rotation.

## 6. Exploding a mesh

The chapter moves all three corners of a triangle in its face-normal direction:

```text
                 normal
                   ↑
original face   ┌─────┐
                └─────┘

exploded face         ┌─────┐
                      └─────┘
```

A geometry shader can calculate one normal from the triangle's three positions:

```glsl
vec3 a = p0 - p1;
vec3 b = p2 - p1;
vec3 normal = normalize(cross(a, b));
```

The two subtractions produce directions lying along the triangle surface. The
cross product produces a perpendicular direction. Reversing the cross-product
order reverses the normal.

The portable scene stores the face normal with every face vertex instead:

```text
face vertex 0 ─┐
face vertex 1 ─┼── all contain the same face normal
face vertex 2 ─┤
face vertex 3 ─┘
```

The ordinary vertex shader can then move every corner identically:

```glsl
vec3 exploded_position = position + normal * explode_distance;
```

The CPU animates the distance:

```zig
0.45 * (0.5 + 0.5 * @sin(time * 1.7))
```

```text
sin result:       -1 ───────────── +1
0.5 + 0.5*sin:     0 ─────────────  1
final distance:    0 ──────────── 0.45
```

The `+ 0.5` shifts the wave so faces move outward and return instead of moving
inward during the negative half of `sin`.

## 7. Visualizing normals

Normal lines are a debugging view:

```text
surface vertex ●────────► vertex + normal × line_length
               line start             line end
```

The chapter uses a second draw with a geometry shader that emits one line for
each normal. This project builds those start/end pairs once in `init()`:

```zig
normal_lines[i * 2] = vertex.position;
normal_lines[i * 2 + 1] = vertex.position + vertex.normal * 0.28;
```

It then draws the object normally and overlays the yellow line buffer:

```zig
sg.applyPipeline(state.mesh_pipeline);
sg.draw(...);

sg.applyPipeline(state.line_pipeline);
sg.draw(...);
```

If the lines point sideways, inward, or have unexpected lengths, the mesh's
normal data or normal transformation is probably wrong.

For a transformed object, positions and normals must reach the same coordinate
space before making the line endpoints. Non-uniform scale requires a normal
matrix rather than transforming normals exactly like positions.

## 8. Which replacement should you choose?

```text
geometry rarely changes?          build it once on the CPU
many copies of one small shape?    use instancing
simple per-vertex movement?        use the vertex shader
triangle must move as one face?    duplicate vertices and store face data
large GPU-generated output?        consider a compute-driven design
debug normals occasionally?        build a temporary line buffer
```

The durable concept is not the OpenGL-specific stage. It is this question:

> Starting from one primitive or compact description, where should the final
> drawable vertices be generated for the backends I need to support?

## Quick source map

| Lesson concept                 | Project location                              |
|--------------------------------|-----------------------------------------------|
| CPU-expanded houses            | `makeHouses()`                                |
| House colour and snow gradient | `house_vertices` and `color_fs`               |
| Stored flat face normals       | `cube_vertices`                               |
| Animated face explosion        | `drawCubeScene()` and `mesh_vs`               |
| CPU-generated normal lines     | `normal_lines` construction in `init()`       |
| Normal-line overlay draw       | `.normals` branch in `drawCubeScene()`        |
| Portable shader programs       | `src/geometry_shader.glsl`                    |
