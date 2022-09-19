#ifndef GENELIT_META_INCLUDED
    #define GENELIT_META_INCLUDED

    #include "UnityCG.cginc"
    #include "UnityMetaPass.cginc"
    #include "GeneLit_Input.cginc"
    #include "GeneLit_Shading.cginc"
    #include "GeneLit_Utils.cginc"

    struct v2f_meta
    {
        float4 pos : SV_POSITION;
        UVCoord uv : TEXCOORD0;
        #ifdef EDITOR_VISUALIZATION
            float2 vizUV      : TEXCOORD1;
            float4 lightCoord : TEXCOORD2;
        #endif
        float4 color : TEXCOORD3;
        float3 wPos : TEXCOORD4;
        float3 wNormal : TEXCOORD5;
    };

    
    void initMaterial_meta(const ShadingData shadingData, inout MaterialInputs material)
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
            material.baseColor *= UNITY_SAMPLE_TEX2D(_MainTex, uv);
        #endif
        #if defined(_MASKMAP)
            GENELIT_SAMPLE_TEX2D_SAMPLER(_MaskMap, _MainTex, uv, mods)
        #else
            float4 mods = 1;
        #endif
        material.roughness = 1.0 - GENELIT_ACCESS_PROP(_Glossiness) * mods.a;
        material.emissive = GENELIT_ACCESS_PROP(_EmissionColor);
        GENELIT_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv, emissive)
        material.emissive *= emissive;
    }

    v2f_meta vert_meta (appdata_full v)
    {
        v2f_meta o;
        o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
        o.uv = TexCoords(v);
        #ifdef EDITOR_VISUALIZATION
            o.vizUV = 0;
            o.lightCoord = 0;
            if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
            o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
            else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
            {
                o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
            }
        #endif
        o.color = v.color;
        o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        o.wNormal = UnityObjectToWorldNormal(v.normal);
        return o;
    }

    float4 frag_meta (v2f_meta i, fixed facing : VFACE) : SV_Target
    {
        ShadingData shadingData;
        UNITY_INITIALIZE_OUTPUT(ShadingData, shadingData);
        shadingData.geometricNormal = i.wNormal;
        shadingData.position = i.wPos;
        shadingData.uv = i.uv;

        MaterialInputs material;
        UNITY_INITIALIZE_OUTPUT(MaterialInputs, material);
        material.baseColor = i.color;
        initMaterial_meta(shadingData, material);

        PixelParams pixel;
        UNITY_INITIALIZE_OUTPUT(PixelParams, pixel);
        getCommonPixelParams(material, pixel);

        UnityMetaInput o;
        UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

        #ifdef EDITOR_VISUALIZATION
            o.Albedo = material.baseColor;
            o.VizUV = i.vizUV;
            o.LightCoord = i.lightCoord;
        #else
            o.Albedo = material.baseColor + pixel.f0 * perceptualRoughnessToRoughness(material.roughness) * 0.5;
        #endif
        o.SpecularColor = pixel.f0;
        o.Emission = material.emissive.rgb;

        return UnityMetaFragment(o);
    }

#endif
