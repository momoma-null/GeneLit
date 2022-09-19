
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
        #if UNITY_SHOULD_SAMPLE_SH && !defined(_DIRECTIONALLIGHTESTIMATION_OFF)
            light.l = normalize(unity_SHAr.rgb * unity_ColorSpaceLuminance.r + unity_SHAg.rgb * unity_ColorSpaceLuminance.g + unity_SHAb.rgb * unity_ColorSpaceLuminance.b + float3(0, 1e-8, 0));
            light.colorIntensity = float4(saturate(SHEvalLinearL0L1(half4(light.l, 1))), 1);
        #elif defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
            fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, shadingData.lightmapUV.xy);
            light.l = normalize(bakedDirTex.xyz - 0.5);
            // bakedDirTex.w, which may be length from light, is not considered.
            light.colorIntensity = float4(saturate(shadingData.ambient), 1);
        #else
            light.l = float3(0, 1, 0);
            light.colorIntensity = 0;
        #endif
    }
    light.attenuation = 1.0;
    light.NoL = saturate(dot(shadingData.normal, light.l));
    return light;
}
