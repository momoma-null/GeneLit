
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
// Punctual lights evaluation
//------------------------------------------------------------------------------

/**
* Returns a Light structure (see common_lighting.fs) describing a point or spot light.
* The colorIntensity field will store the *pre-exposed* intensity of the light
* in the w component.
*
* The light parameters used to compute the Light structure are fetched from the
* lightsUniforms uniform buffer.
*/

FilamentLight getLight(float3 worldPosition, float3 normal)
{
    // retrieve the light data from the UBO

    // poition-to-light vector
    float3 posToLight = _WorldSpaceLightPos0.xyz - worldPosition * _WorldSpaceLightPos0.w;

    // and populate the Light structure
    FilamentLight light;
    light.colorIntensity.rgb = _LightColor0.rgb;
    light.colorIntensity.w = 1;
    light.l = normalize(posToLight + float3(0, 1e-8, 0));
    light.attenuation = 1;
    light.NoL = saturate(dot(normal, light.l));
    #ifdef SPOT
        unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPosition, 1));
        light.attenuation *= UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
    #endif
    return light;
}

/**
* Evaluates all punctual lights that my affect the current fragment.
* The result of the lighting computations is accumulated in the color
* parameter, as linear HDR RGB.
*/
void evaluatePunctualLights(const MaterialInputs material, const PixelParams pixel, const ShadingData shadingData, inout float3 color)
{
    // Iterate point lights
    FilamentLight light = getLight(shadingData.position, shadingData.normal);

    float visibility = shadingData.atten;
    #if defined(SHADOWS_SCREEN) || defined(SHADOWS_DEPTH) || defined(SHADOWS_CUBE)
        if (light.NoL > 0.0)
        {
            if (false && visibility > 0.0)
            {
                //visibility *= 1.0 - screenSpaceContactShadow(light.l);
            }
        }
    #endif

    color.rgb += surfaceShading(pixel, light, shadingData, visibility);
}
