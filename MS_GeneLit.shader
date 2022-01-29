Shader "MomomaShader/General/GeneLit"
{
    Properties
    {
        [BlendMode] _Mode ("Blend Mode", Float) = 0.0
        [KeywordEnum(STANDARD, SUBSURFACE, CLOTH)] Shading_Model ("Model Type", Float) = 0
        [SingleLine] _Color ("Color", Color) = (1,1,1,1)
        [ScaleOffset]
        [SingleLine(_Color)] _MainTex ("Albedo", 2D) = "white" {}
        [IfDef(_ALPHATEST_ON)]_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
        [SingleLine(, _MASKMAP)] _MaskMap ("Mask Map", 2D) = "white" {}
        [IfNDef(SHADING_MODEL_CLOTH)] _Metallic ("Metallic", Range(0,1)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _OcclusionStrength ("Occlusion", Range(0,1)) = 1.0
        _IoR ("IoR", Range(0.01, 5)) = 1.5
        [SingleLine] _BumpScale ("Normal Scale", Float) = 1.0
        [SingleLine(_BumpScale, _NORMALMAP)][Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        [Emission]
        [SingleLine][HDR] _EmissionColor ("Emission Color", Color) = (0,0,0,1)
        [SingleLine(_EmissionColor)] _EmissionMap ("Emission", 2D) = "white" {}

        [IfDef(SHADING_MODEL_SUBSURFACE)] _SubsurfaceThickness ("Thickness", Float) = 0.5
        [IfDef(SHADING_MODEL_SUBSURFACE)] _SubsurfacePower ("Subsurface Power", Float) = 12.234
        [IfDef(SHADING_MODEL_SUBSURFACE)] _SubsurfaceColor ("Subsurface Color", Color) = (1,1,1,1)

        [ToggleHeader(_ANISOTROPY)]
        [IfDef(_ANISOTROPY)] _Anisotropy ("Anisotropy", Vector) = (1, 0, 0, 0)

        [ToggleHeader(_CLEAR_COAT)]
        [IfDef(_CLEAR_COAT)] _ClearCoat ("Clear Coat", Float) = 1.0
        [IfDef(_CLEAR_COAT)] _ClearCoatRoughness ("Clear Coat Roughness", Range(0,1)) = 0.0

        [ToggleHeader(_REFRACTION)]
        [IfDef(_REFRACTION)] _Thickness ("Thickness", Float) = 0.5
        [IfDef(_REFRACTION)] _Absorption ("Absorption", Range(0,1)) = 0.0
        [IfDef(_REFRACTION)] _Transmission ("Transmission", Range(0,1)) = 0.0

        [ToggleHeader(_SHEEN)]
        [IfDef(_SHEEN)] _SheenColor ("Sheen Color", Color) = (0,0,0,1)
        [IfDef(_SHEEN)] _SheenRoughness ("Sheen Roughness", Range(0,1)) = 0.0

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
