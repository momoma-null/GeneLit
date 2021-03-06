Shader "MomomaShader/General/GeneLit"
{
    Properties
    {
        [BlendMode] _Mode ("Blend Mode", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2.0
        [KeywordEnum(STANDARD, SUBSURFACE, CLOTH)] Shading_Model ("Model Type", Float) = 0
        [KeywordEnum(NORMAL_TILE, NO_TILE)] _TileMode ("Tile Mode", Float) = 0
        [IfDef(_TILEMODE_NO_TILE)] _NoiseHeight ("Noise Height", Range(5.0, 20.0)) = 12.0
        [Enum(None,0,Multiply,1,Add,2,Screen,3)] _VertexColorMode ("Vertex Color Mode", Float) = 0.0
        [SingleLine] _Color ("Color", Color) = (1,1,1,1)
        [ScaleOffset][SingleLine(_Color)] _MainTex ("Albedo", 2D) = "white" {}
        [IfDef(_ALPHATEST_ON)]_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
        [SingleLine(, _MASKMAP)] _MaskMap ("Mask Map", 2D) = "white" {}
        [IfNDef(SHADING_MODEL_CLOTH)] _Metallic ("Metallic", Range(0,1)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _OcclusionStrength ("Occlusion", Range(0,1)) = 1.0
        _IoR ("IoR", Range(0.01, 5)) = 1.5
        [IfDef(_NORMALMAP)][SingleLine] _BumpScale ("Normal Scale", Float) = 1.0
        [SingleLine(_BumpScale, _NORMALMAP)][Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        [IfDef(_PARALLAXMAP)][SingleLine] _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        [IfNDef(_TILEMODE_NO_TILE)][SingleLine(_Parallax, _PARALLAXMAP)] _ParallaxMap ("Height Map", 2D) = "white" {}
        [SingleLine][HDR] _EmissionColor ("Emission Color", Color) = (0,0,0,1)
        [Emission]
        [SingleLine(_EmissionColor)] _EmissionMap ("Emission", 2D) = "white" {}

        [IfDef(SHADING_MODEL_SUBSURFACE)] _SubsurfaceThickness ("Thickness", Range(0,1)) = 0.5
        [IfDef(SHADING_MODEL_SUBSURFACE)] _SubsurfacePower ("Subsurface Power", Float) = 12.234
        [IfDef(SHADING_MODEL_SUBSURFACE)] _SubsurfaceColor ("Subsurface Color", Color) = (1,1,1,1)

        [ToggleHeader(Detail Map, _DETAIL_MULX2)]
        [IfDef(_DETAIL_MULX2)][Enum(UV0,0,UV1,1,UV2,2,UV3,3)] _UVSec ("UV Set", Float) = 0
        [ScaleOffset][IfDef(_DETAIL_MULX2)][SingleLine] _DetailAlbedoMap ("Albedo", 2D) = "grey" {}
        [IfDef(_DETAIL_MULX2)][SingleLine] _DetailMaskMap ("Mask Map", 2D) = "white" {}
        [IfDef(_DETAIL_MULX2)][SingleLine] _DetailNormalMapScale ("Normal Scale", Float) = 1.0
        [IfDef(_DETAIL_MULX2)][SingleLine(_DetailNormalMapScale)][Normal] _DetailNormalMap ("Normal Map", 2D) = "bump" {}
        [IfDef(_DETAIL_MULX2)][IfNDef(SHADING_MODEL_CLOTH)] _DetailMetallic ("Metallic", Range(0,1)) = 0.0
        [IfDef(_DETAIL_MULX2)] _DetailGlossiness ("Smoothness", Range(0,1)) = 0.5

        [ToggleHeader(Anisotropy, _ANISOTROPY)]
        [IfDef(_ANISOTROPY)] _Anisotropy ("Anisotropy", Vector) = (1, 0, 0, 0)

        [ToggleHeader(ClearCoat, _CLEAR_COAT)]
        [IfDef(_CLEAR_COAT)] _ClearCoat ("Clear Coat", Float) = 1.0
        [IfDef(_CLEAR_COAT)] _ClearCoatRoughness ("Clear Coat Roughness", Range(0,1)) = 0.0

        [ToggleHeader(Refraction, _REFRACTION)]
        [IfDef(_REFRACTION)] _Thickness ("Thickness", Float) = 0.5
        [IfDef(_REFRACTION)] _Absorption ("Absorption", Range(0,1)) = 0.0
        [IfDef(_REFRACTION)] _Transmission ("Transmission", Range(0,1)) = 0.0

        [IfNDef(SHADING_MODEL_CLOTH)]
        [ToggleHeader(Sheen, _SHEEN)]
        [IfDef(_SHEEN)] _SheenColor ("Sheen Color", Color) = (0,0,0,1)
        [IfNDef(SHADING_MODEL_CLOTH)][IfDef(_SHEEN)] _SheenRoughness ("Sheen Roughness", Range(0,1)) = 0.0

        [HideInInspector] _DFG ("_DFG", 2D) = "black" {}

        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask ("__am", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        AlphaToMask [_AlphaToMask]

        CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup

        #define FILAMENT_QUALITY FILAMENT_QUALITY_HIGH
        #define GEOMETRIC_SPECULAR_AA
        ENDCG

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode"="ForwardBase" }

            Cull [_CullMode]
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 3.5
            #pragma vertex vertForward
            #pragma fragment fragForward
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local SHADING_MODEL_STANDARD SHADING_MODEL_SUBSURFACE SHADING_MODEL_CLOTH
            #pragma shader_feature_local _TILEMODE_NORMAL_TILE _TILEMODE_NO_TILE
            #pragma shader_feature_local _ANISOTROPY
            #pragma shader_feature_local _CLEAR_COAT
            #pragma shader_feature_local _SHEEN
            #pragma shader_feature_local _REFRACTION
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _DETAIL_MULX2

            #include "GeneLit_Core.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode"="ForwardAdd" }

            Cull [_CullMode]
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) }
            ZWrite Off

            CGPROGRAM
            #pragma target 3.5
            #pragma vertex vertForward
            #pragma fragment fragForward
            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local SHADING_MODEL_STANDARD SHADING_MODEL_SUBSURFACE SHADING_MODEL_CLOTH
            #pragma shader_feature_local _TILEMODE_NORMAL_TILE _TILEMODE_NO_TILE
            #pragma shader_feature_local _ANISOTROPY
            #pragma shader_feature_local _CLEAR_COAT
            #pragma shader_feature_local _SHEEN
            #pragma shader_feature_local _REFRACTION
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _DETAIL_MULX2

            #include "GeneLit_Core.cginc"
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            Cull [_CullMode]

            CGPROGRAM
            #pragma target 3.5
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #include "UnityStandardShadow.cginc"
            ENDCG
        }

        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert_meta
            #pragma fragment frag_meta
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature _EMISSION
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "UnityStandardMeta.cginc"
            ENDCG
        }
    }
}
