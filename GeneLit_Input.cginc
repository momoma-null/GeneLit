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
    #if !defined(GENELIT_GET_COMMON_COLOR_PARAMS)
        UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
        UNITY_DEFINE_INSTANCED_PROP(half, _Reflectance)
    #endif
    UNITY_DEFINE_INSTANCED_PROP(half, _OcclusionStrength)
    UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
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
    UNITY_DEFINE_INSTANCED_PROP(fixed, _SkyboxFog)
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

        uint skyboxFog;

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
        float2 ParallaxOffset2Step(float2 uv, half3 oViewDir)
        {
            float2 uvShift = oViewDir.xy / (oViewDir.z + 0.42) * GENELIT_ACCESS_PROP(_Parallax);
            float h1 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, uv).g;
            float shift1 = h1 * 0.5;
            float2 huv = uv - shift1 * uvShift;
            float h2 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, huv).g;
            float a = (oViewDir.z + 0.42) * shift1 + 1e-4;
            float b = h2 - h1;
            float height = shift1 * (b + sqrt(max(0.0, b * b + 4 * a * h1))) / (2.0 * a);
            return uv - uvShift * height;
        }
    #endif

    void initMaterial(ShadingData shadingData, inout MaterialInputs material)
    {
        float4 color = GENELIT_ACCESS_PROP(_Color);
        switch(GENELIT_ACCESS_PROP(_VertexColorMode))
        {
            case 1:material.baseColor *= color;break;
            case 2:material.baseColor += color;break;
            case 3:material.baseColor =  material.baseColor + color - material.baseColor * color;break;
            default:material.baseColor = color;break;
        }
        #if defined(_TILEMODE_NO_TILE)
            SAMPLE_TEX2DTILE_WIEGHT(_MainTex, baseColor, shadingData.position, shadingData.geometricNormal)
            material.baseColor *= baseColor;
        #else
            float2 uv = shadingData.uv.xy;
            #if defined(_PARALLAXMAP)
                half3 oViewDir = normalize(mul(shadingData.view, shadingData.tangentToWorld));
                uv = ParallaxOffset2Step(uv, oViewDir);
            #endif
            material.baseColor *= UNITY_SAMPLE_TEX2D(_MainTex, uv);
        #endif
        #if defined(_MASKMAP)
            GENELIT_SAMPLE_TEX2D_SAMPLER(_MaskMap, _MainTex, uv, mods)
        #else
            float4 mods = 1;
        #endif
        material.roughness = 1.0 - GENELIT_ACCESS_PROP(_Glossiness) * mods.a;
        #if !defined(GENELIT_GET_COMMON_COLOR_PARAMS)
            material.metallic = GENELIT_ACCESS_PROP(_Metallic) * mods.r;
            material.reflectance = GENELIT_ACCESS_PROP(_Reflectance);
        #endif
        material.ambientOcclusion = GENELIT_ACCESS_PROP(_OcclusionStrength) * mods.g;

        #if defined(_NORMALMAP)
            GENELIT_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, uv, normalMap)
            material.normal = UnpackScaleNormal(normalMap, GENELIT_ACCESS_PROP(_BumpScale));
        #else
            material.normal = float3(0.0, 0.0, 1.0);
        #endif

        #if defined(_BENTNORMALMAP)
            material.bentNormal = UnpackNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_BentNormalMap, _MainTex, uv));
        #endif

        #if defined(_DETAIL_MAP)
            float detailMask = mods.b;
            float2 detailUV = shadingData.uv.zw;
            float4 detailMap = UNITY_SAMPLE_TEX2D(_DetailMap, detailUV);
            float detailAlbedo = detailMap.r - 0.5;
            float detailSmoothness = detailMap.b - 0.5;
            float3 detailNormal = float3(detailMap.ag * 2.0 - 1.0, 0);

            float albedoDetailSpeed = saturate(abs(detailAlbedo) * GENELIT_ACCESS_PROP(_DetailAlbedoScale));
            float3 baseColorOverlay = lerp(sqrt(material.baseColor.rgb), (detailAlbedo < 0.0) ? float3(0.0, 0.0, 0.0) : float3(1.0, 1.0, 1.0), albedoDetailSpeed * albedoDetailSpeed);
            baseColorOverlay *= baseColorOverlay;
            material.baseColor.rgb = lerp(material.baseColor.rgb, saturate(baseColorOverlay), detailMask);

            float smoothness = 1.0 - material.roughness;
            float smoothnessDetailSpeed = saturate(abs(detailSmoothness) * GENELIT_ACCESS_PROP(_DetailSmoothnessScale));
            float smoothnessOverlay = lerp(smoothness, (detailSmoothness < 0.0) ? 0.0 : 1.0, smoothnessDetailSpeed);
            smoothness = lerp(smoothness, saturate(smoothnessOverlay), detailMask);
            material.roughness = 1.0 - smoothness;

            detailNormal.xy *= GENELIT_ACCESS_PROP(_DetailNormalScale);
            detailNormal.z = sqrt(saturate(1.0 - dot(detailNormal.xy, detailNormal.xy)));
            material.normal = lerp(material.normal, BlendNormals(material.normal, detailNormal), detailMask);
        #endif

        material.emissive = GENELIT_ACCESS_PROP(_EmissionColor);
        GENELIT_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv, emissive)
        material.emissive *= emissive;

        #if defined(_ALPHATEST_ON)
            material.maskThreshold = GENELIT_ACCESS_PROP(_Cutoff);
        #endif

        #if defined(USE_SHEEN)
            material.sheenColor = GENELIT_ACCESS_PROP(_SheenColor).rgb;
            material.sheenRoughness = GENELIT_ACCESS_PROP(_SheenRoughness);
        #endif

        #if defined(_ANISOTROPY)
            material.anisotropy = GENELIT_ACCESS_PROP(_Anisotropy);
            GENELIT_SAMPLE_TEX2D_SAMPLER(_TangentMap, _MainTex, uv, tangentMap)
            material.anisotropyDirection = UnpackNormal(tangentMap);
        #endif

        #if defined(_CLEAR_COAT)
            material.clearCoat = GENELIT_ACCESS_PROP(_ClearCoat);
            material.clearCoatRoughness = GENELIT_ACCESS_PROP(_ClearCoatRoughness);
            #if defined(_CLEAR_COAT_NORMAL)
                material.clearCoatNormal = float3(0.0, 0.0, 1.0);
            #endif
        #endif

        #if defined(USE_REFRACTION)
            material.thickness = GENELIT_ACCESS_PROP(_Thickness);
            material.absorption = -log(GENELIT_ACCESS_PROP(_TransmittanceColor).rgb) / max(material.thickness, 1e-5);
            material.transmission = GENELIT_ACCESS_PROP(_Transmission);
            #if defined(REFRACTION_TYPE_THIN)
                material.microThickness = GENELIT_ACCESS_PROP(_MicroThickness);
            #endif
        #endif

        material.skyboxFog = GENELIT_ACCESS_PROP(_SkyboxFog);

        #ifdef GENELIT_CUSTOM_INIT_MATERIAL
            GENELIT_CUSTOM_INIT_MATERIAL(material)
        #endif
    }
#endif
