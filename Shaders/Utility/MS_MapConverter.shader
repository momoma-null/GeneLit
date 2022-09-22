Shader "Hidden/MS_MapConverter"
{
    Properties
    {
        _MainTex ("", 2D) = "white" {}
        _SpecGlossMap ("", 2D) = "white" {}
        _MetallicGlossMap ("", 2D) = "white" {}
        _OcclusionMap ("", 2D) = "white" {}
        _DetailMask ("", 2D) = "white" {}
        _SmoothnessTextureChannel ("", Float) = 0
        _UseRoughnessMap ("", Float) = 0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            UNITY_DECLARE_TEX2D(_MainTex);
            UNITY_DECLARE_TEX2D(_SpecGlossMap);
            UNITY_DECLARE_TEX2D(_MetallicGlossMap);
            UNITY_DECLARE_TEX2D(_OcclusionMap);
            UNITY_DECLARE_TEX2D(_DetailMask);

            fixed _SmoothnessTextureChannel;
            fixed _UseRoughnessMap;

            void vert(appdata_img v, out v2f o)
            {
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
            }

            half4 frag(v2f i) : SV_Target
            {
                float r = UNITY_SAMPLE_TEX2D(_SpecGlossMap, i.uv).r;
                float a = UNITY_SAMPLE_TEX2D(_MainTex, i.uv).a;
                float2 mg = UNITY_SAMPLE_TEX2D(_MetallicGlossMap, i.uv).ra;
                float o = UNITY_SAMPLE_TEX2D(_OcclusionMap, i.uv).g;
                float d = UNITY_SAMPLE_TEX2D(_DetailMask, i.uv).a;
                float s = _UseRoughnessMap ? (1 - r) : (_SmoothnessTextureChannel ? a : mg.y);
                return half4(mg.x, o, d, s);
            }
            ENDCG
        }
    }
}
