#ifndef GENELIT_LIGHTING_COMMON_INCLUDED
    #define GENELIT_LIGHTING_COMMON_INCLUDED

    #if defined(_DETAIL_MAP)
        #define UVCoord float4
    #else
        #define UVCoord float2
    #endif

    struct FilamentLight
    {
        float4 colorIntensity;  // rgb, diffuse strength
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
        float pseudoAmbient;

        #if defined(_CLEAR_COAT)
            float clearCoat;
            float clearCoatPerceptualRoughness;
            float clearCoatRoughness;
        #endif

        #if defined(USE_SHEEN)
            float3 sheenColor;
            float sheenRoughness;
            float sheenPerceptualRoughness;
            float sheenScaling;
            float sheenDFG;
        #endif

        #if defined(_ANISOTROPY)
            float3 anisotropicT;
            float3 anisotropicB;
            float  anisotropy;
        #endif

        #if defined(USE_REFRACTION)
            float thickness;
            float  etaRI;
            float  etaIR;
            float  transmission;
            float  uThickness;
            float3 absorption;
        #endif

        #ifdef GENELIT_CUSTOM_PIXEL_PARAMS
            GENELIT_CUSTOM_PIXEL_PARAMS
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
        float atten;
        half3 ambient;
        half4 lightmapUV;
        UVCoord uv;

        #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
            fixed4 bakedDir;
        #endif

        bool useDirectionalLightEstimation;
    };

    float computeMicroShadowing(float NoL, float visibility)
    {
        // Chan 2018, "Material Advances in Call of Duty: WWII"
        float aperture = rsqrt(1.001 - visibility);
        float microShadow = saturate(NoL * aperture);
        return microShadow * microShadow;
    }
#endif
