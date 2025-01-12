Shader "MomomaShader/General/GeneLit_Subsurface"
{
    Properties
    {
        [ShurikenHeader(Surface Options)]
        [BlendMode] _Mode ("Blend Mode", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2.0
        [IfDef(_ALPHATEST_ON)] _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
        [Decal] _Offset ("Decal Mode", Float) = 0

        [ShurikenHeader(Surface Inputs)]
        [KeywordEnum(Normal_Tile, No_Tile, TriPlanar)] _TileMode ("Tile Mode", Float) = 0
        [IfDef(_TILEMODE_NO_TILE)] _NoiseHeight ("Noise Height", Range(5.0, 20.0)) = 12.0
        [Enum(None,0,Multiply,1,Add,2,Screen,3)] _VertexColorMode ("Vertex Color Mode", Float) = 0.0
        [SingleLine] _Color ("Color", Color) = (1,1,1,1)
        [SingleLineScaleOffset(_Color)] _MainTex ("Albedo", 2D) = "white" {}
        [SingleLine(, _MASKMAP)] _MaskMap ("Mask Map", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _OcclusionStrength ("Occlusion", Range(0,1)) = 1.0
        _Reflectance ("Reflectance", Range(0.35, 1.0)) = 0.5

        [IfDef(_NORMALMAP)][SingleLine] _BumpScale ("Normal Scale", Float) = 1.0
        [SingleLine(_BumpScale, _NORMALMAP)][Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        [SingleLine(, _BENTNORMALMAP)][Normal] _BentNormalMap ("Bent Normal Map", 2D) = "bump" {}

        [IfDef(_PARALLAXMAP)][SingleLine] _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        [IfNDef(_TILEMODE_NO_TILE)][SingleLine(_Parallax, _PARALLAXMAP)] _ParallaxMap ("Height Map", 2D) = "white" {}
        [IfDef(_PARALLAXMAP)][Toggle(_PARALLAX_OCCLUSION)] _UseParallaxOcclusion ("Use Parallax Occlusion ( ! Slow ! )", Float) = 0

        [SingleLine][HDR] _EmissionColor ("Emission Color", Color) = (0,0,0,1)
        [Emission]
        [SingleLine(_EmissionColor)] _EmissionMap ("Emission", 2D) = "white" {}
        [ToggleUI] _AlbedoAffectEmissive ("Albedo Affect Emissive", Float) = 0.0

        [IfDef(_ANISOTROPY)][SingleLine] _Anisotropy ("Anisotropy", Range(-1, 1)) = 0.5
        [SingleLine(_Anisotropy, _ANISOTROPY)] _TangentMap ("Anisotropy", 2D) = "red" {}

        [ShurikenHeader(Subsurface Inputs)]
        [SingleLine(_SubsurfaceThickness)] _SubsurfaceThicknessMap ("Thickness Map", 2D) = "white" {}
        [SingleLine] _SubsurfaceThickness ("Thickness", Range(0,1)) = 0.5
        _SubsurfacePower ("Subsurface Power", Float) = 12.234
        _SubsurfaceColor ("Subsurface Color", Color) = (1,1,1,1)
        _SubsurfaceDistortion ("Distortion", Range(0, 1)) = 1.0

        [ShurikenHeader(Detail Inputs)]
        [SingleLineScaleOffset(,_DETAIL_MAP)] _DetailMap ("Detail Map", 2D) = "grey" {}
        [IfDef(_DETAIL_MAP)][Enum(UV0,0,UV1,1,UV2,2,UV3,3)] _UVSec ("UV Set", Float) = 0
        [IfDef(_DETAIL_MAP)] _DetailAlbedoScale ("Albedo Scale", Range(0, 2)) = 1.0
        [IfDef(_DETAIL_MAP)] _DetailNormalScale ("Normal Scale", Range(0, 2)) = 1.0
        [IfDef(_DETAIL_MAP)] _DetailSmoothnessScale ("Smoothness Scale", Range(0, 2)) = 1.0

        [ToggleHeader(Clear Coat, _CLEAR_COAT)]
        [IfDef(_CLEAR_COAT)] _ClearCoat ("Clear Coat", Range(0,1)) = 1.0
        [IfDef(_CLEAR_COAT)] _ClearCoatRoughness ("Clear Coat Roughness", Range(0,1)) = 0.0

        [ShurikenHeader(Experimental)]
        [Toggle(CAPSULE_AO)] _Capsule_AO ("Capsule AO", float) = 0.0
        [IfDef(CAPSULE_AO)] _Capsule_AOStrength ("Capsule AO Strength", Range(0, 1)) = 0.8
        [IfDef(CAPSULE_AO)] _Capsule_ShadowStrength ("Capsule Shadow Strength", Range(0, 1)) = 0.5
        [KeywordEnum(Cube, Cylinder, Additional_Box)] Reflection_Space ("Reflection Space", Float) = 0.0
        [IntRange] _SkyboxFog ("Skybox Fog", Range(0, 7)) = 0.0
        [ToggleUI] _DirectionalLightEstimation ("Directional Light Estimation", Float) = 1.0
        [Toggle(VERTEX_LIGHT_AS_PIXEL_LIGHT)] _VertexLightAsPixelLight ("Use Vertex Light As Pixel Light", float) = 0.0
        _VertexLightRangeMultiplier ("Vertex Light Range Multiplier", Range(0.01, 25)) = 1.0
        _SpecularAO ("Specular AO", Range(0, 1)) = 0.8
        [Toggle(LTCGI)] _LTCGI("LTCGI", Int) = 0

        [HideInInspector][NonModifiableTextureData] _DFG ("_DFG", 2D) = "black" {}

        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask ("__am", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        AlphaToMask [_AlphaToMask]
        Offset [_Offset], [_Offset]

        CGINCLUDE
        #define FILAMENT_QUALITY FILAMENT_QUALITY_HIGH
        #define GEOMETRIC_SPECULAR_AA
        #define CLEAR_COAT_IOR_CHANGE

        #include "Include/GeneLit_Model_Subsurface.cginc"
        ENDCG

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode"="ForwardBase" "LTCGI" = "_LTCGI" }

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
            #pragma shader_feature_local _TILEMODE_NORMAL_TILE _TILEMODE_NO_TILE _TILEMODE_TRIPLANAR
            #pragma shader_feature_local _ANISOTROPY
            #pragma shader_feature_local _CLEAR_COAT
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _BENTNORMALMAP
            #pragma shader_feature_local _ _PARALLAX_OCCLUSION _PARALLAXMAP
            #pragma shader_feature_local _DETAIL_MAP
            #pragma shader_feature_local CAPSULE_AO
            #pragma shader_feature_local REFLECTION_SPACE_CUBE REFLECTION_SPACE_CYLINDER REFLECTION_SPACE_ADDITIONAL_BOX
            #pragma shader_feature_local VERTEX_LIGHT_AS_PIXEL_LIGHT
            #pragma shader_feature_local_fragment LTCGI

            #include "Include/GeneLit_Core.cginc"
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
            #pragma shader_feature_local _TILEMODE_NORMAL_TILE _TILEMODE_NO_TILE _TILEMODE_TRIPLANAR
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _DETAIL_MAP

            #include "Include/GeneLit_Core.cginc"
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
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _PARALLAXMAP

            #include "Include/GeneLit_Shadow.cginc"
            ENDCG
        }

        UsePass "MomomaShader/General/GeneLit/META"
    }
}
