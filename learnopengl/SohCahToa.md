**SOH CAH TOA** is a memory aid for three trigonometric functions:

```text
SOH: Sine     = Opposite ÷ Hypotenuse
CAH: Cosine   = Adjacent ÷ Hypotenuse
TOA: Tangent  = Opposite ÷ Adjacent
```

Written mathematically:

```text
sin(θ) = opposite / hypotenuse
cos(θ) = adjacent / hypotenuse
tan(θ) = opposite / adjacent
```

It helps you find missing sides or angles in a right-angled triangle.

## The triangle

Start with a right triangle:

```text
                         ●
                        /│
                       / │
          hypotenuse /  │ opposite
                     /   │
                    / θ  │
                   ●─────●
                    adjacent
```

The small square would mark the 90° angle:

```text
                         ●
                        /│
                       / │
          hypotenuse /  │ opposite
                     /   │
                    / θ  │
                   ●─────┘
                    adjacent
```

The labels are relative to the angle `θ`, pronounced “theta.”

## Hypotenuse

The hypotenuse is:

- Opposite the 90° angle
- The longest side
- The diagonal side in this diagram

```text
                         ●
                        /│
           this one → / │
          hypotenuse /  │
                    /   │
                   ●────┘
```

The hypotenuse does not change identity when you choose a different non-right angle.

## Opposite

The opposite side is directly across from the angle you are considering:

```text
                         ●
                        /│
                       / │ ← opposite θ
                      /  │
                     / θ │
                    ●────┘
```

It does not touch `θ`.

## Adjacent

The adjacent side is next to the angle:

```text
                         ●
                        /│
                       / │
                      /  │
                     / θ │
                    ●────┘
                     ↑
                  adjacent
```

The hypotenuse also touches `θ`, but when using SOH CAH TOA, “adjacent” means the nearby side that is **not** the hypotenuse.

# SOH: sine

```text
SOH

S = sine
O = opposite
H = hypotenuse
```

Therefore:

```text
sin(θ) = opposite / hypotenuse
```

Diagram:

```text
                         ●
                        /│
                       / │ opposite
          hypotenuse /  │
                     / θ │
                    ●────┘
```

If:

```text
opposite   = 3
hypotenuse = 5
```

then:

```text
sin(θ) = 3 / 5
       = 0.6
```

Sine tells you how much of the diagonal length points in the opposite direction.

# CAH: cosine

```text
CAH

C = cosine
A = adjacent
H = hypotenuse
```

Therefore:

```text
cos(θ) = adjacent / hypotenuse
```

Diagram:

```text
                         ●
                        /│
                       / │
          hypotenuse /  │
                     / θ │
                    ●────┘
                     adjacent
```

If:

```text
adjacent   = 4
hypotenuse = 5
```

then:

```text
cos(θ) = 4 / 5
       = 0.8
```

Cosine tells you how much of the diagonal length points in the adjacent direction.

# TOA: tangent

```text
TOA

T = tangent
O = opposite
A = adjacent
```

Therefore:

```text
tan(θ) = opposite / adjacent
```

If:

```text
opposite = 3
adjacent = 4
```

then:

```text
tan(θ) = 3 / 4
       = 0.75
```

Tangent describes the triangle’s steepness:

```text
tangent = rise / run
```

```text
                         ●
                        /│
                       / │ rise
                      /  │
                     / θ │
                    ●────┘
                      run
```

A larger tangent means a steeper line.

# A complete example

Consider a `3-4-5` triangle:

```text
                         ●
                        /│
                       / │ 3
                    5/   │
                     / θ │
                    ●────┘
                       4
```

Relative to `θ`:

```text
opposite   = 3
adjacent   = 4
hypotenuse = 5
```

Therefore:

```text
sin(θ) = 3/5 = 0.6
cos(θ) = 4/5 = 0.8
tan(θ) = 3/4 = 0.75
```

Notice:

```text
tan(θ) = sin(θ) / cos(θ)
```

For this triangle:

```text
0.6 / 0.8 = 0.75
```

This works because:

```text
sin(θ) / cos(θ)
    =
(opposite/hypotenuse) / (adjacent/hypotenuse)
    =
opposite / adjacent
    =
tan(θ)
```

# What is it used for?

SOH CAH TOA is used when you know some triangle information and need to calculate missing information.

Typical uses include:

- Finding a missing side
- Finding an angle
- Splitting a direction into X and Y components
- Calculating slopes
- Aiming and movement in games
- Camera field-of-view calculations
- Rotating points
- Physics and engineering

# Finding a missing side

Suppose a rope has length `10` and forms a 30° angle with the ground:

```text
                         ●
                        /│
                       / │ height = ?
              rope 10 /  │
                     /30° │
                    ●─────┘
```

You know:

```text
hypotenuse = 10
angle      = 30°
opposite   = unknown
```

Use SOH:

```text
sin(30°) = opposite / 10
```

Rearrange:

```text
opposite = sin(30°) * 10
```

Since:

