# Face culling: LearnOpenGL mapped to Sokol + Zig

This lesson maps the [LearnOpenGL face-culling chapter](https://learnopengl.com/Advanced-OpenGL/Face-culling)
to this project's Sokol + Zig setup.

Run it natively:

```bash
zig build run-face-culling
```

Run the WASM version:

```bash
zig build run-face-culling -Dtarget=wasm32-emscripten
```

Controls:

| Key     | Result                                                         |
|---------|----------------------------------------------------------------|
| `1`     | Disable culling                                                |
| `2`     | Cull back faces; counter-clockwise means front                 |
| `3`     | Cull front faces; counter-clockwise means front                |
| `4`     | Cull back faces; clockwise means front                         |
| `5`     | Cull both sides—the equivalent draw is skipped                 |
| `I`     | Move the camera outside or inside the cube                     |
| `Space` | Pause or resume rotation                                       |

Mode `2` is the normal LearnOpenGL setup and the default.

## 1. Why remove faces?

From outside a closed cube, you can see at most three of its six faces:

```text
          ┌───────┐
         / top   /│
        ┌───────┐ │
        │ front │ /  ← right side
        │       │/
        └───────┘

visible: front + top + right
hidden:  back + bottom + left
```

The hidden faces cannot contribute visible pixels. **Face culling** removes
those entire triangles before rasterization creates their fragments.

```text
vertex shader
     ↓
assemble triangle
     ↓
front or back face?
     ↓
cull unwanted face ──► no rasterization and no fragment shader runs
```

The vertex shader has already run. Face culling mainly saves rasterization and
fragment work.

## 2. A triangle has two sides

A triangle is usually a thin mathematical surface:

```text
front side  ◄── triangle ──► back side
```

The GPU needs a rule for naming those sides. It uses the order in which the
triangle's three vertices appear.

## 3. Winding order

Suppose a triangle is facing you:

```text
             2
            / \
           /   \
          0─────1
```

Reading `0 → 1 → 2` travels counter-clockwise:

```text
0 → 1
    ↗
   2

counter-clockwise: CCW
```

Swapping the final two vertices reverses it:

```text
0 → 2 → 1

clockwise: CW
```

That is why this Zig index change reverses a triangle:

```zig
// CCW
.{ 0, 1, 2 }

// CW
.{ 0, 2, 1 }
```

The actual scene stores every cube triangle as CCW when viewed from outside
its face.

## 4. The camera changes the apparent winding

The GPU determines winding after the vertex shader has transformed vertices.
It judges the triangle as it appears on screen:

```text
near cube face                    far cube face
seen from outside                 seen through the cube

0 → 1 → 2                         0 → 1 → 2
looks CCW                         looks CW
front-facing                      back-facing
```

The same consistent model data therefore distinguishes exterior faces from
interior-facing faces.

## 5. Enabling culling

OpenGL uses mutable global state:

```cpp
glEnable(GL_CULL_FACE);
glCullFace(GL_BACK);
glFrontFace(GL_CCW);
```

Sokol stores those decisions in immutable pipeline state:

```zig
const pipeline = sg.makePipeline(.{
    .cull_mode = .BACK,
    .face_winding = .CCW,
});
```

The direct mapping is:

| OpenGL                         | Sokol                         |
|--------------------------------|-------------------------------|
| `glDisable(GL_CULL_FACE)`      | `.cull_mode = .NONE`          |
| `glCullFace(GL_BACK)`          | `.cull_mode = .BACK`          |
| `glCullFace(GL_FRONT)`         | `.cull_mode = .FRONT`         |
| `glFrontFace(GL_CCW)`          | `.face_winding = .CCW`        |
| `glFrontFace(GL_CW)`           | `.face_winding = .CW`         |

After creating the pipelines, the frame selects one:

```zig
sg.applyPipeline(state.back_ccw_pipeline);
sg.applyBindings(state.bindings);
sg.applyUniforms(shd.UB_vs_params, sg.asRange(&params));
sg.draw(0, cube_indices.len, 1);
```

## 6. An important default difference

OpenGL's default front-face winding is counter-clockwise:

```text
OpenGL default: CCW
```

Sokol's default `FaceWinding` is clockwise:

```text
Sokol default: CW
```

This does not prevent an OpenGL-style scene. Set the choice explicitly:

```zig
.face_winding = .CCW,
```

Explicit state also makes the vertex-data convention obvious to readers.

## 7. Back-face culling

The usual setup keeps outside-facing surfaces and removes the hidden inside
sides:

```zig
.cull_mode = .BACK,
.face_winding = .CCW,
```

Press `2`. From outside, the cube looks solid and ordinary. Culling is an
optimization, so the correct result often looks the same as no culling.

Now press `I` to move inside the cube:

```text
camera inside
      ●
     /|\
all visible wall sides are back-facing
```

With back-face culling, the cube disappears because all its interior sides are
removed. Press `1` and those interior sides become visible again.

## 8. Front-face culling

Press `3` to use:

```zig
.cull_mode = .FRONT,
.face_winding = .CCW,
```

The outside surfaces are removed. From outside, you see the far interior sides
and the cube appears hollow or turned inside-out.

Front-face culling is less common for ordinary object rendering, but it is
useful in some multi-pass effects such as shadow-volume or shell techniques.

## 9. Reversing the front-face rule

Press `4` to keep culling back faces but change the winding rule:

```zig
.cull_mode = .BACK,
.face_winding = .CW,
```

The geometry is still CCW. Calling its CW triangles "front" reverses which
sides survive. The result is therefore similar to:

```zig
.cull_mode = .FRONT,
.face_winding = .CCW,
```

This maps the chapter's `glFrontFace(GL_CW)` experiment.

## 10. Culling both sides

OpenGL supports:

```cpp
glCullFace(GL_FRONT_AND_BACK);
```

Every triangle is either front-facing or back-facing, so this rasterizes
nothing.

Sokol's `CullMode` contains `.NONE`, `.FRONT`, and `.BACK`, but no "both"
value. If the desired result is no triangles, simply omit the draw:

```zig
if (state.mode != .both) {
    sg.draw(0, cube_indices.len, 1);
}
```

Press `5` to see that equivalent result.

## 11. When culling should be disabled

Culling works naturally for closed objects with consistent winding:

```text
cube, sphere, character body, closed building wall mesh
```

It may be wrong for geometry intended to be visible from both sides:

```text
grass card, leaf card, sheet of paper, some particles
```

For the grass quads from the blending lesson, use a pipeline with:

```zig
.cull_mode = .NONE,
```

Another option is to model actual thickness or draw separate front and back
surfaces.

## 12. Common problems

### Inconsistent winding

If some mesh triangles are CW and others CCW, enabling culling makes random
patches disappear. Fix the model/index data so outward faces use one rule.

### Negative scale

A transform such as this mirrors an object:

```text
scale X by -1
```

Mirroring reverses winding. You may need mirrored index data, a pipeline with
the opposite `face_winding`, or a different asset convention.

### Open meshes

Looking through a hole can expose back faces that culling removes. Decide
whether the mesh should be closed, two-sided, or intentionally hollow.

## 13. Zoomed-out frame flow

```text
begin render pass
      ↓
choose cull mode + front-face winding pipeline
      ↓
apply vertex/index bindings
      ↓
apply MVP uniform
      ↓
draw indexed cube
      ↓
GPU removes unwanted triangles before rasterization
      ↓
end pass and commit
```
