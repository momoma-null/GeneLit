#ifndef GENELIT_TRIPLANAR_INCLUDED
    #define GENELIT_TRIPLANAR_INCLUDED

    #include "UnityCG.cginc"
    #include "GeneLit_Utils.cginc"

    #define SAMPLE_TEX2D_TRIPLANAR(tex, col, position, normal) \
    float3 weight = abs(normal);\
    weight /= weight.x + weight.y + weight.z;\
    float2 uv##tex[3] = { TRANSFORM_TEX(position.yz, tex), TRANSFORM_TEX(position.zx, tex), TRANSFORM_TEX(position.xy, tex) };\
    float mip##tex[3] = { ComputeTextureLOD(uv##tex[0], tex##_TexelSize.zw), ComputeTextureLOD(uv##tex[1], tex##_TexelSize.zw), ComputeTextureLOD(uv##tex[2], tex##_TexelSize.zw)};\
    SAMPLE_TEX2D_TRIPLANAR_SAMPLER(tex, tex, col)

    #define SAMPLE_TEX2D_TRIPLANAR_SAMPLER(tex, samplertex, col) \
    float4 c0##col = UNITY_SAMPLE_TEX2D_SAMPLER_LOD(tex, samplertex, uv##samplertex[0], mip##samplertex[0]);\
    float4 c1##col = UNITY_SAMPLE_TEX2D_SAMPLER_LOD(tex, samplertex, uv##samplertex[1], mip##samplertex[1]);\
    float4 c2##col = UNITY_SAMPLE_TEX2D_SAMPLER_LOD(tex, samplertex, uv##samplertex[2], mip##samplertex[2]);\
    float4 col = c0##col * weight[0] + c1##col * weight[1] + c2##col * weight[2];

#endif
