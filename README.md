<div align="center">
  <img src="https://user-images.githubusercontent.com/44657486/165004226-c928b922-56a2-4b4f-b5cf-efbd92a938a2.png">
</div>

# Overview
Physically based rendering (PBR) shaders for Unity derived from [Filament shaders](https://github.com/google/filament).
More beautiful and accurate rendering than Unity Standard shaders.

![GeneLit0](https://user-images.githubusercontent.com/44657486/200121648-ff1bbcef-a948-4636-b02d-009d1f436997.png)
![GeneLit1](https://user-images.githubusercontent.com/44657486/200121660-8919e730-f847-4ca7-8abb-f5d508b19a10.png)

# Feature
- [Basic Filament Features](https://google.github.io/filament/Materials.html) 
  - Albedo
  - Metallic
  - Smoothness
  - Ambient Occlusion
    - Multi Bounce AO
    - Specular AO
  - Reflectance (instead of IoR)
  - Normal
  - Bent Normal
  - Emission
  - Anisotropy (tangent map)
  - Sheen
  - Clear Coat
  - Refraction
    - Thin
    - Solid sphere
    - Using Reflection Probe
    - Main texture alpha channel is used as Transmission
  - Subsurface Model
    - No Sheen and Refraction
  - Cloth Model
    - No Metallic, Reflectance, Sheen and Refraction
  - Directional Light
  - Additional Light
  - Micro Shadowing
  - Specular AA
- Unity's standard rendering features
  - Blend Mode
    - Alpha Clipping
      - Alpha to coverage
    - Transparent
    - Fade
    - Additive
    - Multiply
  - Culling Mode
  - Decal Mode
  - Detail Map
    - Choice of UV0~UV3
  - Vertex Color
    - Vertex Color Alpha is used as Detail Mask
  - Vertex Light
  - Ambient Light
  - Reflection Probe
    - Box Projection
    - Blend
  - Light Map
  - Directional Map
  - Receive Shadow
  - Cast Shadow
  - Meta Pass
  - GPU Instancing
- Special Features
  - Parallax Map
    - More accurate unique method by sampling twice
    - or Parallax Occlusion mode
  - Light Source Estimation from Spherical Harmonics
  - Accurate Fog
  - Tri Planar Sampling
  - No Tiling Sampling
  - Height Map Shadow
  - Tree Shader for "Tree It"
- Experimental Features
  - Capsule AO / Capsule Shadow
    - A dedicated script is required
  - Cylinder Projection of Reflection / Additive box Projection of Reflection
    - Only if using box projection
  - Skybox Fog
  - Using vertex light as pixel light
  - Specular AO
  - Support for LTCGI
  - Support for VRC Light Volumes

# Map Channel
Basically same as [Unity HDRP mapping](https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@15.0/manual/Mask-Map-and-Detail-Map.html)
## Albedo
| Channel | Map |
|---|---|
| RGB | Albedo (Color)  |
| A   | Opacity |

## Mask Map
| Channel | Map |
|---|---|
| R | Metallic  |
| G | Occlusion |
| B | Detail Mask |
| A | Smoothness |

## Detail Map
| Channel | Map |
|---|---|
| R | Desaturated albedo  |
| G | Normal Y |
| B | Smoothness |
| A | Normal X |

# Height Map
Gene Lit Shaders provides more accurate parallax than Standard Shader by sampling a height map twice.

A height map and a directional light can be used to create a pseudo-shadow effect.(Height Map Shadow)

![HeightMapComparision](https://user-images.githubusercontent.com/44657486/209775824-256d83e8-7b12-4d17-a981-f4db18f1e769.png)

# Notice
Filament code is included under the Apache license.Copyright (C) 2020 Google, Inc.
