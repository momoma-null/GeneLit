Shader "MomomaShader/General/GeneLit"
{
    Properties
    {
        [BlendMode] _Mode ("Blend Mode", Float) = 0.0
        [KeywordEnum(STANDARD, SUBSURFACE, CLOTH)] Shading_Model ("Model Type", Float) = 0
        [SingleLine] _Color ("Color", Color) = (1,1,1,1)
        [SingleLine(_Color)] _MainTex ("Albedo", 2D) = "white" {}
        [If(_AlphaToMask, 1)]_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
        [SingleLine(, _MASKMAP)] _MaskMap ("Mask Map", 2D) = "white" {}
        [IfNot(Shading_Model, 2)] _Metallic ("Metallic", Range(0,1)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _OcclusionStrength ("Occlusion", Range(0,1)) = 1.0
        _IoR ("IoR", Range(0.01, 5)) = 1.5
        [SingleLine] _BumpScale ("Normal Scale", Float) = 1.0
        [SingleLine(_BumpScale, _NORMALMAP)][Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        [LightmapFlags]
        [SingleLine][HDR] _EmissionColor ("Emission Color", Color) = (0,0,0,1)
        [SingleLine(_EmissionColor)] _EmissionMap ("Emission", 2D) = "white" {}

        [If(Shading_Model, 1)] _SubsurfaceThickness ("Thickness", Float) = 0.5
        [If(Shading_Model, 1)] _SubsurfacePower ("Subsurface Power", Float) = 12.234
        [If(Shading_Model, 1)] _SubsurfaceColor ("Subsurface Color", Color) = (1,1,1,1)

        [ToggleHeader(_ANISOTROPY)] _UseAnisotropy ("Anisotropy", float) = 0.0
        [If(_UseAnisotropy, 1)] _Anisotropy ("Anisotropy", Vector) = (1, 0, 0, 0)

        [ToggleHeader(_CLEAR_COAT)] _UseClearCoat ("Clear Coat", float) = 0.0
        [If(_UseClearCoat, 1)] _ClearCoat ("Clear Coat", Float) = 1.0
        [If(_UseClearCoat, 1)] _ClearCoatRoughness ("Clear Coat Roughness", Range(0,1)) = 0.0

        [ToggleHeader(_REFRACTION)] _UseRefraction ("Refraction", float) = 0.0
        [If(_UseRefraction, 1)] _Thickness ("Thickness", Float) = 0.5
        [If(_UseRefraction, 1)] _Absorption ("Absorption", Range(0,1)) = 0.0
        [If(_UseRefraction, 1)] _Transmission ("Transmission", Range(0,1)) = 0.0

        [ToggleHeader(_SHEEN)] _UseSheen ("Sheen", float) = 0.0
        [If(_UseSheen, 1)] _SheenColor ("Sheen Color", Color) = (0,0,0,1)
        [If(_UseSheen, 1)] _SheenRoughness ("Sheen Roughness", Range(0,1)) = 0.0

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
            #pragma shader_feature_local _ANISOTROPY
            #pragma shader_feature_local _CLEAR_COAT
            #pragma shader_feature_local _SHEEN
            #pragma shader_feature_local _REFRACTION
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _NORMALMAP

            #include "GeneLit_Core.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode"="ForwardAdd" }

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
            #pragma shader_feature_local _ANISOTROPY
            #pragma shader_feature_local _CLEAR_COAT
            #pragma shader_feature_local _SHEEN
            #pragma shader_feature_local _REFRACTION
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _NORMALMAP

            #include "GeneLit_Core.cginc"
            ENDCG
        }

        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

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
