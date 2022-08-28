
#include "AutoLight.cginc"
#include "UnityLightingCommon.cginc"
#include "GeneLit_LightingCommon.cginc"

//------------------------------------------------------------------------------
// Punctual lights
//------------------------------------------------------------------------------

FilamentLight getPunctualLights(const ShadingData shadingData)
{
    // retrieve the light data from the UBO

    // poition-to-light vector
    float3 posToLight = _WorldSpaceLightPos0.xyz - shadingData.position * _WorldSpaceLightPos0.w;

    // and populate the Light structure
    FilamentLight light;
    light.colorIntensity = float4(_LightColor0.rgb, 1);
    light.l = normalize(posToLight + float3(0, 1e-8, 0));
    light.attenuation = 1;
    light.NoL = saturate(dot(shadingData.normal, light.l));
    return light;
}
