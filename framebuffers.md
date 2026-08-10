# Framebuffers: LearnOpenGL mapped to Sokol + Zig

This guide maps the [LearnOpenGL framebuffer chapter](https://learnopengl.com/Advanced-OpenGL/Framebuffers)
to this project's current Sokol + Zig API.

Run it natively:

```bash
zig build run-framebuffers
```

Run it as WASM:

```bash
zig build run-framebuffers -Dtarget=wasm32-emscripten
```

Controls:

| Key | Result                                     |
|-----|--------------------------------------------|
| `1` | Show the unmodified framebuffer texture    |
| `2` | Invert every colour                        |
| `3` | Convert the image to grayscale             |
| `4` | Apply a sharpen kernel                     |
| `5` | Apply a blur kernel                        |
| `6` | Apply an edge-detection kernel             |

## 1. What is a framebuffer?

A framebuffer is the collection of images into which rendering stores its
results.

```text
framebuffer
    │
    ├── colour buffer   final red, green, blue, alpha values
    ├── depth buffer    distance used by depth testing
    └── stencil buffer  small integers used by stencil testing
```

Until this lesson, the examples normally rendered into the window's
framebuffer:

```text
scene ──► window framebuffer ──► screen
```

This lesson creates another target in GPU memory:

```text
scene ──► offscreen framebuffer ──► texture
                                         │
                                         ▼
                                  full-screen quad
                                         │
                                         ▼
                                window framebuffer
```

**Offscreen** means that the first render target is not displayed directly by
the window. It is still GPU rendering; its pixels simply go into an image that
another pass can use.

## 2. Why render offscreen?

Once the whole scene is available as one texture, a later shader can process
the completed picture:

```text
ordinary rendering              post-processing

thousands of 3D triangles       one screen-sized quad
          │                               │
          ▼                               ▼
      scene texture ─────────────► sample and alter pixels
```

The same idea is used for effects such as:

- grayscale, blur, sharpening, and edge detection;
- mirrors and security-camera displays;
- shadow maps;
- bloom and HDR pipelines;
- deferred rendering.

## 3. OpenGL framebuffer objects and Sokol passes

OpenGL creates and binds a framebuffer object, usually called an FBO:

```cpp
glGenFramebuffers(1, &fbo);
glBindFramebuffer(GL_FRAMEBUFFER, fbo);
```

Current Sokol does not expose an OpenGL-style mutable FBO object. Instead, an
offscreen `sg.Pass` directly contains the attachment views it will use:

```zig
var offscreen_pass: sg.Pass = .{};
offscreen_pass.attachments.colors[0] = color_attachment_view;
offscreen_pass.attachments.depth_stencil = depth_attachment_view;

sg.beginPass(offscreen_pass);
```

This describes the destination at the point where the pass begins.

The main mapping is:

| OpenGL                                      | Sokol + Zig                                       |
|---------------------------------------------|---------------------------------------------------|
| `glGenFramebuffers`                         | Prepare an `sg.Pass` and its attachment views     |
| `glBindFramebuffer(..., fbo)`               | `sg.beginPass(offscreen_pass)`                    |
| `glBindFramebuffer(..., 0)`                 | `sg.beginPass(.{ .swapchain = ... })`             |
| `glFramebufferTexture2D`                    | `sg.makeView(.{ .color_attachment = ... })`       |
| `glFramebufferRenderbuffer`                 | Use a depth/stencil attachment image and view     |
| `glCheckFramebufferStatus`                  | Sokol's validation checks pass compatibility      |
| `glDeleteFramebuffers`                      | Destroy owned views/images, or call `sg.shutdown` |

The window framebuffer is represented by Sokol's **swapchain**:

```zig
sg.beginPass(.{
    .action = state.display_action,
    .swapchain = sglue.swapchain(),
});
```

## 4. Images and views

Sokol separates an image's memory from the way a pass or shader sees that
memory:

```text
                    ┌── colour-attachment view ──► write rendered pixels
colour image memory ┤
                    └── texture view ────────────► sample pixels in a shader
```

The example first allocates the colour image:

```zig
state.color_image = sg.makeImage(.{
    .usage = .{ .color_attachment = true },
    .width = width,
    .height = height,
    .pixel_format = .RGBA8,
    .sample_count = 1,
});
```

There is no initial pixel data. Pass 1 will produce the data on the GPU.

It then creates two views of that same image:

```zig
state.color_attachment_view = sg.makeView(.{
    .color_attachment = .{ .image = state.color_image },
});

state.color_texture_view = sg.makeView(.{
    .texture = .{ .image = state.color_image },
});
```

A simple mental model is:

```text
image = the storage
view  = how this operation is allowed to use the storage
```

## 5. The depth attachment

The cubes and floor need depth testing during pass 1. The example creates a
separate depth image:

```zig
state.depth_image = sg.makeImage(.{
    .usage = .{ .depth_stencil_attachment = true },
    .width = width,
    .height = height,
    .pixel_format = .DEPTH,
    .sample_count = 1,
});
```

Then it creates the attachment view:

```zig
state.depth_attachment_view = sg.makeView(.{
    .depth_stencil_attachment = .{ .image = state.depth_image },
});
```

The second pass never samples the depth values, so it does not need a texture
view for this image. This fills the same role as the chapter's depth/stencil
renderbuffer: the values exist so the GPU can perform tests, not because the
post-processing shader needs to read them.

## 6. Attachment compatibility

Attachments used by one pass must agree on important properties:

```text
colour: 800 × 600, 1 sample
depth:  800 × 600, 1 sample
         │     │       │
         └─────┴───────┴── must match
```

The pipeline must also describe the target formats and sample count:

```zig
var scene_pipeline_desc: sg.PipelineDesc = .{
    .sample_count = 1,
    .depth = .{
        .pixel_format = .DEPTH,
        .compare = .LESS,
        .write_enabled = true,
    },
};
scene_pipeline_desc.colors[0].pixel_format = .RGBA8;
```

If these disagree, Sokol's validation layer reports the mismatch. This is the
Sokol equivalent of discovering that an OpenGL framebuffer is incomplete.

The window uses four samples, but that is a different pass. Its display
pipeline uses the swapchain defaults, while the offscreen pass consistently
uses one sample.

## 7. Pass 1: render the 3D scene into the texture

Pass 1 begins with the offscreen attachments:

```zig
sg.beginPass(state.offscreen_pass);
sg.applyPipeline(state.scene_pipeline);
```

The scene is then drawn normally:

```zig
sg.applyBindings(state.cube_bindings);
drawSceneObject(...);
drawSceneObject(...);

sg.applyBindings(state.floor_bindings);
drawSceneObject(...);
sg.endPass();
```

The vertex shader applies the ordinary MVP matrix, while the fragment shader
samples the marble or metal texture. The difference is only the destination:

```text
before this lesson: fragments ──► swapchain colour buffer
this first pass:    fragments ──► state.color_image
```

Both colour and depth are cleared at the start of this pass:

```zig
state.offscreen_action.colors[0].load_action = .CLEAR;
state.offscreen_action.depth.load_action = .CLEAR;
```

Each framebuffer owns separate contents, so clearing the offscreen pass does
not clear the window's framebuffer.

## 8. Pass 2: draw the texture onto the window

After `sg.endPass()`, pass 1's colour image is ready to be sampled. Pass 2
starts on the normal window swapchain:

```zig
sg.beginPass(.{
    .action = state.display_action,
    .swapchain = sglue.swapchain(),
});
```

The offscreen image's texture view is bound for the screen shader:

```zig
state.screen_bindings.views[shd.VIEW_scene_tex] =
    state.color_texture_view;
```

Finally, six vertices draw two triangles covering the screen:

```text
(-1,+1) ┌──────────────┐ (+1,+1)
        │            / │
        │          /   │
        │        /     │
        │      /       │
        │    /         │
(-1,-1) └──────────────┘ (+1,-1)

        two triangles = one full-screen quad
```

Those positions are already in clip space, so the screen vertex shader does
not need model, view, or projection matrices:

```glsl
gl_Position = vec4(position, 0.0, 1.0);
```

Depth testing is unnecessary for this pipeline because the quad is intended to
cover the whole window.

## 9. The complete frame

```text
OFFSCREEN PASS
begin pass with colour + depth attachment views
    ↓
clear its colour and depth
    ↓
draw cubes and floor
    ↓
end pass: completed scene is now in color_image

DISPLAY PASS
begin pass with the window swapchain
    ↓
bind color_image through its texture view
    ↓
draw one full-screen quad
    ↓
screen fragment shader applies the selected effect
    ↓
end pass
    ↓
sg.commit()
```

`sg.commit()` submits the completed frame after both passes have been recorded.

## 10. Normal sampling

Press `1`. The screen fragment shader simply copies the scene texture:

```glsl
vec3 center = texture(sampler2D(scene_tex, scene_smp), uv).rgb;
frag_color = vec4(center, 1.0);
```

The result looks like direct rendering, but every displayed pixel has travelled
through the offscreen texture and second pass.

## 11. Inversion

Press `2`. Each colour channel ranges from `0` to `1`. Subtracting it from `1`
finds its opposite:

```glsl
frag_color = vec4(vec3(1.0) - center, 1.0);
```

```text
black  (0, 0, 0) ──► (1, 1, 1) white
red    (1, 0, 0) ──► (0, 1, 1) cyan
```

One fragment-shader operation changes the entire finished scene.

## 12. Grayscale

Press `3`. Grayscale uses one brightness value for red, green, and blue:

```glsl
float brightness = dot(center, vec3(0.2126, 0.7152, 0.0722));
frag_color = vec4(vec3(brightness), 1.0);
```

The larger green weight models human vision being more sensitive to green.

```text
input RGB ──► weighted brightness ──► (brightness, brightness, brightness)
```

## 13. What is a kernel?

A 3×3 kernel examines the current pixel and its eight neighbours:

```text
top-left      top      top-right
left          YOU      right
bottom-left   bottom   bottom-right
```

Each sampled colour is multiplied by a weight. The weighted colours are then
added to produce the output pixel.

The shader needs to know how far apart texture pixels are:

```zig
const texel_x = 1.0 / @as(f32, @floatFromInt(width));
const texel_y = 1.0 / @as(f32, @floatFromInt(height));
```

For an 800-pixel-wide image, moving one pixel horizontally means moving
`1 / 800` through UV space.

## 14. Sharpen

Press `4`:

```text
┌             ┐
│ -1  -1  -1 │
│ -1   9  -1 │
│ -1  -1  -1 │
└             ┘
```

The current pixel is emphasized while its neighbours are subtracted. Changes
between nearby pixels therefore become stronger, making detail look sharper.

The weights add to `1`, helping broadly uniform areas keep similar brightness.

## 15. Blur

Press `5`:

```text
┌          ┐
│ 1  2  1 │
│ 2  4  2 │ ÷ 16
│ 1  2  1 │
└          ┘
```

This calculates a weighted average of nearby pixels. The center matters most,
and diagonal pixels matter least. Averaging neighbouring differences creates a
blur.

The weights total `16`, so dividing by `16` prevents the result from becoming
sixteen times brighter.

## 16. Edge detection

Press `6`:

```text
┌             ┐
│  1   1   1 │
│  1  -8   1 │
│  1   1   1 │
└             ┘
```

If the centre and neighbours are similar, the positive and negative values
mostly cancel to black. Where neighbouring pixels differ sharply, some value
remains and forms a visible edge.

## 17. Choosing an effect from Zig

The keyboard changes a Zig enum:

```zig
const Effect = enum(u8) {
    normal,
    invert,
    grayscale,
    sharpen,
    blur,
    edges,
};
```

Its numeric value is sent to the screen fragment shader as a uniform:

```zig
const screen_params = shd.ScreenFsParams{
    .post_options = .{
        @floatFromInt(@intFromEnum(state.effect)),
        texel_x,
        texel_y,
        0,
    },
};
sg.applyUniforms(shd.UB_screen_fs_params, sg.asRange(&screen_params));
```

Zig chooses the effect; thousands of fragment-shader invocations apply it to
the screen pixels in parallel on the GPU.

## 18. Resizing

Framebuffer images have fixed dimensions. If the window changes size, the old
images do not grow automatically.

The example checks the current framebuffer size each frame and recreates its
offscreen images and views when necessary:

```text
window size unchanged ──► reuse attachments

window size changed
        ↓
destroy old views and images
        ↓
create matching colour and depth images
        ↓
create new attachment and texture views
```

This also keeps the kernel's one-pixel UV offsets accurate.

## 19. Texture attachment or attachment-only storage?

Use a texture view when a later shader must sample the result:

```text
colour output ──► sampled by pass 2 ──► texture view needed
```

An attachment-only role is enough when the GPU merely needs temporary values
for rendering tests:

```text
depth output ──► used by depth testing only ──► no texture view needed here
```

If a later lesson needs to sample depth—for example, some shadow or depth-based
effects—it can create an appropriate texture view for a compatible depth image.
