
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityLightingCommon.cginc"
#include "GeneLit_LightingCommon.cginc"

#if defined(SHADING_MODEL_SUBSURFACE)
    #include "GeneLit_Model_Subsurface.cginc"
#elif defined(SHADING_MODEL_CLOTH)
    #include "GeneLit_Model_Cloth.cginc"
#else
    #include "GeneLit_Model_Standard.cginc"
#endif

//------------------------------------------------------------------------------
// Directional light evaluation
//------------------------------------------------------------------------------

#if FILAMENT_QUALITY < FILAMENT_QUALITY_HIGH
    #define SUN_AS_AREA_LIGHT
#endif

float3 sampleSunAreaLight(const float3 lightDirection) {
    #if defined(SUN_AS_AREA_LIGHT)
        if (frameUniforms.sun.w >= 0.0) {
            // simulate sun as disc area light
            float LoR = dot(lightDirection, shading_reflected);
            float d = frameUniforms.sun.x;
            float3 s = shading_reflected - LoR * lightDirection;
            return LoR < d ?
            normalize(lightDirection * d + normalize(s) * frameUniforms.sun.y) : shading_reflected;
        }
    #endif
    return lightDirection;
}

FilamentLight getDirectionalLight(const float3 n)
{
    FilamentLight light;
    light.colorIntensity = float4(_LightColor0.rgb, 1);
    light.l = sampleSunAreaLight(normalize(_WorldSpaceLightPos0.xyz + float3(0, 1e-8, 0)));
    light.attenuation = 1.0;
    light.NoL = saturate(dot(n, light.l));
    return light;
}

void evaluateDirectionalLight(const MaterialInputs material, const PixelParams pixel, const ShadingData shadingData, inout float3 color)
{
    FilamentLight light = getDirectionalLight(shadingData.normal);

    float visibility = shadingData.atten;
    visibility *= computeMicroShadowing(light.NoL, material.ambientOcclusion);

    color.rgb += surfaceShading(pixel, light, shadingData, visibility);
}
