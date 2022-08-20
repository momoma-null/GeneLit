#ifndef FILAMENT_INPUT_INCLUDED
    #define FILAMENT_INPUT_INCLUDED

    #include "UnityCG.cginc"
    #include "UnityStandardUtils.cginc"
    #include "GeneLit_LightingCommon.cginc"

    #define FILAMENT_QUALITY_LOW    0
    #define FILAMENT_QUALITY_NORMAL 1
    #define FILAMENT_QUALITY_HIGH   2

    UNITY_DECLARE_TEX2D(_MainTex);
    float4 _MainTex_ST;
    float4 _MainTex_TexelSize;
    #if defined(_MASKMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_MaskMap);
    #endif
    #if defined(_NORMALMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
    #endif
    #if defined(_PARALLAXMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_ParallaxMap);
    #endif
    UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
    #if defined(_DETAIL_MULX2)
        UNITY_DECLARE_TEX2D(_DetailAlbedoMap);
        UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap);
        UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMaskMap);        
        float4 _DetailAlbedoMap_ST;
    #endif

    UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(half, _NoiseHeight)
    UNITY_DEFINE_INSTANCED_PROP(half, _VertexColorMode)
    UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
    UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
    UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
    UNITY_DEFINE_INSTANCED_PROP(half, _Glossiness)
    UNITY_DEFINE_INSTANCED_PROP(half, _OcclusionStrength)
    UNITY_DEFINE_INSTANCED_PROP(half, _Reflectance)
    UNITY_DEFINE_INSTANCED_PROP(half, _BumpScale)
    UNITY_DEFINE_INSTANCED_PROP(half, _Parallax)
    UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
    UNITY_DEFINE_INSTANCED_PROP(half4, _Anisotropy)
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfaceThickness)
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfacePower)
    UNITY_DEFINE_INSTANCED_PROP(half4, _SubsurfaceColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoat)
    UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoatRoughness)
    UNITY_DEFINE_INSTANCED_PROP(half, _Thickness)
    UNITY_DEFINE_INSTANCED_PROP(half, _MicroThickness)
    UNITY_DEFINE_INSTANCED_PROP(half4, _TransmittanceColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _Transmission)
    UNITY_DEFINE_INSTANCED_PROP(half4, _SheenColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _SheenRoughness)
    UNITY_DEFINE_INSTANCED_PROP(half, _UVSec)
    UNITY_DEFINE_INSTANCED_PROP(half, _DetailNormalMapScale)
    UNITY_DEFINE_INSTANCED_PROP(half, _DetailMetallic)
    UNITY_DEFINE_INSTANCED_PROP(half, _DetailGlossiness)
    UNITY_INSTANCING_BUFFER_END(Props)

    #include "GeneLit_NoTile.cginc"

    struct MaterialInputs
    {
        float4  baseColor;
        float roughness;
        #if !defined(SHADING_MODEL_CLOTH)
            float metallic;
            float reflectance;
        #endif
        float ambientOcclusion;
        float4 emissive;

        #if defined(_ALPHATEST_ON)
            float maskThreshold;
        #endif

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            #if defined(_SHEEN)
                float3 sheenColor;
                float sheenRoughness;
            #endif
        #endif

        #if defined(SHADING_MODEL_SUBSURFACE)
            float subsurfaceThickness;
            float subsurfacePower;
            float3 subsurfaceColor;
        #endif

        #if defined(_ANISOTROPY)
            float anisotropy;
            float3 anisotropyDirection;
        #endif

        #if defined(SHADING_MODEL_CLOTH)
            float3 sheenColor;
            #if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
                float3 subsurfaceColor;
            #endif
        #endif

        float3  normal;
        #if defined(MATERIAL_HAS_BENT_NORMAL)
            float3 bentNormal;
        #endif
        #if defined(_CLEAR_COAT)
            float clearCoat;
            float clearCoatRoughness;
            #if defined(_CLEAR_COAT_NORMAL)
                float3 clearCoatNormal;
            #endif
        #endif

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            #if defined(_REFRACTION)
                float thickness;
                float3 absorption;
                float transmission;
                #if defined(REFRACTION_TYPE_THIN)
                    float microThickness;
                #endif
            #endif
        #endif
    };

    void initMaterial(ShadingData shadingData, inout MaterialInputs material)
    {
        float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
        switch(UNITY_ACCESS_INSTANCED_PROP(Props, _VertexColorMode))
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
                float3 oViewDir = normalize(mul(shadingData.view, shadingData.tangentToWorld));
                float2 uvShift = oViewDir.xy / (oViewDir.z + 0.42) * UNITY_ACCESS_INSTANCED_PROP(Props, _Parallax);
                float h1 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, uv).g;
                float shift1 = h1 * 0.5;
                float2 huv = uv - shift1 * uvShift;
                float h2 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, huv).g;
                float a = (oViewDir.z + 0.42) * shift1 + 1e-4;
                float b = h2 - h1;
                float height = (b + sqrt(b * b + 4 * a * h1)) / a * shift1;
                uv -= uvShift * height;
            #endif
            material.baseColor *= UNITY_SAMPLE_TEX2D(_MainTex, uv);
        #endif
        #if defined(_MASKMAP)
            #if defined(_TILEMODE_NO_TILE)
                SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(_MaskMap, _MainTex, mods)
            #else
                float4 mods = UNITY_SAMPLE_TEX2D_SAMPLER(_MaskMap, _MainTex, uv);
            #endif
        #else
            float4 mods = 1;
        #endif
        material.roughness = 1.0 - UNITY_ACCESS_INSTANCED_PROP(Props, _Glossiness) * mods.a;
        #if !defined(SHADING_MODEL_CLOTH)
            material.metallic = UNITY_ACCESS_INSTANCED_PROP(Props, _Metallic) * mods.r;
            material.reflectance = UNITY_ACCESS_INSTANCED_PROP(Props, _Reflectance);
        #endif
        material.ambientOcclusion = UNITY_ACCESS_INSTANCED_PROP(Props, _OcclusionStrength) * mods.g;

        #if defined(_NORMALMAP)
            #if defined(_TILEMODE_NO_TILE)
                SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(_BumpMap, _MainTex, normalMap)
            #else
                float4 normalMap = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, uv);
            #endif
            material.normal = UnpackScaleNormal(normalMap, UNITY_ACCESS_INSTANCED_PROP(Props, _BumpScale));
        #else
            material.normal = float3(0.0, 0.0, 1.0);
        #endif
        #if defined(MATERIAL_HAS_BENT_NORMAL)
            material.bentNormal = float3(0.0, 0.0, 1.0);
        #endif

        #if defined(_DETAIL_MULX2)
            float2 uv2 = shadingData.uv.zw;
            float detailMask = mods.b;
            float3 detailAlbedo = UNITY_SAMPLE_TEX2D(_DetailAlbedoMap, uv2).rgb;
            material.baseColor.rgb *= lerp(1.0, detailAlbedo * unity_ColorSpaceDouble.rgb, detailMask);
            float4 detailMods = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMaskMap, _DetailAlbedoMap, uv2);
            material.roughness = lerp(material.roughness, 1.0 - UNITY_ACCESS_INSTANCED_PROP(Props, _DetailGlossiness) * detailMods.a, detailMask);
            #if !defined(SHADING_MODEL_CLOTH)
                material.metallic = lerp(material.metallic, UNITY_ACCESS_INSTANCED_PROP(Props, _DetailMetallic) * detailMods.r, detailMask);
            #endif
            material.ambientOcclusion = lerp(material.ambientOcclusion, detailMods.g, detailMask);
            half3 detailNormalTangent = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _DetailAlbedoMap, uv2), UNITY_ACCESS_INSTANCED_PROP(Props, _DetailNormalMapScale));
            material.normal = lerp(material.normal, BlendNormals(material.normal, detailNormalTangent), detailMask);
        #endif
        
        material.emissive = UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionColor);
        #if defined(_TILEMODE_NO_TILE)
            SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(_EmissionMap, _MainTex, emissive)
            material.emissive *= emissive;
        #else
            material.emissive *= UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv);
        #endif

        #if defined(_ALPHATEST_ON)
            material.maskThreshold = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutoff);
        #endif

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            #if defined(_SHEEN)
                material.sheenColor = UNITY_ACCESS_INSTANCED_PROP(Props, _SheenColor);
                material.sheenRoughness = UNITY_ACCESS_INSTANCED_PROP(Props, _SheenRoughness);
            #endif
        #endif

        #if defined(_ANISOTROPY)
            float4 anisotropy = UNITY_ACCESS_INSTANCED_PROP(Props, _Anisotropy);
            material.anisotropy = anisotropy.w;
            material.anisotropyDirection = anisotropy.xyz;
        #endif

        #if defined(SHADING_MODEL_SUBSURFACE)
            material.subsurfaceThickness = UNITY_ACCESS_INSTANCED_PROP(Props, _SubsurfaceThickness);
            material.subsurfacePower = UNITY_ACCESS_INSTANCED_PROP(Props, _SubsurfacePower);
            material.subsurfaceColor = UNITY_ACCESS_INSTANCED_PROP(Props, _SubsurfaceColor);
        #endif

        #if defined(SHADING_MODEL_CLOTH)
            material.sheenColor = sqrt(material.baseColor.rgb);
            #if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
                material.subsurfaceColor = UNITY_ACCESS_INSTANCED_PROP(Props, _SubsurfaceColor);
            #endif
        #endif

        #if defined(_CLEAR_COAT)
            material.clearCoat = UNITY_ACCESS_INSTANCED_PROP(Props, _ClearCoat);
            material.clearCoatRoughness = UNITY_ACCESS_INSTANCED_PROP(Props, _ClearCoatRoughness);
            #if defined(_CLEAR_COAT_NORMAL)
                material.clearCoatNormal = float3(0.0, 0.0, 1.0);
            #endif
        #endif

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            #if defined(_REFRACTION)
                material.thickness = UNITY_ACCESS_INSTANCED_PROP(Props, _Thickness);
                material.absorption = -log(UNITY_ACCESS_INSTANCED_PROP(Props, _TransmittanceColor).rgb) / max(material.thickness, 1e-5);
                material.transmission = UNITY_ACCESS_INSTANCED_PROP(Props, _Transmission);
                #if defined(REFRACTION_TYPE_THIN)
                    material.microThickness = UNITY_ACCESS_INSTANCED_PROP(Props, _MicroThickness);
                #endif
            #endif
        #endif
    }
#endif
