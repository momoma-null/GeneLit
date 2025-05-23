#ifndef GENELIT_LIGHTING_INDIRECT_INCLUDED
#define GENELIT_LIGHTING_INDIRECT_INCLUDED

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityGlobalIllumination.cginc"
#include "GeneLit_LightingCommon.cginc"
#include "GeneLit_Brdf.cginc"
#include "GeneLit_AmbientOcclusion.cginc"

#if defined(LTCGI)
    #include "Packages/at.pimaker.ltcgi/Shaders/LTCGI.cginc"
#endif

#if defined(LIGHTVOLUMES)
    #include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"
    float3 L0, L1r, L1g, L1b;
#endif

//------------------------------------------------------------------------------
// Image based lighting configuration
//------------------------------------------------------------------------------

UNITY_DECLARE_TEX2D(_DFG);

//------------------------------------------------------------------------------
// IBL prefiltered DFG term implementations
//------------------------------------------------------------------------------

float3 PrefilteredDFG_LUT(float lod, float NoV)
{
    // coord = sqrt(linear_roughness), which is the mapping used by cmgen.
    return UNITY_SAMPLE_TEX2D_LOD(_DFG, float2(NoV, lod), 0).rgb;
}

//------------------------------------------------------------------------------
// IBL environment BRDF dispatch
//------------------------------------------------------------------------------

float3 prefilteredDFG(float perceptualRoughness, float NoV)
{
    // PrefilteredDFG_LUT() takes a LOD, which is sqrt(roughness) = perceptualRoughness
    return PrefilteredDFG_LUT(perceptualRoughness, NoV);
}

//------------------------------------------------------------------------------
// IBL irradiance dispatch
//------------------------------------------------------------------------------

float3 diffuseIrradiance(const float3 normalWorld, const ShadingData shadingData)
{
    float3 irradiance = shadingData.ambient;

    #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
        irradiance = DecodeDirectionalLightmap(irradiance, shadingData.bakedDir, normalWorld);
    #endif

    #if defined(LIGHTVOLUMES)
        irradiance += LightVolumeEvaluate(normalWorld, L0, L1r, L1g, L1b);
    #elif UNITY_SHOULD_SAMPLE_SH
        irradiance = ShadeSHPerPixel(normalWorld, irradiance, shadingData.position);
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        // Dynamic lightmaps
        fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, shadingData.lightmapUV.zw);
        half3 realtimeColor = DecodeRealtimeLightmap(realtimeColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, shadingData.lightmapUV.zw);
            irradiance += DecodeDirectionalLightmap(realtimeColor, realtimeDirTex, normalWorld);
        #else
            irradiance += realtimeColor;
        #endif
    #endif

    return irradiance;
}

//------------------------------------------------------------------------------
// IBL specular
//------------------------------------------------------------------------------

inline float4 cylIntersect(float3 ro, float3 rd, float3 c, float pMin, float pMax, float ra)
{
    float2 ho = ro.xz - c.xz;
    float rdl = length(rd.xz);
    float b = dot(ho, rd.xz / rdl);
    float d = b * b + ra * ra - dot(ho, ho);
    float k = (-b + sqrt(max(d, 0.0))) / rdl;
    float rbmax = (pMax - ro.y) / rd.y;
    float rbmin = (pMin - ro.y) / rd.y;
    k = min(k, (rd.y > 0.0f) ? rbmax : rbmin);
    return d < 0 ? - 1.0 : float4(k * rd + ro, 1);
}

