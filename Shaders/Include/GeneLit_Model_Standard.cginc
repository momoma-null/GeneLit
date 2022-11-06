#ifndef GENELIT_MODEL_STANDARD_INCLUDED
    #define GENELIT_MODEL_STANDARD_INCLUDED

    #define USE_METALLIC

    #if defined(_SHEEN)
        #define USE_SHEEN
    #endif

    #if defined(REFRACTION_TYPE_SOLID) || defined(REFRACTION_TYPE_THIN)
        #define USE_REFRACTION
    #endif

    #define GENELIT_CUSTOM_INSTANCED_PROP
    #define GENELIT_CUSTOM_MATERIAL_INPUTS
    #define GENELIT_CUSTOM_PIXEL_PARAMS

    #define GENELIT_INIT_CUSTOM_MATERIAL(material)
    #define GENELIT_EVALUATE_CUSTOM_INDIRECT(pixel, shadingData, irradiance, Fd, Fr)

    #include "GeneLit_Utils.cginc"
    #include "GeneLit_Input.cginc"
    #include "GeneLit_LightingCommon.cginc"
    #include "GeneLit_Brdf.cginc"

    #if defined(USE_SHEEN)
        float3 sheenLobe(const PixelParams pixel, float NoV, float NoL, float NoH)
        {
            float D = distributionCloth(pixel.sheenRoughness, NoH);
            float V = visibilityCloth(NoV, NoL);

            return (D * V) * pixel.sheenColor;
        }
    #endif

    #if defined(_CLEAR_COAT)
        float clearCoatLobe(const PixelParams pixel, const ShadingData shadingData, const float3 h, float NoH, float LoH, out float Fcc)
        {
            #if defined(_CLEAR_COAT_NORMAL)
                // If the material has a normal map, we want to use the geometric normal
                // instead to avoid applying the normal map details to the clear coat layer
                float clearCoatNoH = saturate(dot(shadingData.clearCoatNormal, h));
            #else
                float clearCoatNoH = NoH;
            #endif

            // clear coat specular lobe
            float D = distributionClearCoat(pixel.clearCoatRoughness, clearCoatNoH, h);
            float V = visibilityClearCoat(LoH);
            float F = F_Schlick(0.04, 1.0, LoH) * pixel.clearCoat; // fix IOR to 1.5

            Fcc = F;
            return D * V * F;
        }
    #endif

    #if defined(_ANISOTROPY)
        float3 anisotropicLobe(const PixelParams pixel, const FilamentLight light, const float3 h, const float3 v, float NoV, float NoL, float NoH, float LoH)
        {
            float3 l = light.l;
            float3 t = pixel.anisotropicT;
            float3 b = pixel.anisotropicB;

            float ToV = dot(t, v);
            float BoV = dot(b, v);
            float ToL = dot(t, l);
            float BoL = dot(b, l);
            float ToH = dot(t, h);
            float BoH = dot(b, h);

            // Anisotropic parameters: at and ab are the roughness along the tangent and bitangent
            // to simplify materials, we derive them from a single roughness parameter
            // Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
            float at = max(pixel.roughness * (1.0 + pixel.anisotropy), MIN_ROUGHNESS);
            float ab = max(pixel.roughness * (1.0 - pixel.anisotropy), MIN_ROUGHNESS);

            // specular anisotropic BRDF
            float D = distributionAnisotropic(at, ab, ToH, BoH, NoH);
            float V = visibilityAnisotropic(pixel.roughness, at, ab, ToV, BoV, ToL, BoL, NoV, NoL);
            float3 F = fresnel(pixel.f0, LoH);

            return (D * V) * F;
        }
    #endif

    float3 isotropicLobe(const PixelParams pixel, const float3 h, float NoV, float NoL, float NoH, float LoH)
    {
        float D = distribution(pixel.roughness, NoH, h);
        float V = visibility(pixel.roughness, NoV, NoL);
        float3 F = fresnel(pixel.f0, LoH);
        return (D * V) * F;
    }

    float3 diffuseLobe(const PixelParams pixel, float NoV, float NoL, float LoH)
    {
        return pixel.diffuseColor * diffuse(pixel.roughness, NoV, NoL, LoH);
    }

    void getCustomPixelParams(const MaterialInputs material, const ShadingData shadingData, inout PixelParams pixel) { }

    /**
    * Evaluates lit materials with the standard shading model. This model comprises
    * of 2 BRDFs: an optional clear coat BRDF, and a regular surface BRDF.
    *
    * Surface BRDF
    * The surface BRDF uses a diffuse lobe and a specular lobe to render both
    * dielectrics and conductors. The specular lobe is based on the Cook-Torrance
    * micro-facet model (see brdf.fs for more details). In addition, the specular
    * can be either isotropic or anisotropic.
    *
    * Clear coat BRDF
    * The clear coat BRDF simulates a transparent, absorbing dielectric layer on
    * top of the surface. Its IOR is set to 1.5 (polyutherane) to simplify
    * our computations. This BRDF only contains a specular lobe and while based
    * on the Cook-Torrance microfacet model, it uses cheaper terms than the surface
    * BRDF's specular lobe (see brdf.fs).
    */
    float3 surfaceShading(const PixelParams pixel, const FilamentLight light, const ShadingData shadingData, float occlusion)
    {
        float3 h = normalize(shadingData.view + light.l);

        float NoV = shadingData.NoV;
        float NoL = saturate(light.NoL);
        float NoH = saturate(dot(shadingData.normal, h));
        float LoH = saturate(dot(light.l, h));

        #if defined(_ANISOTROPY)
            float3 Fr = anisotropicLobe(pixel, light, h, shadingData.view, NoV, NoL, NoH, LoH);
        #else
            float3 Fr = isotropicLobe(pixel, h, NoV, NoL, NoH, LoH);
        #endif

        float3 Fd = diffuseLobe(pixel, NoV, NoL, LoH) * light.colorIntensity.w;
        #if defined(USE_REFRACTION)
            Fd *= (1.0 - pixel.transmission);
        #endif

        // TODO: attenuate the diffuse lobe to avoid energy gain

        // The energy compensation term is used to counteract the darkening effect
        // at high roughness
        float3 color = Fd + Fr * pixel.energyCompensation;

        #if defined(USE_SHEEN)
            color *= pixel.sheenScaling;
            color += sheenLobe(pixel, NoV, NoL, NoH);
        #endif

        #if defined(_CLEAR_COAT)
            float Fcc;
            float clearCoat = clearCoatLobe(pixel, shadingData, h, NoH, LoH, Fcc);
            float attenuation = 1.0 - Fcc;

            #if defined(_CLEAR_COAT_NORMAL)
                color *= attenuation * NoL;

                // If the material has a normal map, we want to use the geometric normal
                // instead to avoid applying the normal map details to the clear coat layer
                float clearCoatNoL = saturate(dot(shadingData.clearCoatNormal, light.l));
                color += clearCoat * clearCoatNoL;

                // Early exit to avoid the extra multiplication by NoL
                return (color * light.colorIntensity.rgb) * (light.attenuation * occlusion);
            #else
                color *= attenuation;
                color += clearCoat;
            #endif
        #endif

        return (color * light.colorIntensity.rgb) * (light.attenuation * NoL * occlusion);
    }
#endif
