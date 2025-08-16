
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "UnityLightingCommon.cginc"
#include "GeneLit_LightingCommon.cginc"
#include "GeneLit_Utils.cginc"

//------------------------------------------------------------------------------
// Directional light evaluation
//------------------------------------------------------------------------------

FilamentLight getDirectionalLight(const ShadingData shadingData)
{
    FilamentLight light;
    UNITY_BRANCH
    if(sum(_LightColor0.rgb) > 1e-6)
    {
        light.colorIntensity = float4(_LightColor0.rgb, 1);
        light.l = normalize(_WorldSpaceLightPos0.xyz + float3(0, 1e-8, 0));
    }
    else
    {
        #if UNITY_SHOULD_SAMPLE_SH
            light.l = normalize(unity_SHAr.rgb * unity_ColorSpaceLuminance.r + unity_SHAg.rgb * unity_ColorSpaceLuminance.g + unity_SHAb.rgb * unity_ColorSpaceLuminance.b + float3(0, 1e-8, 0));
            light.colorIntensity = float4(SHEvalLinearL0L1(half4(light.l, 1)), 0) * shadingData.directionalLightEstimation;
        #elif defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
            fixed4 bakedDirTex = shadingData.bakedDir;
            light.l = normalize(bakedDirTex.xyz - 0.5);
            light.colorIntensity = float4(shadingData.ambient / max(1e-4h, bakedDirTex.w), 0) * shadingData.directionalLightEstimation;
        #else
            light.l = float3(0, 1, 0);
            light.colorIntensity = 0;
        #endif
    }
    light.attenuation = 1.0;
    light.NoL = saturate(dot(shadingData.normal, light.l));
    return light;
}
