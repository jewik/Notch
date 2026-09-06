# Custom macOS Liquid Glass Renderer — Technical Specification

## 1. Goal

Build a **custom glass UI renderer for a native macOS application written in Swift/SwiftUI**, visually inspired by the glass elements used by **macOS 26 system UI / Control Center**, but **without relying on Apple's high-level Liquid Glass material behavior**.

The desired glass is intentionally minimal:

* NO blur
* NO vibrancy
* NO system material
* NO automatic tint
* NO dependency on Light/Dark appearance
* NO automatic color adaptation
* NO unwanted specular/highlight effects
* NO dependency on accessibility/transparency settings where avoidable
* ONLY optical/refraction distortion concentrated near the glass boundary

The goal is not to reproduce Apple's implementation internally. The goal is to reproduce the **visual behavior** that is needed while keeping the renderer deterministic and controllable.

---

# 2. Platform

Target:

* macOS 26+
* Swift
* SwiftUI
* AppKit
* Metal / MetalKit

The renderer should be usable from SwiftUI.

Desired usage:

```swift
Text("Hello")
    .padding(30)
    .customGlass(
        in: RoundedRectangle(cornerRadius: 24),
        edgeWidth: 16,
        refraction: 8
    )
```

Also:

```swift
.customGlass(in: Circle())
```

```swift
.customGlass(in: Capsule())
```

and eventually arbitrary custom SwiftUI `Shape`.

---

# 3. Do NOT build the renderer around Apple's glass APIs

Do not use these as the actual rendering implementation:

```swift
NSVisualEffectView
```

or:

```swift
NSGlassEffectView
```

or:

```swift
.glassEffect(...)
```

They can be used as visual references for comparison, but they should not control the final appearance.

Reason:

Apple's glass APIs intentionally encapsulate:

* blur
* material
* tint
* vibrancy
* appearance adaptation
* system-specific lighting
* interactive glass behavior

The required renderer needs independent control over these properties.

Private API reverse engineering is also undesirable as the primary implementation because the implementation can change between macOS releases and private API usage can create distribution/signing/App Store problems.

---

# 4. Core rendering model

The renderer should be based on three textures/data sources:

```text
backdropTexture
        +
shapeMaskTexture
        +
distanceFieldTexture
        ↓
     Metal shader
        ↓
   custom glass
```

### `backdropTexture`

Image of the content/background behind the glass.

The glass shader samples this texture with a modified UV coordinate to create optical refraction.

### `shapeMaskTexture`

Binary or antialiased mask describing the shape of the glass.

Example:

```text
0 = outside
1 = inside
```

### `distanceFieldTexture`

Signed distance field (SDF) representing distance to the glass boundary.

Convention:

```text
negative = inside
zero     = boundary
positive = outside
```

The SDF is used to determine:

* how close a pixel is to the boundary
* the direction of the boundary normal
* how strong refraction should be

---

# 5. Main visual principle

The most important requirement:

> Refraction must happen primarily at the edge of the glass, not uniformly across the entire glass surface.

Conceptually:

```text
             glass boundary
                  ↓
        ┌───────────────────┐
        │███████████████████│ ← strong refraction
        │██               ██│
        │██               ██│
        │██     NONE      ██│ ← almost no distortion
        │██               ██│
        │███████████████████│ ← strong refraction
        └───────────────────┘
```

The center of the glass should essentially be a normal sample of the backdrop.

The boundary should optically bend/distort the backdrop.

---

# 6. Edge factor

Given signed distance:

```text
d = signedDistance(pixel, shape)
```

Calculate an edge factor:

```metal
float edge =
    1.0 - smoothstep(
        -edgeWidth,
        0.0,
        d
    );
```

Desired behavior:

```text
far inside      edge ≈ 0
near boundary   edge → 1
outside         edge = 0
```

The exact falloff should be tunable.

Parameters:

```swift
edgeWidth
refractionStrength
```

---

# 7. Boundary normal

The refraction direction should follow the normal of the actual shape boundary.

Do NOT use a vector from the shape center.

For an arbitrary SDF:

```text
normal = normalize(gradient(SDF))
```

Approximate gradient:

```metal
float dx =
    sdf(x + epsilon, y)
    -
    sdf(x - epsilon, y);

float dy =
    sdf(x, y + epsilon)
    -
    sdf(x, y - epsilon);

float2 normal =
    normalize(float2(dx, dy));
```