inline float3 CylinderProjectedCubemapDirection(float3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
{
    UNITY_BRANCH
    if (cubemapCenter.w > 0.0)
    {
        float3 nrdir = normalize(worldRefl);
        float r = min(min(abs(boxMin.x - cubemapCenter.x), abs(boxMin.z - cubemapCenter.z)), min(abs(boxMax.x - cubemapCenter.x), abs(boxMax.z - cubemapCenter.z)));
        float4 intersectPos = cylIntersect(worldPos, nrdir, cubemapCenter.xyz, boxMin.y, boxMax.y, r);
        worldRefl = intersectPos.w > 0 ? (intersectPos.xyz - cubemapCenter.xyz) : nrdir;
    }
    return worldRefl;
}

#if defined(REFLECTION_SPACE_ADDITIONAL_BOX)

    #define ADDITIONAL_BOX_COUNT 4

    float4 _UdonAdditionalBoxPosition[ADDITIONAL_BOX_COUNT];
    float4 _UdonAdditionalBoxRotation[ADDITIONAL_BOX_COUNT];
    float4 _UdonAdditionalBoxSize[ADDITIONAL_BOX_COUNT];

    inline float4 mulQuaternion(float4 q1, float4 q2)
    {
        return float4(cross(q1.xyz, q2.xyz) + q2.w * q1.xyz + q1.w * q2.xyz, q1.w * q2.w - dot(q1.xyz, q2.xyz));
    }

    inline float3 mulQuaternion(float4 q, float3 v)
    {
        float4 iq = float4(-q.xyz, q.w);
        return mulQuaternion(q, mulQuaternion(float4(v, 0), iq)).xyz;
    }

    inline float boxIntersect(float3 ro, float3 rd, float3 size, float3 pos, float4 rot)
    {
        rot = float4(-rot.xyz, rot.w);
        ro = mulQuaternion(rot, ro - pos);
        rd = mulQuaternion(rot, rd);
        float3 m = 1.0 / rd;
        float3 n = m * ro;
        float3 k = abs(m) * size * 0.5;
        float3 t1 = -n - k;
        float3 t2 = -n + k;
        float tN = max(max(t1.x, t1.y), t1.z);
        float tF = min(min(t2.x, t2.y), t2.z);
        return (tN > tF || tF < 0.0) ? 1e10 : tN;
    }

    inline float3 AdditionalBoxProjectedCubemapDirection(float3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
    {
        UNITY_BRANCH
        if (cubemapCenter.w > 0.0)
        {
            float3 nrdir = normalize(worldRefl);
            float3 rbmax = (boxMax.xyz - worldPos) / nrdir;
            float3 rbmin = (boxMin.xyz - worldPos) / nrdir;

            float3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;

            float fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);

            UNITY_UNROLL
            for (uint i = 0; i < ADDITIONAL_BOX_COUNT; ++i)
            {
                float tN = boxIntersect(worldPos, nrdir, _UdonAdditionalBoxSize[i].xyz, _UdonAdditionalBoxPosition[i].xyz, _UdonAdditionalBoxRotation[i]);
                fa = min(fa, tN);
            }

            worldPos -= cubemapCenter.xyz;
            worldRefl = worldPos + nrdir * fa;
        }
        return worldRefl;
    }
#endif

#if defined(REFLECTION_SPACE_CYLINDER)
    #define GENELIT_PROJECTED_DIRECTION CylinderProjectedCubemapDirection
#elif defined(REFLECTION_SPACE_ADDITIONAL_BOX)
    #define GENELIT_PROJECTED_DIRECTION AdditionalBoxProjectedCubemapDirection
#else
    #define GENELIT_PROJECTED_DIRECTION BoxProjectedCubemapDirection
#endif

inline half3 indirectSpecular(float3 r, float lod, float3 worldPos)
{
    half3 specular;

    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        float3 refDir = GENELIT_PROJECTED_DIRECTION(r, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
    #else
        float3 refDir = r;
    #endif

    #ifdef _GLOSSYREFLECTIONS_OFF
        specular = unity_IndirectSpecColor.rgb;
    #else
        half3 env0 = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, refDir, lod), unity_SpecCube0_HDR);
        #ifdef UNITY_SPECCUBE_BLENDING
            const float kBlendFactor = 0.99999;
            float blendLerp = unity_SpecCube0_BoxMin.w;
            UNITY_BRANCH
            if (blendLerp < kBlendFactor)
            {
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                    refDir = BoxProjectedCubemapDirection(r, worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                #else
                    refDir = r;
                #endif

                half3 env1 = DecodeHDR(UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, refDir, lod), unity_SpecCube1_HDR);
                specular = lerp(env1, env0, blendLerp);
            }
            else
            {
                specular = env0;
            }
        #else
            specular = env0;
        #endif
    #endif

    return specular;
}

