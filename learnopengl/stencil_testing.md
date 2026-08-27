# Stencil testing: LearnOpenGL mapped to Sokol + Zig

The stencil buffer is a small integer stored beside every screen pixel. Think
of it as a mask that the GPU can draw into and consult later:

```text
colour buffer     depth buffer       stencil buffer
final colours     nearest depths     small labels such as 0 or 1
     │                  │                     │
     └──────────────────┴─────────────────────┘
                    one value per pixel
```

It does not normally appear on screen. Instead, a stencil test decides whether
a fragment is allowed to continue toward the colour and depth buffers.

## The OpenGL to Sokol mapping

| LearnOpenGL / OpenGL                  | Sokol + Zig                                                                |
|---------------------------------------|----------------------------------------------------------------------------|
| `glEnable(GL_STENCIL_TEST)`           | `.stencil.enabled = true` in `sg.PipelineDesc`                             |
| `glClear(GL_STENCIL_BUFFER_BIT)`      | `pass_action.stencil.load_action = .CLEAR`                                 |
| stencil clear value `0`               | `pass_action.stencil.clear_value = 0`                                      |
| `glStencilFunc(func, ref, mask)`      | `.stencil.front/back.compare`, `.ref`, and `.read_mask`                    |
| `glStencilMask(mask)`                 | `.stencil.write_mask`                                                      |
| `glStencilOp(sfail, dpfail, dppass)`  | `.fail_op`, `.depth_fail_op`, and `.pass_op`                               |
| `GL_ALWAYS`                           | `sg.CompareFunc.ALWAYS` / `.ALWAYS`                                        |
| `GL_NOTEQUAL`                         | `sg.CompareFunc.NOT_EQUAL` / `.NOT_EQUAL`                                  |
| `GL_KEEP`                             | `sg.StencilOp.KEEP` / `.KEEP`                                              |
| `GL_REPLACE`                          | `sg.StencilOp.REPLACE` / `.REPLACE`                                        |
| change stencil state before a draw    | apply a different immutable `sg.Pipeline`                                  |
| `glDisable(GL_DEPTH_TEST)`            | use a pipeline with `.depth.compare = .ALWAYS` and depth writes disabled   |

OpenGL changes individual pieces of global state with function calls. Sokol
collects those choices into an immutable pipeline. This example therefore
creates three pipelines once in `init()` and chooses the required pipeline
before each draw.

## What the stencil comparison does

For every rasterized fragment, the GPU compares:

```text
pipeline reference value       stencil value already at this pixel
            1          compare                 0 or 1
```

The comparison can always pass, pass only when the values are equal, pass only
when they differ, and so on. The read mask controls which bits participate in
that comparison.

The three stencil operations say what happens in each possible case:

```text
stencil test failed ───────────────────────────► fail_op
stencil passed, but depth failed ──────────────► depth_fail_op
stencil and depth both passed ─────────────────► pass_op
```

`KEEP` leaves the stored value alone. `REPLACE` writes the pipeline's reference
value. The chapter uses `KEEP, KEEP, REPLACE`, meaning that only visible object
fragments mark the stencil buffer.

## How the outline is produced

At the beginning of every frame, colour, depth, and stencil are cleared. The
stencil buffer starts entirely at zero:

```text
0 0 0 0 0 0 0
0 0 0 0 0 0 0
0 0 0 0 0 0 0
```

The scene then follows these steps:

1. Draw the floor with ordinary depth testing and no stencil writes.
2. Draw unselected cubes normally.
3. Draw the selected cube with `ALWAYS`, `REPLACE`, reference `1`, and write
   mask `0xFF`.
4. Draw that cube again, scaled to `1.1`, using the solid-colour shader.
5. For this enlarged draw, use `NOT_EQUAL`, reference `1`, and write mask
   `0x00`.

After step 3, the selected cube has left a silhouette of ones:

```text
0 0 0 0 0 0 0
0 0 1 1 1 0 0
0 0 1 1 1 0 0
0 0 0 0 0 0 0
```

The enlarged cube covers a slightly larger region:

```text
0 1 1 1 1 1 0
0 1 1 1 1 1 0
0 1 1 1 1 1 0
```

Its `NOT_EQUAL 1` stencil test rejects the middle and accepts only pixels still
containing zero:

```text
0 # # # # # 0
0 #         # 0       # = visible outline colour
0 #         # 0
```

Depth comparison is `ALWAYS` for this second draw, matching the chapter's
temporary `glDisable(GL_DEPTH_TEST)`. Depth writes are disabled so this visual
overlay does not damage the depth buffer.

## Clicking a cube

Stencil testing answers “where may this fragment draw?” It does not tell the
CPU what the mouse is pointing at. Selection is a separate operation:

```text
mouse pixel
    │
    ▼
convert to a world-space ray from the camera
    │
    ▼
test that ray against each cube's axis-aligned box
    │
    ▼
store the nearest hit as selected_cube
```

`pickCube()` builds the ray using the camera's forward, right, and up vectors.
`rayBoxDistance()` uses the slab method: it finds where the ray enters and
leaves the box on X, Y, and Z. A cube is hit only if those three intervals
overlap. If multiple cubes were along the same ray, the nearest hit wins.

Clicking empty space stores `null`, so no outline pass is recorded.

## Files and commands

- Scene: `src/examples/stencil_testing.zig`
- Shader: `src/examples/stencil_testing.glsl`
- Native: `zig build run-stencil-testing`
- WASM: `zig build run-stencil-testing -Dtarget=wasm32-emscripten`

The chapter's complete explanation is available at
[LearnOpenGL: Stencil testing](https://learnopengl.com/Advanced-OpenGL/Stencil-testing).
