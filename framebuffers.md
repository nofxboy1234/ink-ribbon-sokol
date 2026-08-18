# Framebuffers: LearnOpenGL mapped to Sokol + Zig

This is a compact, standalone mapping of the
[LearnOpenGL Framebuffers chapter](https://learnopengl.com/Advanced-OpenGL/Framebuffers)
to this project.

Run the existing scene:

```bash
zig build run-framebuffers
```

WASM:

```bash
zig build run-framebuffers -Dtarget=wasm32-emscripten
```

Controls:

| Key | Result                                   |
|-----|------------------------------------------|
| `1` | Unmodified framebuffer texture           |
| `2` | Inverted colours                         |
| `3` | Weighted grayscale                       |
| `4` | Sharpen                                  |
| `5` | Blur                                     |
| `6` | Edge detection                           |

## 1. The whole idea

Normal rendering goes directly to the window:

```text
3D scene ──► window framebuffer ──► screen
```

This lesson first renders into a texture:

```text
PASS 1                              PASS 2

3D scene ──► offscreen image ──► full-screen quad ──► window
                 store                 read
```

The first result is **offscreen**: the GPU produced it, but the window does not
display it directly.

Once the completed scene is one texture, a second fragment shader can alter
the whole picture. This is **post-processing**.

## 2. The Sokol primitives

Use these mental models:

| Sokol primitive | Simple mental model                                        |
|-----------------|------------------------------------------------------------|
| `sg.Image`      | Pixel storage: a blank or filled sheet of GPU memory       |
| `sg.View`       | An adapter saying how this operation sees that storage     |
| Attachment      | A view connected to one output socket of a render pass     |
| `sg.Pass`       | One period of rendering into a chosen set of attachments   |
| `sg.PassAction` | What to do with old contents when a pass starts            |
| `sg.Pipeline`   | Fixed drawing rules, including target formats and depth    |
| `sg.Bindings`   | Buffers, texture views, and samplers supplied as inputs    |
| `sg.Sampler`    | Rules for reading between or outside texture pixels        |
| Swapchain       | The window's displayable colour/depth images               |

The important distinction is:

```text
image = storage
view  = a particular way to access that storage
```

A view does not copy the image.

## 3. What is an attachment?

A render pass has output sockets:

```text
sg.Pass
│
├── colors[0] socket ──► colour-attachment view ──► colour image
├── colors[1] socket ──► optional second colour image
└── depth socket     ──► depth-attachment view  ──► depth image
```

An **attachment** is the view plugged into one of those sockets.

It answers:

> Where should this pass store its colour or depth results?

It is not another copy of the pixels, and the pass does not own the image.
The pass merely refers to it through a suitably typed view.

The same colour image can later be accessed differently:

```text
                         colour-attachment view
PASS 1 writes ──────────────────────────────────► colour image
                                                        │
                         texture view                   │ same storage
PASS 2 reads  ◄─────────────────────────────────────────┘
```

That write-then-read transition is the central idea of this example.

## 4. OpenGL → Sokol mapping

OpenGL keeps a mutable framebuffer object, or FBO. Sokol supplies the
attachment views directly when a pass begins.

| OpenGL                                    | Sokol + Zig                                            |
|-------------------------------------------|--------------------------------------------------------|
| `glGenFramebuffers`                       | Prepare an `sg.Pass` and attachment views              |
| `glBindFramebuffer(..., fbo)`             | `sg.beginPass(offscreen_pass)`                         |
| `glBindFramebuffer(..., 0)`               | Begin a pass with `sglue.swapchain()`                  |
| `glFramebufferTexture2D`                  | Create a colour/depth attachment `sg.View`             |
| `glGenTextures` + empty `glTexImage2D`    | `sg.makeImage` with attachment usage                   |
| `glFramebufferRenderbuffer`               | Attachment image/view not sampled by this scene        |
| `glCheckFramebufferStatus`                | Sokol validation checks compatibility                  |
| `glClear`                                 | Clear actions in `sg.PassAction`                       |
| `glViewport`                              | Full target by default; `sg.applyViewport` if needed   |
| Bind rendered colour as a texture         | Bind its texture view through `sg.Bindings`            |
| `glDeleteFramebuffers` and attachments    | Destroy views/images, or call `sg.shutdown`            |

OpenGL's separate read/draw framebuffer bindings are not needed here:

```text
write destination = attachments passed to sg.beginPass()
read input         = texture view passed through sg.applyBindings()
```

## 5. Creating the offscreen target

### Colour storage

Pass 1 needs an image that fragment shaders may write:

```zig
state.color_image = sg.makeImage(.{
    .usage = .{ .color_attachment = true },
    .width = width,
    .height = height,
    .pixel_format = .RGBA8,
    .sample_count = 1,
});
```

There is no initial pixel data. Rendering supplies it.

The image gets two views:

```zig
state.color_attachment_view = sg.makeView(.{
    .color_attachment = .{ .image = state.color_image },
});

state.color_texture_view = sg.makeView(.{
    .texture = .{ .image = state.color_image },
});
```

```text
attachment view = pass 1 may write here
texture view    = pass 2 may sample here
```

### Depth storage

The cubes and floor also need depth testing:

```zig
state.depth_image = sg.makeImage(.{
    .usage = .{ .depth_stencil_attachment = true },
    .width = width,
    .height = height,
    .pixel_format = .DEPTH,
    .sample_count = 1,
});

state.depth_attachment_view = sg.makeView(.{
    .depth_stencil_attachment = .{ .image = state.depth_image },
});
```

The chapter uses a depth/stencil renderbuffer because it does not sample that
result. This scene only needs depth, so a Sokol `.DEPTH` image with an
attachment view fills the same role.

Rule of thumb:

```text
need to sample it later?  use a texture view
only needed during tests? an attachment view is enough for this use
```

## 6. Connecting and validating attachments

The views are connected to the pass:

```zig
state.offscreen_pass.attachments.colors[0] =
    state.color_attachment_view;

state.offscreen_pass.attachments.depth_stencil =
    state.depth_attachment_view;
```

Attachments in one pass must be compatible:

```text
colour: width × height, RGBA8, 1 sample
depth:  width × height, DEPTH, 1 sample
         │       │                  │
         └───────┴──────────────────┴── must agree where required
```

The pipeline must expect the same formats and sample count:

```zig
var desc: sg.PipelineDesc = .{
    .sample_count = 1,
    .depth = .{
        .pixel_format = .DEPTH,
        .compare = .LESS,
        .write_enabled = true,
    },
};
desc.colors[0].pixel_format = .RGBA8;
```

Sokol's validation layer reports mismatched formats, dimensions, sample
counts, or missing attachments. This fills the practical role of the chapter's
`glCheckFramebufferStatus` check.

## 7. Pass actions: what happens on entry?

Each framebuffer has separate contents, so each pass needs its own decision:

```text
CLEAR     replace old contents with a chosen value
LOAD      preserve and continue using old contents
DONTCARE  old contents are irrelevant
```

This scene clears offscreen colour and depth:

```zig
state.offscreen_action.colors[0].load_action = .CLEAR;
state.offscreen_action.depth.load_action = .CLEAR;
```

Mental model:

```text
attachment = the sheet of paper
pass action = erase it, keep it, or ignore what was there
```

## 8. The two passes

### Pass 1: create the scene texture

```zig
sg.beginPass(state.offscreen_pass);
sg.applyPipeline(state.scene_pipeline);

// Draw cubes and floor normally.
// Their fragments now enter color_image, not the window.

sg.endPass();
```

```text
vertex/index buffers + object textures
                 ↓
          ordinary 3D shaders
                 ↓
    colour image + depth image
```

### Pass 2: display and process it

```zig
sg.beginPass(.{
    .action = state.display_action,
    .swapchain = sglue.swapchain(),
});

sg.applyPipeline(state.screen_pipeline);
sg.applyBindings(state.screen_bindings);
sg.draw(0, 6, 1);
sg.endPass();
```

The screen bindings contain the first pass's texture view:

```zig
state.screen_bindings.views[shd.VIEW_scene_tex] =
    state.color_texture_view;
```

The whole frame is:

```text
begin offscreen pass
  clear colour + depth
  draw 3D scene
end pass
        ↓ dependency through color_image
begin swapchain pass
  draw screen quad using color_texture_view
end pass
        ↓
sg.commit()
```

## 9. Why a full-screen quad?

Two triangles cover clip space from `-1` to `+1`:

```text
(-1,+1) ┌────────────┐ (+1,+1)
        │          / │
        │        /   │
        │      /     │
        │    /       │
(-1,-1) └────────────┘ (+1,-1)
```

The positions are already in clip space:

```glsl
gl_Position = vec4(position, 0.0, 1.0);
```

No model, view, or projection matrix is needed. Depth testing is unnecessary
because this quad is intended to cover the window.

Each fragment samples the completed scene:

```glsl
vec3 center =
    texture(sampler2D(scene_tex, scene_smp), uv).rgb;
```

## 10. Post-processing effects

Press `1`: copy the sampled colour unchanged.

Press `2`: invert each channel:

```glsl
vec3 inverted = vec3(1.0) - center;
```

```text
black (0,0,0) ──► white (1,1,1)
red   (1,0,0) ──► cyan  (0,1,1)
```

Press `3`: calculate one brightness and use it for all channels:

```glsl
float brightness =
    dot(center, vec3(0.2126, 0.7152, 0.0722));
vec3 gray = vec3(brightness);
```

Green has the largest weight because human vision is most sensitive to it.

Zig sends the selected effect to the fragment shader as a uniform:

```text
keyboard ──► Zig enum ──► uniform ──► screen fragment shader
```

## 11. Kernel effects

A 3×3 kernel reads the current pixel and its eight neighbours:

```text
top-left      top      top-right
left          YOU      right
bottom-left   bottom   bottom-right
```

Each colour is multiplied by a weight; all nine results are added.

Moving one texture pixel requires a UV-sized step:

```zig
texel_x = 1.0 / width;
texel_y = 1.0 / height;
```

For an 800-pixel-wide image, one horizontal pixel is `1 / 800` in UV space.

### Sharpen — key `4`

```text
┌             ┐
│ -1  -1  -1 │
│ -1   9  -1 │
│ -1  -1  -1 │
└             ┘
```

Emphasize the centre and subtract neighbours. Nearby differences become
stronger.

### Blur — key `5`

```text
┌          ┐
│ 1  2  1 │
│ 2  4  2 │ ÷ 16
│ 1  2  1 │
└          ┘
```

Average nearby pixels. Dividing by the weight total, `16`, preserves general
brightness.

### Edge detection — key `6`

```text
┌             ┐
│  1   1   1 │
│  1  -8   1 │
│  1   1   1 │
└             ┘
```

Similar neighbours cancel toward black. Strong differences remain as edges.

## 12. Resizing and common failures

Images have fixed dimensions. When the window changes size, the example:

```text
destroys old views and images
              ↓
creates matching colour and depth images
              ↓
creates new attachment and texture views
              ↓
updates the one-pixel kernel offsets
```

If nothing appears, check:

- the pass has compatible colour and depth attachment views;
- the offscreen pipeline formats/sample count match those images;
- pass 1 ends before pass 2 samples its image;
- pass 2 binds the **texture view**, not the attachment view;
- each pass clears or loads the contents intentionally;
- the screen quad covers clip space and its texture is not flipped.

## Quick source map

| Concept                            | Project location                       |
|------------------------------------|----------------------------------------|
| Create images and views            | `recreateOffscreenTargets()`           |
| Configure both pipelines           | `init()`                               |
| Attach colour and depth            | `recreateOffscreenTargets()`           |
| Record the two passes              | `frame()`                              |
| Select an effect                   | `input()` and `screen_fs_params`       |
| Post-processing and kernels        | `screen_fs` in `src/examples/framebuffers.glsl` |

Implementation:

- [`src/examples/framebuffers.zig`](src/examples/framebuffers.zig)
- [`src/examples/framebuffers.glsl`](src/examples/framebuffers.glsl)

Keep this final mental model:

```text
image      = storage
view       = how storage is accessed
attachment = a view plugged into a pass output
pass       = a bounded period of writing those outputs
bindings   = inputs read while drawing
swapchain  = the window's display target
```
