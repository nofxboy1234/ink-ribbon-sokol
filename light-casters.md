Implemented the LearnOpenGL Light Casters lesson as a separate Sokol + Zig example.

Run it with:

```bash
zig build run-light-casters
```

WASM:

```bash
zig build run-light-casters -Dtarget=wasm32-emscripten
```

The scene recreates the chapter’s final smooth-edged flashlight example: ten textured crates, diffuse/specular maps, distance attenuation, and inner/outer spotlight cones.

Key files:

- [light_casters.zig](/home/dylan/repos/ink-ribbon-sokol/src/light_casters.zig)
- [light_casters.glsl](/home/dylan/repos/ink-ribbon-sokol/src/light_casters.glsl)
- [generated shader](/home/dylan/repos/ink-ribbon-sokol/src/generated/light_casters_shader.zig)
- [build.zig](/home/dylan/repos/ink-ribbon-sokol/build.zig)
- [ZLS build configuration](/home/dylan/repos/ink-ribbon-sokol/toolchain/zls-build-config.json.in)

## Light casters, simply

A “light caster” describes where light rays come from and which direction they travel.

### Directional light

Think of sunlight:

```text
→ → → → →
→ → → → →
→ → → → →
```

All rays are parallel. The light effectively has no nearby position, only a direction.

```glsl
vec3 to_light = normalize(-light_direction);
```

This is not the type rendered by the new example, but it is the first type explained in the chapter.

### Point light

Think of a bare light bulb:

```text
       ↑
    ↖  │  ↗
  ←    ●    →
    ↙  │  ↘
       ↓
```

It has a position and shines in every direction:

```glsl
vec3 to_light =
    normalize(light_position - fragment_position);
```

Its brightness decreases with distance:

```text
                         1
attenuation = -------------------------
              constant + linear·d + quadratic·d²
```

The Zig values are:

```zig
.attenuation_terms = .{
    1.0,   // constant
    0.09,  // linear
    0.032, // quadratic
    0.0,
},
```

These match the chapter.

### Spotlight

A spotlight is a point light restricted to a cone:

```text
flashlight
    ●
     \       /
      \     /    outer cone
       \   /
        \ /      inner cone
         ↓
```

It needs:

- A position
- A direction
- An inner cutoff angle
- An outer cutoff angle
- Point-light distance attenuation

The example attaches the flashlight to the camera:

```zig
.light_position = camera_position,
.light_direction = camera_forward,
```

Therefore you do not see a separate lamp cube. The light originates from the viewer.

## Smooth spotlight edges

The inner cone is fully illuminated. Between the inner and outer cones, the light fades smoothly:

```text
outside      fade       full light       fade      outside
  0 ─────────╱──────────── 1 ─────────────╲───────── 0
```

The angles are converted to cosines on the CPU:

```zig
.spotlight_cutoffs = .{
    @cos(std.math.degreesToRadians(12.5)),
    @cos(std.math.degreesToRadians(17.5)),
    0.0,
    0.0,
},
```

The fragment shader calculates:

```glsl
float theta = dot(to_light, normalize(-light_direction.xyz));
float epsilon = inner_cutoff - outer_cutoff;

float intensity =
    clamp((theta - outer_cutoff) / epsilon, 0.0, 1.0);
```

Then direct lighting is multiplied by that intensity:

```glsl
diffuse *= attenuation * intensity;
specular *= attenuation * intensity;
```

Ambient light is attenuated by distance but is not removed by the cone. This leaves the very faint crates visible outside the flashlight beam, matching the chapter.

## OpenGL → Sokol mapping

| LearnOpenGL/OpenGL | Sokol + Zig |
|---|---|
| `glGenBuffers` and `glBufferData` | `sg.makeBuffer()` |
| VAO vertex configuration | `sg.PipelineDesc.layout` |
| `glVertexAttribPointer` | `.layout.attrs[…].format` and buffer stride |
| `glEnable(GL_DEPTH_TEST)` | Pipeline `.depth` configuration |
| `glUseProgram` | `sg.applyPipeline()` |
| `glBindVertexArray` and texture binding | `sg.applyBindings()` |
| `shader.setVec3/setFloat/setMat4` | `sg.applyUniforms()` |
| `glActiveTexture` and `glBindTexture` | `Bindings.views` and `Bindings.samplers` |
| `glDrawArrays` | `sg.draw()` |
| `glClear` | `sg.beginPass()` with `PassAction` |
| `glfwSwapBuffers` | `sg.commit()` |
| GLSL compilation/linking | `sokol-shdc` generated shader descriptors |

The main per-frame pattern is:

```zig
sg.beginPass(...);

sg.applyPipeline(state.pipeline);
sg.applyBindings(state.bind);
sg.applyUniforms(...light values...);

for (cube_positions) |position| {
    sg.applyUniforms(...this cube's model and MVP...);
    sg.draw(0, 36, 1);
}

sg.endPass();
sg.commit();
```

All ten crates reuse the same geometry, pipeline, and textures. Only their model matrices change.

Validation completed:

- `zig build test` passes.
- Full `wasm32-emscripten` build passes.
- The generated WebGL page loaded successfully in headless Chrome.
- The rendered screenshot contained the expected illuminated crates and smooth spotlight falloff.
- Both tracked and active ZLS configurations parse successfully.

Chapter reference: [LearnOpenGL — Light casters](https://learnopengl.com/Lighting/Light-casters).