#if defined(LIGHTVOLUMES)
    float3 LightVolumeSpecular_GeneLit(float3 f0, float perceptualRoughness, float3 worldNormal, float3 viewDir, float3 L0, float3 L1r, float3 L1g, float3 L1b)
    {
        float3 specColor = max(float3(dot(reflect(-L1r, worldNormal), viewDir), dot(reflect(-L1g, worldNormal), viewDir), dot(reflect(-L1b, worldNormal), viewDir)), 0);

        float3 rDir = LV_Normalize(LV_Normalize(L1r) + viewDir);
        float3 gDir = LV_Normalize(LV_Normalize(L1g) + viewDir);
        float3 bDir = LV_Normalize(LV_Normalize(L1b) + viewDir);

        float rNh = saturate(dot(worldNormal, rDir));
        float gNh = saturate(dot(worldNormal, gDir));
        float bNh = saturate(dot(worldNormal, bDir));

        float roughExp = perceptualRoughness * perceptualRoughness;

        float rSpec = LV_DistributionGGX(rNh, roughExp);
        float gSpec = LV_DistributionGGX(gNh, roughExp);
        float bSpec = LV_DistributionGGX(bNh, roughExp);

        float3 specs = (rSpec + gSpec + bSpec) * f0;
        float3 coloredSpecs = specs * specColor;

        float3 a = coloredSpecs + specs * L0;
        float3 b = coloredSpecs * 4;

        return max(lerp(b, a, perceptualRoughness), 0.0);
    }

    float3 LightVolumeSpecularDominant_GeneLit(float3 f0, float perceptualRoughness, float3 worldNormal, float3 viewDir, float3 L0, float3 L1r, float3 L1g, float3 L1b)
    {
        float3 dominantDir = L1r + L1g + L1b;
        float3 dir = LV_Normalize(LV_Normalize(dominantDir) + viewDir);
        float nh = saturate(dot(worldNormal, dir));

        float roughExp = perceptualRoughness * perceptualRoughness;

        float spec = LV_DistributionGGX(nh, roughExp);

        return max(spec * L0 * f0, 0.0) * 2;
    }
#endif

float3 additiveSpecular(const PixelParams pixel, const ShadingData shadingData)
{
    #if defined(LIGHTVOLUMES)
        #if defined(LIGHTMAP_ON)
            return LightVolumeSpecularDominant_GeneLit(pixel.f0, pixel.perceptualRoughness, shadingData.normal, shadingData.view, L0, L1r, L1g, L1b);
        #else
            return LightVolumeSpecular_GeneLit(pixel.f0, pixel.perceptualRoughness, shadingData.normal, shadingData.view, L0, L1r, L1g, L1b);
        #endif
    #else
        return 0;
    #endif
}

inline float perceptualRoughnessToLod(float perceptualRoughness)
{
    // The mapping below is a quadratic fit for log2(perceptualRoughness)+iblRoughnessOneLevel when
    // iblRoughnessOneLevel is 4. We found empirically that this mapping works very well for
    // a 256 cubemap with 5 levels used. But also scales well for other iblRoughnessOneLevel values.
    return UNITY_SPECCUBE_LOD_STEPS * perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
}

inline half3 prefilteredRadiance(const float3 r, float perceptualRoughness, float3 worldPos)
{
    float lod = perceptualRoughnessToLod(perceptualRoughness);
    return indirectSpecular(r, lod, worldPos);
}

