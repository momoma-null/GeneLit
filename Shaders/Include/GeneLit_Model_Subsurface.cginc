#ifndef GENELIT_MODEL_SUBSURFACE_INCLUDED
    #define GENELIT_MODEL_SUBSURFACE_INCLUDED

    #define USE_METALLIC

    UNITY_DECLARE_TEX2D_NOSAMPLER(_SubsurfaceThicknessMap);

    #define GENELIT_CUSTOM_INSTANCED_PROP \
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfaceThickness)\
    UNITY_DEFINE_INSTANCED_PROP(half, _SubsurfacePower)\
    UNITY_DEFINE_INSTANCED_PROP(half4, _SubsurfaceColor)

    #define GENELIT_CUSTOM_MATERIAL_INPUTS \
    float subsurfaceThickness;\
    float subsurfacePower;\
    float3 subsurfaceColor;

    #define GENELIT_CUSTOM_PIXEL_PARAMS \
    float subsurfaceThickness;\
    float subsurfacePower;\
    float3 subsurfaceColor;

    #define GENELIT_INIT_CUSTOM_MATERIAL(material) \
    GENELIT_SAMPLE_TEX2D_SAMPLER(_SubsurfaceThicknessMap, _MainTex, uv, subsurfaceThickness)\
    material.subsurfaceThickness = subsurfaceThickness.g * GENELIT_ACCESS_PROP(_SubsurfaceThickness);\
    material.subsurfacePower = GENELIT_ACCESS_PROP(_SubsurfacePower);\
    material.subsurfaceColor = GENELIT_ACCESS_PROP(_SubsurfaceColor).rgb;

    #define GENELIT_EVALUATE_CUSTOM_INDIRECT(pixel, shadingData, irradiance, Fd, Fr) \
    float3 viewDependent = prefilteredRadiance(-shadingData.view, pixel.roughness, 1.0 + pixel.subsurfaceThickness, shadingData.position);\
    float attenuation = (1.0 - pixel.subsurfaceThickness) / (2.0 * PI);\
    Fd += pixel.subsurfaceColor * (irradiance + viewDependent) * attenuation;

    #include "GeneLit_Input.cginc"
    #include "GeneLit_LightingCommon.cginc"
    #include "GeneLit_Brdf.cginc"

    void getCustomPixelParams(const MaterialInputs material, const ShadingData shadingData, inout PixelParams pixel)
    {
        pixel.subsurfaceThickness = saturate(material.subsurfaceThickness);
        pixel.subsurfacePower = material.subsurfacePower;
        pixel.subsurfaceColor = material.subsurfaceColor;
    }

    /**
    * Evalutes lit materials with the subsurface shading model. This model is a
    * combination of a BRDF (the same used in shading_model_standard.fs, refer to that
    * file for more information) and of an approximated BTDF to simulate subsurface
    * scattering. The BTDF itself is not physically based and does not represent a
    * correct interpretation of transmission events.
    */
    float3 surfaceShading(const PixelParams pixel, const FilamentLight light, const ShadingData shadingData, float occlusion)
    {
        float3 h = normalize(shadingData.view + light.l);

        float NoL = light.NoL;
        float NoH = saturate(dot(shadingData.normal, h));
        float LoH = saturate(dot(light.l, h));

        float3 Fr = 0.0;
        if (NoL > 0.0) {
            // specular BRDF
            float D = distribution(pixel.roughness, NoH, h);
            float V = visibility(pixel.roughness, shadingData.NoV, NoL);
            float3  F = fresnel(pixel.f0, LoH);
            Fr = (D * V) * F * pixel.energyCompensation;
        }

        // diffuse BRDF
        float3 Fd = pixel.diffuseColor * diffuse(pixel.roughness, shadingData.NoV, NoL, LoH) * light.colorIntensity.w;

        // NoL does not apply to transmitted light
        float3 color = (Fd + Fr) * (NoL * occlusion);

        // subsurface scattering
        // Use a spherical gaussian approximation of pow() for forwardScattering
        // We could include distortion by adding shading_normal * distortion to light.l
        float scatterVoH = saturate(dot(shadingData.view, -light.l));
        float forwardScatter = exp2(scatterVoH * pixel.subsurfacePower - pixel.subsurfacePower);
        float backScatter = saturate(NoL * pixel.subsurfaceThickness + (1.0 - pixel.subsurfaceThickness)) * 0.5;
        float subsurface = lerp(backScatter, 1.0, forwardScatter) * (1.0 - pixel.subsurfaceThickness);
        color += pixel.subsurfaceColor * (subsurface * Fd_Lambert());

        // TODO: apply occlusion to the transmitted light
        return (color * light.colorIntensity.rgb) * (light.attenuation);
    }
#endif
