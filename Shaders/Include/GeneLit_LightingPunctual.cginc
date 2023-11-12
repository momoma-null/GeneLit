
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
    light.attenuation = shadingData.atten;
    light.NoL = saturate(dot(shadingData.normal, light.l));
    return light;
}

void getVertexPunctualLights(const ShadingData shadingData, float4 lightAttenSq, out FilamentLight lights[4])
{
    // to light vectors
    float3 pos = shadingData.position;
    float4 toLightX = unity_4LightPosX0 - pos.x;
    float4 toLightY = unity_4LightPosY0 - pos.y;
    float4 toLightZ = unity_4LightPosZ0 - pos.z;
    // squared lengths
    float4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;
    // don't produce NaNs if some vertex position overlaps with the light
    lengthSq = max(lengthSq, 0.000001);
    // NdotL
    float4 ndotl = 0;
    float3 normal = shadingData.normal;
    ndotl += toLightX * normal.x;
    ndotl += toLightY * normal.y;
    ndotl += toLightZ * normal.z;
    // correct NdotL
    float4 corr = rsqrt(lengthSq);
    ndotl = saturate(ndotl * corr);
    // attenuation
    float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);

    FilamentLight light0, light1, light2, light3;
    
    light0.colorIntensity = float4(unity_LightColor[0].rgb, 1);
    light0.l = normalize(float3(toLightX[0], toLightY[0], toLightZ[0]) + float3(0, 1e-8, 0));
    light0.attenuation = atten[0];
    light0.NoL = ndotl[0];

    light1.colorIntensity = float4(unity_LightColor[1].rgb, 1);
    light1.l = normalize(float3(toLightX[1], toLightY[1], toLightZ[1]) + float3(0, 1e-8, 0));
    light1.attenuation = atten[1];
    light1.NoL = ndotl[1];
    
    light2.colorIntensity = float4(unity_LightColor[2].rgb, 1);
    light2.l = normalize(float3(toLightX[2], toLightY[2], toLightZ[2]) + float3(0, 1e-8, 0));
    light2.attenuation = atten[2];
    light2.NoL = ndotl[2];
    
    light3.colorIntensity = float4(unity_LightColor[3].rgb, 1);
    light3.l = normalize(float3(toLightX[3], toLightY[3], toLightZ[3]) + float3(0, 1e-8, 0));
    light3.attenuation = atten[3];
    light3.NoL = ndotl[3];

    lights[0] = light0;
    lights[1] = light1;
    lights[2] = light2;
    lights[3] = light3;
}