inline half3 prefilteredRadiance(const float3 r, float roughness, float offset, float3 worldPos)
{
    float lod = UNITY_SPECCUBE_LOD_STEPS * roughness;
    return indirectSpecular(r, lod + offset, worldPos);
}

inline float3 getSpecularDominantDirection(const float3 n, const float3 r, float roughness)
{
    return lerp(r, n, roughness * roughness);
}

inline float3 specularDFG(const PixelParams pixel)
{
    #if defined(DFG_TYPE_CLOTH)
        return pixel.f0 * pixel.dfg.z;
    #else
        return lerp(pixel.dfg.xxx, pixel.dfg.yyy, pixel.f0);
    #endif
}

/**
    * Returns the reflected vector at the current shading point. The reflected vector
    * return by this function might be different from shading_reflected:
    * - For anisotropic material, we bend the reflection vector to simulate
    *   anisotropic indirect lighting
    * - The reflected vector may be modified to point towards the dominant specular
    *   direction to match reference renderings when the roughness increases
*/

float3 getReflectedVector(const PixelParams pixel, const float3 v, const float3 n, const float3 refl)
{
    #if defined(_ANISOTROPY)
        float3 anisotropyDirection = pixel.anisotropy >= 0.0 ? pixel.anisotropicB : pixel.anisotropicT;
        float3 anisotropicTangent = cross(anisotropyDirection, v);
        float3 anisotropicNormal = cross(anisotropicTangent, anisotropyDirection);
        float bendFactor = abs(pixel.anisotropy) * saturate(5.0 * pixel.perceptualRoughness);
        float3 bentNormal = normalize(lerp(n, anisotropicNormal, bendFactor));

        float3 r = reflect(-v, bentNormal);
    #else
        float3 r = refl;
    #endif
    return getSpecularDominantDirection(n, r, pixel.roughness);
}

//------------------------------------------------------------------------------
// IBL evaluation
//------------------------------------------------------------------------------

void evaluateSheenIBL(const PixelParams pixel, const ShadingData shadingData, float diffuseAO, inout float3 Fd, inout float3 Fr)
{
    #if defined(USE_SHEEN)
        // Albedo scaling of the base layer before we layer sheen on top
        Fd *= pixel.sheenScaling;
        Fr *= pixel.sheenScaling;

        float3 reflectance = pixel.sheenDFG * pixel.sheenColor;
        reflectance *= specularAO(shadingData.NoV, diffuseAO, pixel.sheenRoughness, shadingData.normal, shadingData.reflected);

        Fr += reflectance * prefilteredRadiance(shadingData.reflected, pixel.sheenPerceptualRoughness, shadingData.position);
    #endif
}

void evaluateClearCoatIBL(const PixelParams pixel, const ShadingData shadingData, float diffuseAO, inout float3 Fd, inout float3 Fr)
{
    #if defined(_CLEAR_COAT)
        #if defined(_NORMALMAP) || defined(_CLEAR_COAT_NORMAL)
            // We want to use the geometric normal for the clear coat layer
            float clearCoatNoV = clampNoV(dot(shadingData.clearCoatNormal, shadingData.view));
            float3 clearCoatR = reflect(-shadingData.view, shadingData.clearCoatNormal);
        #else
            float clearCoatNoV = shadingData.NoV;
            float3 clearCoatR = shadingData.reflected;
        #endif
        // The clear coat layer assumes an IOR of 1.5 (4% reflectance)
        float Fc = F_Schlick(0.04, 1.0, clearCoatNoV) * pixel.clearCoat;
        float attenuation = 1.0 - Fc;
        Fd *= attenuation;
        Fr *= attenuation;

        // TODO: Should we apply specularAO to the attenuation as well?
        float specAO = specularAO(clearCoatNoV, diffuseAO, pixel.clearCoatRoughness, shadingData.normal, shadingData.reflected);
        Fr += prefilteredRadiance(clearCoatR, pixel.clearCoatPerceptualRoughness, shadingData.position) * (specAO * Fc);
    #endif
}