This allows the same algorithm to work with:

* Circle
* Capsule
* RoundedRectangle
* arbitrary Bezier/path-based shapes

---

# 8. Refraction

The basic optical distortion is:

```metal
float2 offset =
    normal
    * edge
    * refractionStrength;
```

Convert the offset to UV space:

```metal
float2 uvOffset =
    offset / resolution;
```

Then sample the backdrop:

```metal
float2 refractedUV =
    uv + uvOffset;

float4 color =
    backdropTexture.sample(
        linearSampler,
        refractedUV
    );
```

The important property is:

```text
refractionStrength = 0
```

should completely disable distortion.

---

# 9. No blur

The renderer must NOT perform Gaussian blur or any other blur as part of the glass effect.

The backdrop sample should be approximately:

```metal
backdrop.sample(linearSampler, refractedUV)
```

The only interpolation should be texture sampling.

The visual softness of the glass should come from:

* antialiasing
* edge refraction
* normal/gradient behavior
* optional very subtle compositing

not from blur.

---

# 10. No tint

The default glass color should be transparent:

```text
tint = none
```

Do not apply:

```text
white overlay
black overlay
system accent color
material color
Light/Dark mode color
```

The renderer should produce approximately:

```text
glassColor = refractedBackdrop
```

Any future tint should be an explicit optional parameter, not an implicit system behavior.

---

# 11. No appearance dependency

The renderer should behave identically in:

```text
Light mode
Dark mode
High Contrast
different accent colors
```

unless the application explicitly chooses otherwise.

Do not query:

```swift
NSAppearance
```

to determine the glass rendering parameters.

The renderer should be deterministic.

For the same:

```text
backdrop
shape
edgeWidth
refractionStrength
```

the output should be the same regardless of system appearance.

---

# 12. SwiftUI API

The desired public API is approximately:

```swift
extension View {

    func customGlass<S: Shape>(
        in shape: S,
        edgeWidth: CGFloat = 16,
        refraction: CGFloat = 8
    ) -> some View
}
```

Potential future parameters:

```swift
func customGlass<S: Shape>(
    in shape: S,
    edgeWidth: CGFloat = 16,
    refraction: CGFloat = 8,
    opacity: CGFloat = 1,
    enabled: Bool = true
) -> some View
```

Avoid exposing implementation-specific parameters unless necessary.

---

# 13. Shape handling

The renderer should eventually support arbitrary SwiftUI `Shape`.

Pipeline:

```text
SwiftUI Shape
      ↓
Path
      ↓
CGPath
      ↓
rasterized mask
      ↓
SDF
      ↓
Metal texture
```

The Metal shader must NOT need to know whether the shape is:

```swift
Circle()
```

or:

```swift
RoundedRectangle(...)
```

or a custom path.

It should only consume the resulting mask/SDF.

---

# 14. SDF generation

For the first prototype, an analytic SDF is acceptable for:

```text
RoundedRectangle
Circle
Capsule
```

For the general implementation, generate an SDF from the `CGPath`.

Possible approach:

1. Rasterize the path into a mask texture.
2. Generate a distance field from the mask.
3. Upload the distance field to Metal.
4. Calculate the gradient in the fragment shader.

Possible SDF generation implementations:

* CPU distance transform for a prototype
* GPU distance transform for production
* Jump Flooding Algorithm (JFA) for GPU implementation

The production implementation should preferably generate the SDF on GPU if shapes change frequently.

---

# 15. Backdrop architecture

The difficult part is not the fragment shader.

The difficult part is obtaining the backdrop behind the glass efficiently.

Desired architecture:

```text
Application scene
       ↓
Metal/rendering composition
       ↓
backdrop texture
       ↓
glass shader
       ↓
final composition
       ↓
MTKView / window
```

Avoid taking a screenshot of the entire window every frame.

Avoid screen capture APIs for normal rendering.

The preferred solution is to make the application rendering pipeline aware of the glass layer and provide the backdrop texture directly.

---

# 16. Renderer architecture

Recommended components:

```text
CustomGlassView
    │
    ├── CustomGlassRenderer
    │       │
    │       ├── Metal pipeline
    │       ├── backdrop texture
    │       ├── mask texture
    │       └── SDF texture
    │
    └── SwiftUI / NSViewRepresentable bridge
```

