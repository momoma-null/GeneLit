#ifndef GENELIT_AO_INCLUDED
    #define GENELIT_AO_INCLUDED

    //------------------------------------------------------------------------------
    // Ambient occlusion configuration
    //------------------------------------------------------------------------------

    // Diffuse BRDFs
    #define SPECULAR_AO_OFF             0
    #define SPECULAR_AO_SIMPLE          1
    #define SPECULAR_AO_BENT_NORMALS    2

    #define SPECULAR_AMBIENT_OCCLUSION SPECULAR_AO_SIMPLE
    #define MULTI_BOUNCE_AMBIENT_OCCLUSION 1

    //------------------------------------------------------------------------------
    // Ambient occlusion helpers
    //------------------------------------------------------------------------------

    float SpecularAO_Lagarde(float NoV, float visibility, float roughness)
    {
        // Lagarde and de Rousiers 2014, "Moving Frostbite to PBR"
        return saturate(pow(NoV + visibility, exp2(-16.0 * roughness - 1.0)) - 1.0 + visibility);
    }

    float sphericalCapsIntersection(float cosCap1, float cosCap2, float cosDistance)
    {
        // Oat and Sander 2007, "Ambient Aperture Lighting"
        // Approximation mentioned by Jimenez et al. 2016
        float r1 = acosFastPositive(cosCap1);
        float r2 = acosFastPositive(cosCap2);
        float d  = acosFast(cosDistance);

        // We work with cosine angles, replace the original paper's use of
        // cos(min(r1, r2)) with max(cosCap1, cosCap2)
        // We also remove a multiplication by 2 * PI to simplify the computation
        // since we divide by 2 * PI in computeBentSpecularAO()

        if (min(r1, r2) <= max(r1, r2) - d) return 1.0 - max(cosCap1, cosCap2);
        else if (r1 + r2 <= d) return 0.0;

        float delta = abs(r1 - r2);
        float x = 1.0 - saturate((d - delta) / max(r1 + r2 - delta, 1e-4));
        // simplified smoothstep()
        float area = sq(x) * (-2.0 * x + 3.0);
        return area * (1.0 - max(cosCap1, cosCap2));
    }

    // This function could (should?) be implemented as a 3D LUT instead, but we need to save samplers
    float SpecularAO_Cones(float3 bentNormal, float visibility, float roughness, float3 refl)
    {
        // Jimenez et al. 2016, "Practical Realtime Strategies for Accurate Indirect Occlusion"

        // aperture from ambient occlusion
        float cosAv = sqrt(1.0 - visibility);
        // aperture from roughness, log(10) / log(2) = 3.321928
        float cosAs = exp2(-3.321928 * sq(roughness));
        // angle betwen bent normal and reflection direction
        float cosB  = dot(bentNormal, refl);

        // Remove the 2 * PI term from the denominator, it cancels out the same term from
        // sphericalCapsIntersection()
        float ao = sphericalCapsIntersection(cosAv, cosAs, cosB) / (1.0 - cosAs);
        // Smoothly kill specular AO when entering the perceptual roughness range [0.1..0.3]
        // Without this, specular AO can remove all reflections, which looks bad on metals
        return lerp(1.0, ao, smoothstep(0.01, 0.09, roughness));
    }

    float specularAO(float NoV, float visibility, float roughness, float3 normal, float3 refl)
    {
        float specularAO = 1.0;

        // SSAO is not applied when blending is enabled
        #if !defined(_ALPHABLEND_ON) && !defined(_ALPHAPREMULTIPLY_ON)

            #if SPECULAR_AMBIENT_OCCLUSION == SPECULAR_AO_SIMPLE
                // TODO: Should we even bother computing this when screen space bent normals are enabled?
                specularAO = SpecularAO_Lagarde(NoV, visibility, roughness);
            #elif SPECULAR_AMBIENT_OCCLUSION == SPECULAR_AO_BENT_NORMALS
                specularAO = SpecularAO_Cones(normal, visibility, roughness, refl);
            #endif

        #endif

        return specularAO;
    }

    #if MULTI_BOUNCE_AMBIENT_OCCLUSION == 1
        /**
        * Returns a color ambient occlusion based on a pre-computed visibility term.
        * The albedo term is meant to be the diffuse color or f0 for the diffuse and
        * specular terms respectively.
        */
        float3 gtaoMultiBounce(float visibility, const float3 albedo)
        {
            // Jimenez et al. 2016, "Practical Realtime Strategies for Accurate Indirect Occlusion"
            float3 a =  2.0404 * albedo - 0.3324;
            float3 b = -4.7951 * albedo + 0.6417;
            float3 c =  2.7552 * albedo + 0.6903;

            return max(visibility, ((visibility * a + b) * visibility + c) * visibility);
        }
    #endif

    void multiBounceAO(float visibility, const float3 albedo, inout float3 color)
    {
        #if MULTI_BOUNCE_AMBIENT_OCCLUSION == 1
            color *= gtaoMultiBounce(visibility, albedo);
        #endif
    }

    void multiBounceSpecularAO(float visibility, const float3 albedo, inout float3 color)
    {
        #if MULTI_BOUNCE_AMBIENT_OCCLUSION == 1 && SPECULAR_AMBIENT_OCCLUSION != SPECULAR_AO_OFF
            color *= gtaoMultiBounce(visibility, albedo);
        #endif
    }

    float singleBounceAO(float visibility)
    {
        #if MULTI_BOUNCE_AMBIENT_OCCLUSION == 1
            return 1.0;
        #else
            return visibility;
        #endif
    }
#endif