#if defined(USE_REFRACTION)

    struct Refraction
    {
        float3 position;
        float3 direction;
        float d;
    };

    void refractionSolidSphere(const PixelParams pixel, const float3 p, const float3 n, float3 r, out Refraction ray)
    {
        r = refract(r, n, pixel.etaIR);
        float NoR = dot(n, r);
        float d = pixel.thickness * - NoR;
        ray.position = p + r * d;
        ray.d = d;
        float3 n1 = normalize(NoR * r - n * 0.5);
        ray.direction = refract(r, n1, pixel.etaRI);
    }

    void refractionSolidBox(const PixelParams pixel, const float3 p, const float3 n, float3 r, out Refraction ray)
    {
        float3 rr = refract(r, n, pixel.etaIR);
        float NoR = dot(n, rr);
        float d = pixel.thickness / max(-NoR, 0.001);
        ray.position = p + rr * d;
        ray.direction = r;
        ray.d = d;
        #if REFRACTION_MODE == REFRACTION_MODE_CUBEMAP
            // fudge direction vector, so we see the offset due to the thickness of the object
            float envDistance = 10.0; // this should come from a ubo
            ray.direction = normalize((ray.position - p) + ray.direction * envDistance);
        #endif
    }

    void refractionThinSphere(const PixelParams pixel, const float3 p, const float3 n, float3 r, out Refraction ray)
    {
        float d = 0.0;
        // note: we need the refracted ray to calculate the distance traveled
        // we could use shading_NoV, but we would lose the dependency on ior.
        float3 rr = refract(r, n, pixel.etaIR);
        float NoR = dot(n, rr);
        d = pixel.uThickness / max(-NoR, 0.001);
        ray.position = p + rr * d;
        ray.direction = r;
        ray.d = d;
    }

    void applyRefraction(const PixelParams pixel, const float3 p, const float3 v, const float3 n0, float3 E, float3 Fd, float3 Fr, inout float3 color)
    {
        Refraction ray;

        #if defined(REFRACTION_TYPE_SOLID)
            refractionSolidSphere(pixel, p, n0, -v, ray);
        #elif defined(REFRACTION_TYPE_THIN)
            refractionThinSphere(pixel, p, n0, -v, ray);
        #else
            return;
        #endif

        // compute transmission T
        float3 T = min(1.0, exp(-pixel.absorption * ray.d));

        // Roughness remapping so that an IOR of 1.0 means no microfacet refraction and an IOR
        // of 1.5 has full microfacet refraction
        float perceptualRoughness = lerp(pixel.perceptualRoughnessUnclamped, 0.0,
        saturate(pixel.etaIR * 3.0 - 2.0));
        #if defined(REFRACTION_TYPE_THIN)
            // For thin surfaces, the light will bounce off at the second interface in the direction of
            // the reflection, effectively adding to the specular, but this process will repeat itself.
            // Each time the ray exits the surface on the front side after the first bounce,
            // it's multiplied by E^2, and we get: E + E(1-E)^2 + E^3(1-E)^2 + ...
            // This infinite series converges and is easy to simplify.
            // Note: we calculate these bounces only on a single component,
            // since it's a fairly subtle effect.
            E *= 1.0 + pixel.transmission * (1.0 - E.g) / (1.0 + E.g);
        #endif

        /* sample the cubemap or screen-space */
        #if REFRACTION_MODE == REFRACTION_MODE_CUBEMAP
            // when reading from the cubemap, we are not pre-exposed so we apply iblLuminance
            // which is not the case when we'll read from the screen-space buffer
            float3 Ft = prefilteredRadiance(ray.direction, perceptualRoughness, ray.position);
        #else
            // compute the point where the ray exits the medium, if needed
            float4 screenPos = UnityWorldToClipPos(ray.position);
            float2 grabUV = ComputeGrabScreenPos(screenPos);

            // perceptualRoughness to LOD
            // Empirical factor to compensate for the gaussian approximation of Dggx, chosen so
            // cubemap and screen-space modes match at perceptualRoughness 0.125
            // TODO: Remove this factor temporarily until we find a better solution
            //       This overblurs many scenes and needs a more principled approach
            // float tweakedPerceptualRoughness = perceptualRoughness * 1.74;
            float tweakedPerceptualRoughness = perceptualRoughness;
            float lod = max(0.0, 2.0 * log2(tweakedPerceptualRoughness));

            float3 Ft = UNITY_SAMPLE_TEX2D_LOD(_GrabTexture, grabUV, lod).rgb;
        #endif

        // base color changes the amount of light passing through the boundary
        Ft *= pixel.diffuseColor;

        // fresnel from the first interface
        Ft *= 1.0 - E;

        // apply absorption
        Ft *= T;

        color.rgb += Fr + lerp(Fd, Ft, pixel.transmission);
    }
