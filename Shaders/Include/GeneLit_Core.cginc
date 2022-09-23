#ifndef GENELIT_CORE_INCLUDED
    #define GENELIT_CORE_INCLUDED

    #include "UnityCG.cginc"
    #include "AutoLight.cginc"
    #include "GeneLit_Input.cginc"
    #include "GeneLit_Utils.cginc"
    #include "GeneLit_LightingCommon.cginc"
    #include "GeneLit_Shading.cginc"

    struct v2f
    {
        UNITY_POSITION(pos);
        UVCoord uv : TEXCOORD0;
        float4 tSpace0 : TEXCOORD1;
        float4 tSpace1 : TEXCOORD2;
        float4 tSpace2 : TEXCOORD3;
        half4 color : TEXCOORD4;
        half4 ambientOrLightmapUV : TEXCOORD5;
        UNITY_LIGHTING_COORDS(6,7)
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    inline half4 VertexGIForward(appdata_full v, float3 posWorld, half3 normalWorld)
    {
        half4 ambientOrLightmapUV = 0;

        #ifdef UNITY_PASS_FORWARDBASE
            #ifdef LIGHTMAP_ON
                ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
            #elif UNITY_SHOULD_SAMPLE_SH
                #ifdef VERTEXLIGHT_ON
                    ambientOrLightmapUV.rgb = Shade4PointLights(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    unity_4LightAtten0, posWorld, normalWorld);
                #endif

                ambientOrLightmapUV.rgb = ShadeSHPerVertex(normalWorld, ambientOrLightmapUV.rgb);
            #endif

            #ifdef DYNAMICLIGHTMAP_ON
                ambientOrLightmapUV.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
            #endif
        #endif

        return ambientOrLightmapUV;
    }

    //------------------------------------------------------------------------------
    // Material evaluation
    //------------------------------------------------------------------------------

    /**
    * Computes global shading parameters used to apply lighting, such as the view
    * vector in world space, the tangent frame at the shading point, etc.
    */
    void computeShadingParams(v2f IN, bool facing, out ShadingData shadingData)
    {
        UNITY_INITIALIZE_OUTPUT(ShadingData, shadingData);

        // on build, unity_OcclusionMaskSelector may be 0 without any directional light
        unity_OcclusionMaskSelector = sum(unity_OcclusionMaskSelector) == 0 ? fixed4(1, 0, 0, 0) : unity_OcclusionMaskSelector;

        float3 t = normalize(float3(IN.tSpace0.x, IN.tSpace1.x, IN.tSpace2.x));
        float3 b = normalize(float3(IN.tSpace0.y, IN.tSpace1.y, IN.tSpace2.y));
        float3 n = normalize(float3(IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z));

        n = facing ? n : -n;
        t = facing ? t : -t;
        b = facing ? b : -b;

        shadingData.geometricNormal = n;

        // We use unnormalized post-interpolation values, assuming mikktspace tangents
        shadingData.tangentToWorld = transpose(float3x3(t, b, n));

        shadingData.position = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
        shadingData.view = normalize(_WorldSpaceCameraPos - shadingData.position);

        // we do this so we avoid doing (matrix multiply), but we burn 4 varyings:
        //    p = clipFromWorldMatrix * shadingData.position;
        //    shadingData.normalizedViewportCoord = p.xy * 0.5 / p.w + 0.5
        shadingData.normalizedViewportCoord = ComputeScreenPos(UnityWorldToClipPos(shadingData.position));

        #if defined(LIGHTMAP_ON)
            half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.ambientOrLightmapUV.xy);
            shadingData.ambient = DecodeLightmap(bakedColorTex);
            shadingData.lightmapUV = IN.ambientOrLightmapUV;
        #elif defined(DYNAMICLIGHTMAP_ON)
            shadingData.ambient = 0;
            shadingData.lightmapUV = IN.ambientOrLightmapUV;
        #else
            shadingData.ambient = IN.ambientOrLightmapUV.rgb;
            shadingData.lightmapUV = 0;
        #endif

        shadingData.uv = IN.uv;
    }

    void initMaterial(const ShadingData shadingData, inout MaterialInputs material)
    {
        float4 color = GENELIT_ACCESS_PROP(_Color);
        switch(GENELIT_ACCESS_PROP(_VertexColorMode))
        {
            case 1:material.baseColor *= color;break;
            case 2:material.baseColor += color;break;
            case 3:material.baseColor =  material.baseColor + color - material.baseColor * color;break;
            default:material.baseColor = color;break;
        }
        #if defined(_TILEMODE_NO_TILE)
            SAMPLE_TEX2DTILE_WIEGHT(_MainTex, baseColor, shadingData.position, shadingData.geometricNormal)
            material.baseColor *= baseColor;
        #else
            float2 uv = shadingData.uv.xy;
            #if defined(_PARALLAXMAP)
                half3 oViewDir = normalize(mul(shadingData.view, shadingData.tangentToWorld));
                uv = ParallaxOffset2Step(uv, oViewDir);
            #endif
            material.baseColor *= UNITY_SAMPLE_TEX2D(_MainTex, uv);
        #endif
        #if defined(_MASKMAP)
            GENELIT_SAMPLE_TEX2D_SAMPLER(_MaskMap, _MainTex, uv, mods)
        #else
            float4 mods = 1;
        #endif
        material.roughness = 1.0 - GENELIT_ACCESS_PROP(_Glossiness) * mods.a;
        #if defined(USE_METALLIC)
            material.metallic = GENELIT_ACCESS_PROP(_Metallic) * mods.r;
            material.reflectance = GENELIT_ACCESS_PROP(_Reflectance);
        #endif
        material.ambientOcclusion = GENELIT_ACCESS_PROP(_OcclusionStrength) * mods.g;

        #if defined(_NORMALMAP)
            GENELIT_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, uv, normalMap)
            material.normal = UnpackScaleNormal(normalMap, GENELIT_ACCESS_PROP(_BumpScale));
        #else
            material.normal = float3(0.0, 0.0, 1.0);
        #endif

        #if defined(_BENTNORMALMAP)
            material.bentNormal = UnpackNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_BentNormalMap, _MainTex, uv));
        #endif

        #if defined(_DETAIL_MAP)
            float detailMask = mods.b;
            float2 detailUV = shadingData.uv.zw;
            float4 detailMap = UNITY_SAMPLE_TEX2D(_DetailMap, detailUV);
            float detailAlbedo = detailMap.r - 0.5;
            float detailSmoothness = detailMap.b - 0.5;
            float3 detailNormal = float3(detailMap.ag * 2.0 - 1.0, 0);

            float albedoDetailSpeed = saturate(abs(detailAlbedo) * GENELIT_ACCESS_PROP(_DetailAlbedoScale));
            float3 baseColorOverlay = lerp(sqrt(material.baseColor.rgb), (detailAlbedo < 0.0) ? float3(0.0, 0.0, 0.0) : float3(1.0, 1.0, 1.0), albedoDetailSpeed * albedoDetailSpeed);
            baseColorOverlay *= baseColorOverlay;
            material.baseColor.rgb = lerp(material.baseColor.rgb, saturate(baseColorOverlay), detailMask);

            float smoothness = 1.0 - material.roughness;
            float smoothnessDetailSpeed = saturate(abs(detailSmoothness) * GENELIT_ACCESS_PROP(_DetailSmoothnessScale));
            float smoothnessOverlay = lerp(smoothness, (detailSmoothness < 0.0) ? 0.0 : 1.0, smoothnessDetailSpeed);
            smoothness = lerp(smoothness, saturate(smoothnessOverlay), detailMask);
            material.roughness = 1.0 - smoothness;

            detailNormal.xy *= GENELIT_ACCESS_PROP(_DetailNormalScale);
            detailNormal.z = sqrt(saturate(1.0 - dot(detailNormal.xy, detailNormal.xy)));
            material.normal = lerp(material.normal, BlendNormals(material.normal, detailNormal), detailMask);
        #endif

        material.emissive = GENELIT_ACCESS_PROP(_EmissionColor);
        GENELIT_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv, emissive)
        material.emissive *= emissive;
        UNITY_BRANCH
        if(GENELIT_ACCESS_PROP(_AlbedoAffectEmissive) > 0)
        {
            material.emissive *= material.baseColor;
        }

        #if defined(_ALPHATEST_ON)
            material.maskThreshold = GENELIT_ACCESS_PROP(_Cutoff);
        #endif

        #if defined(USE_SHEEN)
            material.sheenColor = GENELIT_ACCESS_PROP(_SheenColor).rgb;
            material.sheenRoughness = GENELIT_ACCESS_PROP(_SheenRoughness);
        #endif

        #if defined(_ANISOTROPY)
            material.anisotropy = GENELIT_ACCESS_PROP(_Anisotropy);
            GENELIT_SAMPLE_TEX2D_SAMPLER(_TangentMap, _MainTex, uv, tangentMap)
            material.anisotropyDirection = UnpackNormal(tangentMap);
        #endif

        #if defined(_CLEAR_COAT)
            material.clearCoat = GENELIT_ACCESS_PROP(_ClearCoat);
            material.clearCoatRoughness = GENELIT_ACCESS_PROP(_ClearCoatRoughness);
            #if defined(_CLEAR_COAT_NORMAL)
                material.clearCoatNormal = float3(0.0, 0.0, 1.0);
            #endif
        #endif

        #if defined(USE_REFRACTION)
            material.thickness = GENELIT_ACCESS_PROP(_Thickness);
            material.absorption = -log(GENELIT_ACCESS_PROP(_TransmittanceColor).rgb) / max(material.thickness, 1e-5);
            material.transmission = GENELIT_ACCESS_PROP(_Transmission);
            #if defined(REFRACTION_TYPE_THIN)
                material.microThickness = GENELIT_ACCESS_PROP(_MicroThickness);
            #endif
        #endif

        material.skyboxFog = GENELIT_ACCESS_PROP(_SkyboxFog);

        GENELIT_INIT_CUSTOM_MATERIAL(material)
    }

    /**
    * Computes global shading parameters that the material might need to access
    * before lighting: N dot V, the reflected vector and the shading normal (before
    * applying the normal map). These parameters can be useful to material authors
    * to compute other material properties.
    *
    * This function must be invoked by the user's material code (guaranteed by
    * the material compiler) after setting a value for MaterialInputs.normal.
    */
    void prepareMaterial(const MaterialInputs material, inout ShadingData shadingData)
    {
        shadingData.normal = normalize(mul(shadingData.tangentToWorld, material.normal));
        shadingData.NoV = clampNoV(dot(shadingData.normal, shadingData.view));
        shadingData.reflected = reflect(-shadingData.view, shadingData.normal);

        #if defined(_BENTNORMALMAP)
            shadingData.bentNormal = normalize(mul(shadingData.tangentToWorld, material.bentNormal));
        #endif

        #if defined(_CLEAR_COAT)
            #if defined(_CLEAR_COAT_NORMAL)
                shadingData.clearCoatNormal = normalize(mul(shadingData.tangentToWorld, material.clearCoatNormal));
            #endif
        #endif

        #if defined(LIGHTMAP_ON)
            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                shadingData.ambient = SubtractMainLightWithRealtimeAttenuationFromLightmap(shadingData.ambient, shadingData.atten, 0, shadingData.normal);
            #endif
        #endif
    }

    v2f vertForward(appdata_full v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        v2f o;
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = TexCoords(v);
        float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        float3 worldNormal = UnityObjectToWorldNormal(v.normal);
        fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
        fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
        fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
        o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
        o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
        o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
        o.color = v.color;
        o.ambientOrLightmapUV = VertexGIForward(v, worldPos, worldNormal);
        UNITY_TRANSFER_LIGHTING(o, v.texcoord1);
        return o;
    }

    void fragForward(out float4 fragColor : SV_Target, in v2f IN, in fixed facing : VFACE)
    {
        UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);

        UNITY_SETUP_INSTANCE_ID(IN);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

        // See shadingData.parameters.fs
        // Computes global variables we need to evaluate material and lighting
        ShadingData shadingData;
        computeShadingParams(IN, facing > 0, shadingData);

        // Initialize the inputs to sensible default values, see material_inputs.fs
        MaterialInputs inputs;
        UNITY_INITIALIZE_OUTPUT(MaterialInputs, inputs);
        inputs.baseColor = IN.color;
        initMaterial(shadingData, inputs);
        prepareMaterial(inputs, shadingData);
        UNITY_LIGHT_ATTENUATION(atten, IN, shadingData.position);

        fragColor = evaluateMaterial(inputs, shadingData, atten);

        #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
            float l = distance(shadingData.position, _WorldSpaceCameraPos);
            UNITY_CALC_FOG_FACTOR_RAW(l);
            #ifdef UNITY_PASS_FORWARDADD
                UNITY_FOG_LERP_COLOR(fragColor, fixed4(0,0,0,0), unityFogFactor);
            #else
                float4 fogColor = unity_FogColor;
                UNITY_BRANCH
                if (inputs.skyboxFog > 0)
                {
                    fogColor = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, -shadingData.view, inputs.skyboxFog);
                }
                UNITY_FOG_LERP_COLOR(fragColor, fogColor, unityFogFactor);
            #endif
        #endif
    }
#endif