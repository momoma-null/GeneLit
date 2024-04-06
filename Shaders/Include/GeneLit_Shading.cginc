#ifndef GENELIT_SHADING_INCLUDED
    #define GENELIT_SHADING_INCLUDED

    #include "GeneLit_Input.cginc"
    #include "GeneLit_Utils.cginc"
    #include "GeneLit_LightingCommon.cginc"
    #include "GeneLit_LightingDirectional.cginc"
    #include "GeneLit_LightingIndirect.cginc"
    #include "GeneLit_LightingPunctual.cginc"

    #if defined(CAPSULE_AO)
        #include "GeneLit_CapsuleAO.cginc"
    #endif

    //------------------------------------------------------------------------------
    // Lighting
    //------------------------------------------------------------------------------

    #if defined(_ALPHATEST_ON)
        float applyAlphaMask(float alpha, float threshold)
        {
            // Use derivatives to smooth alpha tested edges
            return saturate((alpha - threshold) / max(fwidth(alpha), 1e-3) + 0.5);
        }
    #endif

    float computeDiffuseAlpha(const MaterialInputs material)
    {
        #if defined(_ALPHATEST_ON)
            return applyAlphaMask(material.baseColor.a, material.maskThreshold);
        #elif defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
            return material.baseColor.a;
        #else
            return 1.0;
        #endif
    }

    #if defined(GEOMETRIC_SPECULAR_AA)
        float normalFiltering(float perceptualRoughness, const float3 worldNormal)
        {
            // Kaplanyan 2016, "Stable specular highlights"
            // Tokuyoshi 2017, "Error Reduction and Simplification for Shading Anti-Aliasing"
            // Tokuyoshi and Kaplanyan 2019, "Improved Geometric Specular Antialiasing"

            // This implementation is meant for deferred rendering in the original paper but
            // we use it in forward rendering as well (as discussed in Tokuyoshi and Kaplanyan
            // 2019). The main reason is that the forward version requires an expensive transform
            // of the half vector by the tangent frame for every light. This is therefore an
            // approximation but it works well enough for our needs and provides an improvement
            // over our original implementation based on Vlachos 2015, "Advanced VR Rendering".

            float3 du = ddx(worldNormal);
            float3 dv = ddy(worldNormal);

            float variance = UNITY_INV_TWO_PI * (dot(du, du) + dot(dv, dv));

            float roughness = perceptualRoughnessToRoughness(perceptualRoughness);
            float kernelRoughness = saturate(2.0 * variance);
            float squareRoughness = saturate(roughness * roughness + kernelRoughness);

            return roughnessToPerceptualRoughness(sqrt(squareRoughness));
        }
    #endif

    #if defined(USE_METALLIC)
        void getCommonPixelParams(const MaterialInputs material, inout PixelParams pixel)
        {
            float4 baseColor = material.baseColor;

            #if defined(_ALPHAPREMULTIPLY_ON)
                baseColor.rgb *= baseColor.a;
            #endif

            pixel.diffuseColor = computeDiffuseColor(baseColor, material.metallic);
            // Assumes an interface from air to an IOR of 1.5 for dielectrics
            float reflectance = computeDielectricF0(material.reflectance);
            pixel.f0 = computeF0(baseColor, material.metallic, reflectance);

            #if defined(USE_REFRACTION)
                // Air's Index of refraction is 1.000277 at STP but everybody uses 1.0
                const float airIor = 1.0;
                // [common case] ior is not set in the material, deduce it from F0
                float materialor = f0ToIor(pixel.f0.g);
                pixel.etaIR = airIor / materialor;  // air -> material
                pixel.etaRI = materialor / airIor;  // material -> air
                pixel.transmission = saturate(material.transmission);
                pixel.absorption = max(0, material.absorption);
                pixel.thickness = max(0.0, material.thickness);
                #if defined(REFRACTION_TYPE_THIN)
                    pixel.uThickness = max(0.0, material.microThickness);
                #else
                    pixel.uThickness = 0.0;
                #endif
            #endif
        }
    #endif

    void getSheenPixelParams(const MaterialInputs material, const ShadingData shadingData, inout PixelParams pixel)
    {
        #if defined(USE_SHEEN)
            pixel.sheenColor = material.sheenColor;

            float sheenPerceptualRoughness = material.sheenRoughness;
            sheenPerceptualRoughness = clamp(sheenPerceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);

            #if defined(GEOMETRIC_SPECULAR_AA)
                sheenPerceptualRoughness = normalFiltering(sheenPerceptualRoughness, shadingData.normal);
            #endif

            pixel.sheenPerceptualRoughness = sheenPerceptualRoughness;
            pixel.sheenRoughness = perceptualRoughnessToRoughness(sheenPerceptualRoughness);
        #endif
    }

    void getClearCoatPixelParams(const MaterialInputs material, const ShadingData shadingData, inout PixelParams pixel)
    {
        #if defined(_CLEAR_COAT)
            pixel.clearCoat = material.clearCoat;

            // Clamp the clear coat roughness to avoid divisions by 0
            float clearCoatPerceptualRoughness = material.clearCoatRoughness;
            clearCoatPerceptualRoughness = clamp(clearCoatPerceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);

            #if defined(GEOMETRIC_SPECULAR_AA)
                clearCoatPerceptualRoughness = normalFiltering(clearCoatPerceptualRoughness, shadingData.normal);
            #endif

            pixel.clearCoatPerceptualRoughness = clearCoatPerceptualRoughness;
            pixel.clearCoatRoughness = perceptualRoughnessToRoughness(clearCoatPerceptualRoughness);

            #if defined(CLEAR_COAT_IOR_CHANGE)
                // The base layer's f0 is computed assuming an interface from air to an IOR
                // of 1.5, but the clear coat layer forms an interface from IOR 1.5 to IOR
                // 1.5. We recompute f0 by first computing its IOR, then reconverting to f0
                // by using the correct interface
                pixel.f0 = lerp(pixel.f0, f0ClearCoatToSurface(pixel.f0), pixel.clearCoat);
            #endif
        #endif
    }

    void getRoughnessPixelParams(const MaterialInputs material, const ShadingData shadingData, inout PixelParams pixel)
    {
        float perceptualRoughness = material.roughness;

        // This is used by the refraction code and must be saved before we apply specular AA
        pixel.perceptualRoughnessUnclamped = perceptualRoughness;

        #if defined(GEOMETRIC_SPECULAR_AA)
            perceptualRoughness = normalFiltering(perceptualRoughness, shadingData.normal);
        #endif

        #if defined(_CLEAR_COAT)
            // This is a hack but it will do: the base layer must be at least as rough
            // as the clear coat layer to take into account possible diffusion by the
            // top layer
            float basePerceptualRoughness = max(perceptualRoughness, pixel.clearCoatPerceptualRoughness);
            perceptualRoughness = lerp(perceptualRoughness, basePerceptualRoughness, pixel.clearCoat);
        #endif

        // Clamp the roughness to a minimum value to avoid divisions by 0 during lighting
        pixel.perceptualRoughness = clamp(perceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
        // Remaps the roughness to a perceptually linear roughness (roughness^2)
        pixel.roughness = perceptualRoughnessToRoughness(pixel.perceptualRoughness);
    }

    void getAnisotropyPixelParams(const MaterialInputs material, const ShadingData shadingData, inout PixelParams pixel)
    {
        #if defined(_ANISOTROPY)
            float3 direction = material.anisotropyDirection;
            direction.z = 0;
            pixel.anisotropy = material.anisotropy;
            float3 tempT = mul(shadingData.tangentToWorld, direction);
            pixel.anisotropicB = normalize(cross(shadingData.normal, tempT));
            pixel.anisotropicT = normalize(cross(pixel.anisotropicB, shadingData.normal));
        #endif
    }

    void getEnergyCompensationPixelParams(const ShadingData shadingData, inout PixelParams pixel)
    {
        // Pre-filtered DFG term used for image-based lighting
        pixel.dfg = prefilteredDFG(pixel.perceptualRoughness, shadingData.NoV);

        #if !defined(DFG_TYPE_CLOTH)
            // Energy compensation for multiple scattering in a microfacet model
            // See "Multiple-Scattering Microfacet BSDFs with the Smith Model"
            pixel.energyCompensation = 1.0 + pixel.f0 * (1.0 / pixel.dfg.y - 1.0);
        #else
            pixel.energyCompensation = 1.0;
        #endif

        #if defined(USE_SHEEN)
            pixel.sheenDFG = prefilteredDFG(pixel.sheenPerceptualRoughness, shadingData.NoV).z;
            pixel.sheenScaling = 1.0 - max3(pixel.sheenColor) * pixel.sheenDFG;
        #endif
    }

    /**
    * This function evaluates all lights one by one:
    * - Image based lights (IBL)
    * - Directional lights
    * - Punctual lights
    *
    * Area lights are currently not supported.
    *
    * Returns a pre-exposed HDR RGBA color in linear space.
    */
    float4 evaluateLights(const MaterialInputs material, const ShadingData shadingData)
    {
        PixelParams pixel;
        UNITY_INITIALIZE_OUTPUT(PixelParams, pixel);
        getCommonPixelParams(material, pixel);
        getSheenPixelParams(material, shadingData, pixel);
        getClearCoatPixelParams(material, shadingData, pixel);
        getRoughnessPixelParams(material, shadingData, pixel);
        getAnisotropyPixelParams(material, shadingData, pixel);
        getEnergyCompensationPixelParams(shadingData, pixel);
        getCustomPixelParams(material, shadingData, pixel);

        // Ideally we would keep the diffuse and specular components separate
        // until the very end but it costs more ALUs on mobile. The gains are
        // currently not worth the extra operations
        float3 color = 0.0;
        float visibility = 1.0;
        FilamentLight light;
        UNITY_INITIALIZE_OUTPUT(FilamentLight, light)
        #if UNITY_PASS_FORWARDBASE
            light = getDirectionalLight(shadingData);
            float occlusion = material.ambientOcclusion;
            visibility *= shadingData.atten;

            #if defined(CAPSULE_AO)
                float capsuleAO, capsuleShadow;
                clculateAllCapOcclusion(shadingData.position, shadingData.normal, light.l, /* out */ capsuleAO, /* out */ capsuleShadow);
                occlusion *= lerp(1.0, capsuleAO, material.capsuleAOStrength);
                visibility *= lerp(1.0, capsuleShadow, material.capsuleShadowStrength);
            #endif

            visibility *= computeHeightMapShadowing(shadingData, light);
            pixel.pseudoAmbient = lerp(visibility, 1.0, light.colorIntensity.w);

            // We always evaluate the IBL as not having one is going to be uncommon,
            // it also saves 1 shader variant
            evaluateIBL(pixel, shadingData, occlusion, color);

            visibility *= computeMicroShadowing(light.NoL, occlusion);
        #elif UNITY_PASS_FORWARDADD
            light = getPunctualLights(shadingData);
            visibility *= computeHeightMapShadowing(shadingData, light);
        #endif
        color.rgb += surfaceShading(pixel, light, shadingData, visibility);

        #if defined(UNITY_PASS_FORWARDBASE) && defined(VERTEX_LIGHT_AS_PIXEL_LIGHT)
            FilamentLight lights[4];
            float4 lightAttenSq = unity_4LightAtten0 / (material.vertexLightRangeMultiplier * material.vertexLightRangeMultiplier);
            getVertexPunctualLights(shadingData, lightAttenSq, lights);
            visibility = 1.0;
            color.rgb += surfaceShading(pixel, lights[0], shadingData, visibility);
            color.rgb += surfaceShading(pixel, lights[1], shadingData, visibility);
            color.rgb += surfaceShading(pixel, lights[2], shadingData, visibility);
            color.rgb += surfaceShading(pixel, lights[3], shadingData, visibility);
        #endif

        return float4(color, computeDiffuseAlpha(material));
    }

    void addEmissive(const MaterialInputs material, inout float4 color)
    {
        float4 emissive = material.emissive;
        color.rgb += emissive.rgb * color.a;
    }

    /**
    * Evaluate lit materials. The actual shading model used to do so is defined
    * by the function surfaceShading() found in shading_model_*.fs.
    *
    * Returns a pre-exposed HDR RGBA color in linear space.
    */
    float4 evaluateMaterial(const MaterialInputs material, const ShadingData shadingData)
    {
        float4 color = evaluateLights(material, shadingData);
        #if UNITY_PASS_FORWARDBASE
            addEmissive(material, color);
        #endif
        return color;
    }
#endif