#endif

void evaluateIBL(const PixelParams pixel, const ShadingData shadingData, float occlusion, inout float3 color)
{
    #if defined(LIGHTVOLUMES)
        #if defined(LIGHTMAP_ON)
            LightVolumeAdditiveSH(shadingData.position, L0, L1r, L1g, L1b);
        #else
            LightVolumeSH(shadingData.position, L0, L1r, L1g, L1b);
        #endif
    #endif
    // specular layer
    float3 Fr;
    float3 E = specularDFG(pixel);
    float3 r = getReflectedVector(pixel, shadingData.view, shadingData.normal, shadingData.reflected);
    Fr = E * prefilteredRadiance(r, pixel.perceptualRoughness, shadingData.position);
    Fr += additiveSpecular(pixel, shadingData);

    float diffuseAO = occlusion;
    #if defined(_BENTNORMALMAP)
        float3 diffuseNormal = shadingData.bentNormal;
    #else
        float3 diffuseNormal = shadingData.normal;
    #endif

    float3 irradiance = diffuseIrradiance(diffuseNormal, shadingData);

    float specAO = diffuseAO * LerpOneTo(saturate(Luminance(irradiance) * PI), shadingData.specularAO);
    specAO = specularAO(shadingData.NoV, specAO, pixel.roughness, diffuseNormal, shadingData.reflected);

    Fr *= singleBounceAO(specAO) * pixel.energyCompensation;

    // diffuse layer
    float diffuseBRDF = singleBounceAO(diffuseAO); // Fd_Lambert() is baked in the SH below

    irradiance *= (pixel.pseudoAmbient * 0.5 + 0.5);
    float3 Fd = pixel.diffuseColor * irradiance * saturate(1.0 - E) * diffuseBRDF;

    GENELIT_EVALUATE_CUSTOM_INDIRECT(pixel, shadingData, irradiance, Fd, Fr)

    #if defined(LTCGI)
        LTCGI_Contribution(shadingData.position, shadingData.normal, shadingData.view, pixel.roughness, shadingData.lightmapUV.xy, Fd, Fr);
    #endif
    // extra ambient occlusion term for the base and subsurface layers
    multiBounceAO(diffuseAO, pixel.diffuseColor, Fd);
    multiBounceSpecularAO(specAO, pixel.f0, Fr);

    // sheen layer
    evaluateSheenIBL(pixel, shadingData, diffuseAO, Fd, Fr);

    // clear coat layer
    evaluateClearCoatIBL(pixel, shadingData, diffuseAO, Fd, Fr);

    // Note: iblLuminance is already premultiplied by the exposure
    #if defined(USE_REFRACTION)
        applyRefraction(pixel, shadingData.position, shadingData.view, shadingData.normal, E, Fd, Fr, color);
    #else
        color.rgb += (Fd + Fr);
    #endif
}
#endif
