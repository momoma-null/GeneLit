#ifndef FILAMENT_INPUT_INCLUDED
    #define FILAMENT_INPUT_INCLUDED

    #include "UnityCG.cginc"

    #define FILAMENT_QUALITY_LOW    0
    #define FILAMENT_QUALITY_NORMAL 1
    #define FILAMENT_QUALITY_HIGH   2

    UNITY_DECLARE_TEX2D(_MainTex);
    #if defined(_MASKMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_MaskMap);
    #endif
    #if defined(_NORMALMAP)
        UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
    #endif
    UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);

    float4 _MainTex_ST;

    UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
    UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
    UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
    UNITY_DEFINE_INSTANCED_PROP(half, _Glossiness)
    UNITY_DEFINE_INSTANCED_PROP(half, _OcclusionStrength)
    UNITY_DEFINE_INSTANCED_PROP(half, _IoR)
    UNITY_DEFINE_INSTANCED_PROP(half, _BumpScale)
    UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
    UNITY_DEFINE_INSTANCED_PROP(half4, _Anisotropy)
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfaceThickness)
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfacePower)
    UNITY_DEFINE_INSTANCED_PROP(half4, _SubsurfaceColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoat)
    UNITY_DEFINE_INSTANCED_PROP(half, _ClearCoatRoughness)
    UNITY_DEFINE_INSTANCED_PROP(half, _Thickness)
    UNITY_DEFINE_INSTANCED_PROP(half, _Absorption)
    UNITY_DEFINE_INSTANCED_PROP(half, _Transmission)
    UNITY_DEFINE_INSTANCED_PROP(half4, _SheenColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _SheenRoughness)
    UNITY_INSTANCING_BUFFER_END(Props)

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
            float ior;
            #if defined(_REFRACTION)
                float thickness;
                float3 absorption;
                float transmission;
                #if defined(MATERIAL_HAS_MICRO_THICKNESS) && (REFRACTION_TYPE == REFRACTION_TYPE_THIN)
                    float microThickness;
                #endif
            #endif
        #endif
    };

    void initMaterial(in float2 uv, out MaterialInputs material)
    {
        UNITY_INITIALIZE_OUTPUT(MaterialInputs, material);
        material.baseColor = UNITY_SAMPLE_TEX2D(_MainTex, uv) * UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
        #if defined(_MASKMAP)
            float4 mods = UNITY_SAMPLE_TEX2D_SAMPLER(_MaskMap, _MainTex, uv);
        #else
            float4 mods = 1;
        #endif
        material.roughness = 1.0 - UNITY_ACCESS_INSTANCED_PROP(Props, _Glossiness) * mods.a;
        #if !defined(SHADING_MODEL_CLOTH)
            material.metallic = UNITY_ACCESS_INSTANCED_PROP(Props, _Metallic) * mods.r;
            material.reflectance = 0.5;
        #endif
        material.ambientOcclusion = UNITY_ACCESS_INSTANCED_PROP(Props, _OcclusionStrength) * mods.g;
        material.emissive = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv) * UNITY_ACCESS_INSTANCED_PROP(Props, _EmissionColor);

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

        #if defined(_NORMALMAP)
            material.normal = UnpackNormalWithScale(UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, uv), UNITY_ACCESS_INSTANCED_PROP(Props, _BumpScale));
        #else
            material.normal = float3(0.0, 0.0, 1.0);
        #endif
        #if defined(MATERIAL_HAS_BENT_NORMAL)
            material.bentNormal = float3(0.0, 0.0, 1.0);
        #endif
        
        #if defined(_CLEAR_COAT)
            material.clearCoat = UNITY_ACCESS_INSTANCED_PROP(Props, _ClearCoat);
            material.clearCoatRoughness = UNITY_ACCESS_INSTANCED_PROP(Props, _ClearCoatRoughness);
            #if defined(_CLEAR_COAT_NORMAL)
                material.clearCoatNormal = float3(0.0, 0.0, 1.0);
            #endif
        #endif

        #if !defined(SHADING_MODEL_CLOTH) && !defined(SHADING_MODEL_SUBSURFACE)
            material.ior = UNITY_ACCESS_INSTANCED_PROP(Props, _IoR);
            #if defined(_REFRACTION)
                material.thickness = UNITY_ACCESS_INSTANCED_PROP(Props, _Thickness);
                material.absorption = UNITY_ACCESS_INSTANCED_PROP(Props, _Absorption);
                material.transmission = UNITY_ACCESS_INSTANCED_PROP(Props, _Transmission);
                #if defined(MATERIAL_HAS_MICRO_THICKNESS) && (REFRACTION_TYPE == REFRACTION_TYPE_THIN)
                    material.microThickness = 0.0;
                #endif
            #endif
        #endif
    }
#endif