Suggested Swift classes:

```swift
final class CustomGlassRenderer:
    NSObject,
    MTKViewDelegate
```

```swift
struct CustomGlassView:
    NSViewRepresentable
```

Potential future components:

```swift
final class GlassShapeRenderer
```

```swift
final class SDFGenerator
```

```swift
final class BackdropRenderer
```

---

# 17. Metal shader inputs

The fragment shader should eventually receive:

```metal
texture2d<float> backdropTexture
texture2d<float> maskTexture
texture2d<float> sdfTexture
```

and uniforms approximately:

```metal
struct GlassUniforms {
    float2 resolution;

    float edgeWidth;
    float refractionStrength;

    float opacity;
};
```

Potential future parameters:

```text
edgeFalloff
normalStrength
chromaticDispersion
```

but these should NOT be implemented until the basic effect works.

---

# 18. Basic fragment algorithm

The intended algorithm is:

```text
1. Get UV.

2. Read shape mask.

3. Read signed distance.

4. Calculate edge factor.

5. Calculate SDF gradient.

6. Normalize gradient → boundary normal.

7. Calculate refraction offset.

8. Offset backdrop UV.

9. Sample backdrop.

10. Composite only inside the shape.
```

Pseudo-code:

```metal
float mask =
    maskTexture.sample(sampler, uv).r;

float distance =
    sdfTexture.sample(sampler, uv).r;

float edge =
    calculateEdge(distance);

float2 normal =
    calculateSDFGradient(sdfTexture, uv);

float2 refractedUV =
    uv +
    normal *
    edge *
    refractionStrength /
    resolution;

float4 backdrop =
    backdropTexture.sample(
        sampler,
        refractedUV
    );

return backdrop * mask * opacity;
```

---

# 19. First prototype scope

Do NOT implement everything initially.

### Phase 1

Support only:

```text
RoundedRectangle
```

with:

```text
backdrop texture
+
analytic SDF
+
edge refraction
```

No blur.

No tint.

No animation.

No interaction.

No private API.

Goal:

> Verify that the optical edge distortion looks correct.

### Phase 2

Add:

```text
Circle
Capsule
```

### Phase 3

Add:

```text
arbitrary SwiftUI Shape
```

through:

```text
Shape → CGPath → mask → SDF
```

### Phase 4

Build an efficient backdrop compositor.

### Phase 5

Optimize GPU performance and support animated shapes/resizing.

---

# 20. Important visual constraint

Do not interpret "glass" as:

```text
blur + translucent white + shadow
```

That is NOT the desired effect.

The desired effect is closer to:

```text
transparent optical surface
+
localized edge refraction
```

Conceptually:

```text
BACKDROP
────────────────────────────

          ↘     ↓     ↙
       ┌─────────────────┐
       │                 │
       │    backdrop     │
       │    unchanged    │
       │                 │
       └─────────────────┘
          ↗     ↑     ↖

────────────────────────────
```

The glass should be almost invisible in the center and become visually apparent primarily through the distorted boundary.

---

# 21. Reference implementation status

A minimal prototype already consists of:

```text
CustomGlass.metal
CustomGlassRenderer.swift
CustomGlassMTKView.swift
CustomGlassView.swift
```

The prototype uses:

```text
MTKView
MTLRenderPipelineState
MTLTexture
Metal fragment shader
RoundedRectangle SDF
```

The current missing production component is:

```text
backdropTexture acquisition
```

and the current SDF implementation should eventually be replaced/extended with a general shape-to-SDF pipeline.

---

# 22. Definition of success

The implementation is successful when this:

```swift
.customGlass(
    in: RoundedRectangle(cornerRadius: 24)
)
```

produces a glass element where:

* background remains sharp
* there is no blur
* there is no system material
* there is no automatic tint
* Light/Dark mode does not change the glass parameters
* the interior is mostly visually neutral
* the border creates optical distortion
* distortion follows the actual shape boundary
* changing the shape automatically changes the refraction geometry
* the renderer is entirely controlled by the application
* rendering is performed on Metal/GPU
* no private Apple API is required

The visual target is **macOS 26-style glass**, but the implementation should be an independent deterministic renderer rather than a wrapper around Apple's Liquid Glass implementation.