```text
sin(30°) = 0.5
```

the height is:

```text
opposite = 0.5 * 10
         = 5
```

# Finding the horizontal distance

Using the same rope:

```text
                         ●
                        /│
                       / │
              rope 10 /  │
                     /30° │
                    ●─────┘
                    distance = ?
```

You know:

```text
hypotenuse = 10
angle      = 30°
adjacent   = unknown
```

Use CAH:

```text
cos(30°) = adjacent / 10
```

Rearrange:

```text
adjacent = cos(30°) * 10
```

Since:

```text
cos(30°) ≈ 0.866
```

the horizontal distance is:

```text
adjacent ≈ 0.866 * 10
         ≈ 8.66
```

# Finding an angle

Suppose:

```text
opposite = 3
adjacent = 4
```

Use tangent:

```text
tan(θ) = 3/4
```

To recover the angle, use inverse tangent:

```text
θ = atan(3/4)
```

Result:

```text
θ ≈ 36.87°
```

In Zig:

```zig
const opposite: f32 = 3.0;
const adjacent: f32 = 4.0;

const angle_radians = std.math.atan(
    opposite / adjacent,
);

const angle_degrees =
    angle_radians * 180.0 / std.math.pi;
```

There are also inverse sine and cosine:

```text
θ = asin(opposite / hypotenuse)
θ = acos(adjacent / hypotenuse)
```

# Connection to the unit circle

The same triangle can be drawn inside a circle with radius `1`:

```text
                         ● point
                       / │
              radius 1   │ y
                     / θ │
                    ●────┘
                       x
```

Because the hypotenuse is `1`:

```text
cos(θ) = adjacent / 1
       = adjacent
       = x

sin(θ) = opposite / 1
       = opposite
       = y
```

Therefore:

```text
x = cos(θ)
y = sin(θ)
```

That is the connection to the earlier circular-motion explanation:

```text
point = (cos(θ), sin(θ))
```

For a circle with radius `r`:

```text
x = cos(θ) * r
y = sin(θ) * r
```

In Zig:

```zig
const x = @cos(angle_radians) * radius;
const y = @sin(angle_radians) * radius;
```

# Using it for movement

Suppose a character faces angle `θ` in a 2D XY world.

Its forward direction can be:

```zig
const forward = Vec2{
    .x = @cos(angle_radians),
    .y = @sin(angle_radians),
};
```

Diagram:

```text
                      forward
                         ↗
                       / │ sin(θ)
                     / θ │
character position ●─────┘
                     cos(θ)
```

Multiply by speed and time to calculate movement:

```zig
position.x +=
    @cos(angle_radians) * speed * delta_time;

position.y +=
    @sin(angle_radians) * speed * delta_time;
```

Here:

```text
cosine determines horizontal movement
sine determines vertical movement
```

# Using it in 3D graphics

Trigonometry appears throughout the project.

Rotation matrices use sine and cosine:

```zig
const sin_theta = math.sin(radians(angle));
const cos_theta = math.cos(radians(angle));
```

See [Mat4.rotate](/home/dylan/repos/ink-ribbon-sokol/src/examples/cube_math.zig:147).

Perspective projection uses tangent:

```zig
const t = math.tan(
    fov * (math.pi / 360.0),
);
```

See [Mat4.persp](/home/dylan/repos/ink-ribbon-sokol/src/examples/cube_math.zig:108).

The perspective calculation effectively uses a right triangle formed by:

```text
camera
   ●
    \
     \  edge of field of view
      \
       │ half of visible height
       │
       ●
      distance
```

Tangent connects:

```text
half field of view
visible height
distance from camera
```

# Choosing which function to use

First identify what you know and what you need:

```text
Need opposite and know hypotenuse?
    use sine

Need adjacent and know hypotenuse?
    use cosine

Need opposite and adjacent?
    use tangent
```

Or use this table:

| Known/needed sides | Function |
|---|---|
| Opposite and hypotenuse | Sine |
| Adjacent and hypotenuse | Cosine |
| Opposite and adjacent | Tangent |

# Important detail: the labels depend on the angle

Take this triangle:

```text
                         B
                         ●
                        /│
                       / │
                      /  │
                     /   │
                    ●────●
                    A    C
```

Relative to angle `A`:

```text
opposite = BC
adjacent = AC
```

Relative to angle `B`:

```text
opposite = AC
adjacent = BC
```

The hypotenuse remains `AB` because it is always opposite the 90° angle.

So always ask:

> Opposite or adjacent relative to which angle?

# Short mental model

```text
SOH:
    sine = vertical part / diagonal

CAH:
    cosine = horizontal part / diagonal

TOA:
    tangent = vertical part / horizontal part
```

For a unit-length direction:

```text
horizontal = cos(angle)
vertical   = sin(angle)
steepness  = tan(angle)
```

And the mnemonic is:

```text
SOH  → Sin = Opposite / Hypotenuse
CAH  → Cos = Adjacent / Hypotenuse
TOA  → Tan = Opposite / Adjacent
```
