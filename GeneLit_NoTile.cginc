#ifndef GENELIT_NOTILE_INCLUDED
    #define GENELIT_NOTILE_INCLUDED

    #include "UnityCG.cginc"

    struct TileInfo
    {
        float f;
        float2 offa;
        float2 offb;
        float mip;
    };

    #define SAMPLE_TEX2DTILE_WIEGHT(tex, col, pos, normal) \
    float3 w = abs(normal);\
    w /= (w.x + w.y + w.z);\
	float2 uv[3] = { TRANSFORM_TEX(pos.yz, tex), TRANSFORM_TEX(pos.zx, tex), TRANSFORM_TEX(pos.xy, tex) };\
    TileInfo t0##tex = GetTileInfo(uv[0], tex##_TexelSize.zw);\
    TileInfo t1##tex = GetTileInfo(uv[1], tex##_TexelSize.zw);\
    TileInfo t2##tex = GetTileInfo(uv[2], tex##_TexelSize.zw);\
    SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(tex, tex, col)

    #define SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(tex, samplertex, col) \
    SAMPLE_TEX2DTILE_SAMPLER(tex, samplertex, uv[0], c0##col, t0##samplertex)\
    SAMPLE_TEX2DTILE_SAMPLER(tex, samplertex, uv[1], c1##col, t1##samplertex)\
    SAMPLE_TEX2DTILE_SAMPLER(tex, samplertex, uv[2], c2##col, t2##samplertex)\
    float4 col = c0##col * w.x + c1##col * w.y + c2##col * w.z;

    #define SAMPLE_TEX2DTILE_SAMPLER(tex, samplertex, coord, col, tileInfo) \
    float4 a##col = UNITY_SAMPLE_TEX2D_SAMPLER_LOD(tex, samplertex, coord + tileInfo.offa, tileInfo.mip);\
    float4 b##col = UNITY_SAMPLE_TEX2D_SAMPLER_LOD(tex, samplertex, coord + tileInfo.offb, tileInfo.mip);\
    float4 col = lerp(a##col, b##col, smoothstep(0.2, 0.8, tileInfo.f - 0.1 * sum(a##col - b##col)));

    inline float2 hash22(float2 p)
    {
        static const float2 k = float2(0.3183099, 0.3678794);
        p = p * k + k.yx;
        return frac(16.0 * k * frac(p.x * p.y * (p.x + p.y))) * 2.0 - 1.0;
    }

    float simplexNoise2D(float2 p)
    {
        const float K1 = 0.366025404;//(sqrt(3)-1)/2;
        const float K2 = 0.211324865;//(3-sqrt(3))/6;

        float2 i = floor(p + (p.x + p.y) * K1);
        float2 a = p - i + (i.x + i.y) * K2;
        float2 o = (a.x > a.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
        float2 b = a - o + K2;
        float2 c = a - 1.0 + 2.0 * K2;
        float3 h = max(0.5 - float3(dot(a, a), dot(b, b), dot(c, c) ), 0.0);
        float3 n = h * h * h * h * float3(dot(a, hash22(i)), dot(b, hash22(i + o)), dot(c, hash22(i + 1.0)));

        return (n.x + n.y + n.z) * 35.0 + 0.5;
    }

    inline float sum(float3 v)
    {
        return v.x + v.y + v.z;
    }

    inline float ComputeTextureLOD(float2 uvdx, float2 uvdy, float2 texelSize)
    {
        float2 ddx_ = texelSize * uvdx;
        float2 ddy_ = texelSize * uvdy;
        float  d = max(dot(ddx_, ddx_), dot(ddy_, ddy_));
        return max(0.5 * log2(d), 0.0);
    }

    inline TileInfo GetTileInfo(float2 uv, float2 texelSize)
    {
        TileInfo o;
        float k= simplexNoise2D(uv) * UNITY_ACCESS_INSTANCED_PROP(Props, _NoiseHeight);
        float i = floor(k);
        o.f = k - i;
        o.offa = sin(float2(3.0, 7.0) * (i + 0.0));
        o.offb = sin(float2(3.0, 7.0) * (i + 1.0));
        o.mip = ComputeTextureLOD(ddx(uv), ddy(uv), texelSize);
        return o;
    }

#endif
