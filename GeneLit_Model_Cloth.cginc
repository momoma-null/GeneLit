#ifndef GENELIT_MODEL_CLOTH_INCLUDED
    #define GENELIT_MODEL_CLOTH_INCLUDED

    #include "GeneLit_LightingCommon.cginc"
    #include "GeneLit_Brdf.cginc"

    /**
    * Evaluates lit materials with the cloth shading model. Similar to the standard
    * model, the cloth shading model is based on a Cook-Torrance microfacet model.
    * Its distribution and visibility terms are however very different to take into
    * account the softer apperance of many types of cloth. Some highly reflecting
    * fabrics like satin or leather should use the standard model instead.
    *
    * This shading model optionally models subsurface scattering events. The
    * computation of these events is not physically based but can add necessary
    * details to a material.
    */
    float3 surfaceShading(const PixelParams pixel, const FilamentLight light, const ShadingData shadingData, float occlusion)
    {
        float3 h = normalize(shadingData.view + light.l);
        float NoL = light.NoL;
        float NoH = saturate(dot(shadingData.normal, h));
        float LoH = saturate(dot(light.l, h));

        // specular BRDF
        float D = distributionCloth(pixel.roughness, NoH);
        float V = visibilityCloth(shadingData.NoV, NoL);
        float3  F = pixel.f0;
        // Ignore pixel.energyCompensation since we use a different BRDF here
        float3 Fr = (D * V) * F;

        // diffuse BRDF
        float diff = diffuse(pixel.roughness, shadingData.NoV, NoL, LoH);
        #if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
            // Energy conservative wrap diffuse to simulate subsurface scattering
            diff *= Fd_Wrap(dot(shadingData.normal, light.l), 0.5);
        #endif

        // We do not multiply the diffuse term by the Fresnel term as discussed in
        // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
        // The effect is fairly subtle and not deemed worth the cost for mobile
        float3 Fd = diff * pixel.diffuseColor;

        #if defined(MATERIAL_HAS_SUBSURFACE_COLOR)
            // Cheap subsurface scatter
            Fd *= saturate(pixel.subsurfaceColor + NoL);
            // We need to apply NoL separately to the specular lobe since we already took
            // it into account in the diffuse lobe
            float3 color = Fd + Fr * NoL;
            color *= light.colorIntensity.rgb * (light.colorIntensity.w * light.attenuation * occlusion);
        #else
            float3 color = Fd + Fr;
            color *= light.colorIntensity.rgb * (light.colorIntensity.w * light.attenuation * NoL * occlusion);
        #endif

        return color;
    }
#endif
