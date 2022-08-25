#ifndef FILAMENT_LIGHTING_COMMON_INCLUDED
    #define FILAMENT_LIGHTING_COMMON_INCLUDED

    struct FilamentLight
    {
        float4 colorIntensity;  // rgb, pre-exposed intensity
        float3 l;
        float  attenuation;
        float  NoL;
    };

    struct PixelParams
    {
        float3 diffuseColor;
        float  perceptualRoughness;
        float  perceptualRoughnessUnclamped;
        float3 f0;
        float  roughness;
        float3 dfg;
        float3 energyCompensation;
        float attenuation;

        #if defined(_CLEAR_COAT)
            float clearCoat;
            float clearCoatPerceptualRoughness;
            float clearCoatRoughness;
        #endif

        #if defined(_SHEEN)
            float3 sheenColor;
            #if !defined(SHADING_MODEL_CLOTH)
                float sheenRoughness;
                float sheenPerceptualRoughness;
                float sheenScaling;
                float sheenDFG;
            #endif
        #endif

        #if defined(_ANISOTROPY)
            float3 anisotropicT;
            float3 anisotropicB;
            float  anisotropy;
        #endif

        #if defined(SHADING_MODEL_SUBSURFACE)
            float subsurfaceThickness;
            float3 subsurfaceColor;
            float  subsurfacePower;
        #endif

        #if defined(SHADING_MODEL_CLOTH) && defined(MATERIAL_HAS_SUBSURFACE_COLOR)
            float3 subsurfaceColor;
        #endif

        #if defined(_REFRACTION)
            float thickness;
            float  etaRI;
            float  etaIR;
            float  transmission;
            float  uThickness;
            float3 absorption;
        #endif
    };

    struct ShadingData
    {
        // These variables should be in a struct but some GPU drivers ignore the
        // precision qualifier on individual struct members
        float3x3 tangentToWorld;   // TBN matrix
        float3   position;         // position of the fragment in world space
        float3   view;             // normalized vector from the fragment to the eye
        float3   normal;           // normalized transformed normal, in world space
        float3   geometricNormal;  // normalized geometric normal, in world space
        float3   reflected;        // reflection of view about normal
        float    NoV;              // dot(normal, view), always strictly >= MIN_N_DOT_V

        #if defined(_BENTNORMALMAP)
            float3 bentNormal;       // normalized transformed normal, in world space
        #endif

        #if defined(_CLEAR_COAT_NORMAL)
            float3 clearCoatNormal;  // normalized clear coat layer normal, in world space
        #endif

        float2 normalizedViewportCoord;
        half3 ambient;
        half4 lightmapUV;
        #if defined(_DETAIL_MAP)
            float4 uv;
        #else
            float2 uv;
        #endif
    };

    float computeMicroShadowing(float NoL, float visibility)
    {
        // Chan 2018, "Material Advances in Call of Duty: WWII"
        float aperture = rsqrt(1.001 - visibility);
        float microShadow = saturate(NoL * aperture);
        return microShadow * microShadow;
    }
#endif
