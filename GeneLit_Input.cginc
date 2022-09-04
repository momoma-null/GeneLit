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
    #if defined(SHADING_MODEL_SUBSURFACE)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_SubsurfaceThicknessMap);
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
    UNITY_DEFINE_INSTANCED_PROP(half, _Anisotropy)
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfaceThickness)
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfacePower)
    UNITY_DEFINE_INSTANCED_PROP(half4, _SubsurfaceColor)
    UNITY_DEFINE_INSTANCED_PROP(half4, _ClothSubsurfaceColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoat)
    UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoatRoughness)
    UNITY_DEFINE_INSTANCED_PROP(half, _Thickness)
    UNITY_DEFINE_INSTANCED_PROP(half, _MicroThickness)
    UNITY_DEFINE_INSTANCED_PROP(half4, _TransmittanceColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _Transmission)
    UNITY_DEFINE_INSTANCED_PROP(half4, _SheenColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _SheenRoughness)
    UNITY_DEFINE_INSTANCED_PROP(half, _UVSec)
    UNITY_DEFINE_INSTANCED_PROP(half, _DetailAlbedoScale)
    UNITY_DEFINE_INSTANCED_PROP(half, _DetailNormalScale)
    UNITY_DEFINE_INSTANCED_PROP(half, _DetailSmoothnessScale)
    UNITY_DEFINE_INSTANCED_PROP(fixed, _SkyboxFog)
    UNITY_INSTANCING_BUFFER_END(Props)

    #include "GeneLit_NoTile.cginc"

    #define GENELIT_ACCESS_PROP(var) UNITY_ACCESS_INSTANCED_PROP(Props, var)

    struct MaterialInputs
    {
        float4 baseColor;
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
            float3 subsurfaceColor;
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

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            #if !defined(REFRACTION_TYPE_NONE)
                float thickness;
                float3 absorption;
                float transmission;
                #if defined(REFRACTION_TYPE_THIN)
                    float microThickness;
                #endif
            #endif
        #endif

        uint skyboxFog;
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
                float3 oViewDir = normalize(mul(shadingData.view, shadingData.tangentToWorld));
                float2 uvShift = oViewDir.xy / (oViewDir.z + 0.42) * GENELIT_ACCESS_PROP(_Parallax);
                float h1 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, uv).g;
                float shift1 = h1 * 0.5;
                float2 huv = uv - shift1 * uvShift;
                float h2 = 1.0 - UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxMap, _MainTex, huv).g;
                float a = (oViewDir.z + 0.42) * shift1 + 1e-4;
                float b = h2 - h1;
                float height = shift1 * (b + sqrt(max(0.0, b * b + 4 * a * h1))) / (2.0 * a);
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
        material.roughness = 1.0 - GENELIT_ACCESS_PROP(_Glossiness) * mods.a;
        #if !defined(SHADING_MODEL_CLOTH)
            material.metallic = GENELIT_ACCESS_PROP(_Metallic) * mods.r;
            material.reflectance = GENELIT_ACCESS_PROP(_Reflectance);
        #endif
        material.ambientOcclusion = GENELIT_ACCESS_PROP(_OcclusionStrength) * mods.g;

        #if defined(_NORMALMAP)
            #if defined(_TILEMODE_NO_TILE)
                SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(_BumpMap, _MainTex, normalMap)
            #else
                float4 normalMap = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, uv);
            #endif
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
        #if defined(_TILEMODE_NO_TILE)
            SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(_EmissionMap, _MainTex, emissive)
            material.emissive *= emissive;
        #else
            material.emissive *= UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv);
        #endif

        #if defined(_ALPHATEST_ON)
            material.maskThreshold = GENELIT_ACCESS_PROP(_Cutoff);
        #endif

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            #if defined(_SHEEN)
                material.sheenColor = GENELIT_ACCESS_PROP(_SheenColor).rgb;
                material.sheenRoughness = GENELIT_ACCESS_PROP(_SheenRoughness);
            #endif
        #endif

        #if defined(_ANISOTROPY)
            material.anisotropy = GENELIT_ACCESS_PROP(_Anisotropy);
            #if defined(_TILEMODE_NO_TILE)
                SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(_TangentMap, _MainTex, tangentMap)
            #else
                float4 tangentMap = UNITY_SAMPLE_TEX2D_SAMPLER(_TangentMap, _MainTex, uv);
            #endif
            material.anisotropyDirection = UnpackNormal(tangentMap);
        #endif

        #if defined(SHADING_MODEL_SUBSURFACE)
            #if defined(_TILEMODE_NO_TILE)
                SAMPLE_TEX2DTILE_SAMPLER_WIEGHT(_SubsurfaceThicknessMap, _MainTex, subsurfaceThickness)
            #else
                float4 subsurfaceThickness = UNITY_SAMPLE_TEX2D_SAMPLER(_SubsurfaceThicknessMap, _MainTex, uv);
            #endif
            material.subsurfaceThickness = subsurfaceThickness * GENELIT_ACCESS_PROP(_SubsurfaceThickness);
            material.subsurfacePower = GENELIT_ACCESS_PROP(_SubsurfacePower);
            material.subsurfaceColor = GENELIT_ACCESS_PROP(_SubsurfaceColor).rgb;
        #endif

        #if defined(SHADING_MODEL_CLOTH)
            material.sheenColor = sqrt(material.baseColor.rgb);
            material.subsurfaceColor = GENELIT_ACCESS_PROP(_ClothSubsurfaceColor).rgb;
        #endif

        #if defined(_CLEAR_COAT)
            material.clearCoat = GENELIT_ACCESS_PROP(_ClearCoat);
            material.clearCoatRoughness = GENELIT_ACCESS_PROP(_ClearCoatRoughness);
            #if defined(_CLEAR_COAT_NORMAL)
                material.clearCoatNormal = float3(0.0, 0.0, 1.0);
            #endif
        #endif

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            #if !defined(REFRACTION_TYPE_NONE)
                material.thickness = GENELIT_ACCESS_PROP(_Thickness);
                material.absorption = -log(GENELIT_ACCESS_PROP(_TransmittanceColor).rgb) / max(material.thickness, 1e-5);
                material.transmission = GENELIT_ACCESS_PROP(_Transmission);
                #if defined(REFRACTION_TYPE_THIN)
                    material.microThickness = GENELIT_ACCESS_PROP(_MicroThickness);
                #endif
            #endif
        #endif

        material.skyboxFog = GENELIT_ACCESS_PROP(_SkyboxFog);
    }
#endif
