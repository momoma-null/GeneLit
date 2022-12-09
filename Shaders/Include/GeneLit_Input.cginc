#ifndef GENELIT_INPUT_INCLUDED
    #define GENELIT_INPUT_INCLUDED

    #include "UnityCG.cginc"
    #include "UnityStandardUtils.cginc"
    #include "GeneLit_LightingCommon.cginc"

    #define FILAMENT_QUALITY_LOW    0
    #define FILAMENT_QUALITY_NORMAL 1
    #define FILAMENT_QUALITY_HIGH   2

    #if defined(_TILEMODE_NO_TILE) && defined(_BENTNORMALMAP)
        #undef _BENTNORMALMAP
    #endif

    UNITY_DECLARE_TEX2D(_MainTex);
    float4 _MainTex_ST;
    float4 _MainTex_TexelSize;
    #if defined(_MASKMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_MaskMap);
    #endif
    #if defined(_NORMALMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
    #endif
    #if defined(_BENTNORMALMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_BentNormalMap);
    #endif
    #if defined(_PARALLAXMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_ParallaxMap);
    #endif
    UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
    #if defined(_ANISOTROPY)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_TangentMap);
    #endif
    #if defined(_DETAIL_MAP)
        UNITY_DECLARE_TEX2D(_DetailMap);
        float4 _DetailMap_ST;
    #endif

    UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(half, _NoiseHeight)
    UNITY_DEFINE_INSTANCED_PROP(half, _VertexColorMode)
    #if defined(_PARALLAXMAP)
        UNITY_DEFINE_INSTANCED_PROP(half, _Parallax)
    #endif
    UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
    UNITY_DEFINE_INSTANCED_PROP(half, _Glossiness)
    #if defined(USE_METALLIC)
        UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
        UNITY_DEFINE_INSTANCED_PROP(half, _Reflectance)
    #endif
    UNITY_DEFINE_INSTANCED_PROP(half, _OcclusionStrength)
    UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
    UNITY_DEFINE_INSTANCED_PROP(fixed, _AlbedoAffectEmissive)
    #if defined(_ALPHATEST_ON)
        UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
    #endif
    #if defined(USE_SHEEN)
        UNITY_DEFINE_INSTANCED_PROP(half4, _SheenColor)
        UNITY_DEFINE_INSTANCED_PROP(half, _SheenRoughness)
    #endif
    #if defined(_ANISOTROPY)
        UNITY_DEFINE_INSTANCED_PROP(half, _Anisotropy)
    #endif
    UNITY_DEFINE_INSTANCED_PROP(half, _BumpScale)
    #if defined(_CLEAR_COAT)
        UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoat)
        UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoatRoughness)
    #endif
    #if defined(USE_REFRACTION)
        UNITY_DEFINE_INSTANCED_PROP(half, _Thickness)
        UNITY_DEFINE_INSTANCED_PROP(half4, _TransmittanceColor)
        UNITY_DEFINE_INSTANCED_PROP(half, _Transmission)
        #if defined(REFRACTION_TYPE_THIN)
            UNITY_DEFINE_INSTANCED_PROP(half, _MicroThickness)
        #endif
    #endif
    #if defined(_DETAIL_MAP)
        UNITY_DEFINE_INSTANCED_PROP(half, _UVSec)
        UNITY_DEFINE_INSTANCED_PROP(half, _DetailAlbedoScale)
        UNITY_DEFINE_INSTANCED_PROP(half, _DetailNormalScale)
        UNITY_DEFINE_INSTANCED_PROP(half, _DetailSmoothnessScale)
    #endif
    #if defined(CAPSULE_AO)
        UNITY_DEFINE_INSTANCED_PROP(fixed, _Capsule_AOStrength)
        UNITY_DEFINE_INSTANCED_PROP(fixed, _Capsule_ShadowStrength)
    #endif
    UNITY_DEFINE_INSTANCED_PROP(fixed, _SkyboxFog)
    UNITY_DEFINE_INSTANCED_PROP(fixed, _DirectionalLightEstimation)
    #ifdef GENELIT_CUSTOM_INSTANCED_PROP
        GENELIT_CUSTOM_INSTANCED_PROP
    #endif
    UNITY_INSTANCING_BUFFER_END(Props)

    #include "GeneLit_NoTile.cginc"

    #define GENELIT_ACCESS_PROP(var) UNITY_ACCESS_INSTANCED_PROP(Props, var)

    #if defined(_TILEMODE_NO_TILE)
        #define GENELIT_SAMPLE_TEX2D_SAMPLER(tex, samplertex, uv, col) SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(tex, samplertex, col)
    #else
        #define GENELIT_SAMPLE_TEX2D_SAMPLER(tex, samplertex, uv, col) float4 col = UNITY_SAMPLE_TEX2D_SAMPLER(tex, samplertex, uv);
    #endif

    struct MaterialInputs
    {
        float4 baseColor;
        float roughness;
        #if !defined(GENELIT_GET_COMMON_COLOR_PARAMS)
            float metallic;
            float reflectance;
        #endif
        float ambientOcclusion;
        float4 emissive;

        #if defined(_ALPHATEST_ON)
            float maskThreshold;
        #endif

        #if defined(USE_SHEEN)
            float3 sheenColor;
            float sheenRoughness;
        #endif

        #if defined(_ANISOTROPY)
            float anisotropy;
            float3 anisotropyDirection;
        #endif

        float3  normal;
        #if defined(_BENTNORMALMAP)
            float3 bentNormal;
        #endif

        #if defined(_CLEAR_COAT)
            float clearCoat;
            float clearCoatRoughness;
            #if defined(_CLEAR_COAT_NORMAL)
                float3 clearCoatNormal;
            #endif
        #endif

        #if defined(USE_REFRACTION)
            float thickness;
            float3 absorption;
            float transmission;
            #if defined(REFRACTION_TYPE_THIN)
                float microThickness;
            #endif
        #endif

        #if defined(CAPSULE_AO)
            float capsuleAOStrength;
            float capsuleShadowStrength;
        #endif

        uint skyboxFog;
        bool directionalLightEstimation;

        #ifdef GENELIT_CUSTOM_MATERIAL_INPUTS
            GENELIT_CUSTOM_MATERIAL_INPUTS
        #endif
    };

    UVCoord TexCoords(appdata_full v)
    {
        UVCoord uv = 0;
        uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
        #if defined(_DETAIL_MAP)
            UNITY_BRANCH
            switch(GENELIT_ACCESS_PROP(_UVSec))
            {
                case 0: uv.zw = TRANSFORM_TEX(v.texcoord, _DetailMap); break;
                case 1: uv.zw = TRANSFORM_TEX(v.texcoord1, _DetailMap); break;
                case 2: uv.zw = TRANSFORM_TEX(v.texcoord2, _DetailMap); break;
                case 3: uv.zw = TRANSFORM_TEX(v.texcoord3, _DetailMap); break;
            }
        #endif
        return uv;
    }

    #if defined(_PARALLAXMAP)
        float4 parallaxCache;

        float2 ParallaxOffset2Step(float2 uv, half3 oViewDir)
        {
            float maxHeight = GENELIT_ACCESS_PROP(_Parallax);
            float2 uvShift = oViewDir.xy / (oViewDir.z + 0.42) * maxHeight;
            float h1 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, uv).g;
            float shift1 = h1 * 0.5;
            float2 huv = uv - shift1 * uvShift;
            float h2 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, huv).g;
            float a = (oViewDir.z + 0.42) * shift1 + 1e-4;
            float b = h2 - h1;
            float height = shift1 * (b + sqrt(max(0.0, b * b + 4 * a * h1))) / (2.0 * a);
            parallaxCache = float4(height, maxHeight, uvShift);
            return uv - uvShift * height;
        }
    #endif

    float computeHeightMapShadowing(const ShadingData shadingData, const FilamentLight light)
    {
        #if defined(_PARALLAXMAP)
            float h1 = parallaxCache.x;
            float3 oLitDir = normalize(mul(light.l, shadingData.tangentToWorld));
            float2 uvShift = oLitDir.xy / (oLitDir.z + 0.1) * parallaxCache.y * h1;
            uvShift -= parallaxCache.zw * h1;
            float h2 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, shadingData.uv + uvShift).g;
            return 1.0 - saturate((h1 - h2) * 10);
        #else
            return 1.0;
        #endif
    }
#endif
