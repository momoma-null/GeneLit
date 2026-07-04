Shader "MomomaShader/General/GeneLit_Subsurface"
{
    Properties
    {
        [BlendMode] _Mode ("[ShurikenHeader(Surface Options)]Blend Mode", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2.0
        _Cutoff ("[IfDef(_ALPHATEST_ON)]Alpha Cutoff", Range(0, 1)) = 0.5
        [Decal] _Offset ("Decal Mode", Float) = 0

        [KeywordEnum(Normal_Tile, No_Tile, TriPlanar)] _TileMode ("[ShurikenHeader(Surface Inputs)]Tile Mode", Float) = 0
        _NoiseHeight ("[IfDef(_TILEMODE_NO_TILE)]Noise Height", Range(5.0, 20.0)) = 12.0
        [Enum(None, 0, Multiply, 1, Add, 2, Screen, 3)] _VertexColorMode ("Vertex Color Mode", Float) = 0.0
        _Color ("[Hide]Color", Color) = (1, 1, 1, 1)
        _MainTex ("[SingleLine(_Color)][ScaleOffset]Albedo", 2D) = "white" { }
        _MaskMap ("[SingleLine(,_MASKMAP)]Mask Map", 2D) = "white" { }
        _Metallic ("Metallic", Range(0, 1)) = 0.0
        _Glossiness ("Smoothness", Range(0, 1)) = 0.5
        _OcclusionStrength ("Occlusion", Range(0, 1)) = 1.0
        _Reflectance ("Reflectance", Range(0.35, 1.0)) = 0.5

        _BumpScale ("[Hide]Normal Scale", Float) = 1.0
        [Normal] _BumpMap ("[SingleLine(_BumpScale,_NORMALMAP)]Normal Map", 2D) = "bump" { }
        [Normal] _BentNormalMap ("[SingleLine(,_BENTNORMALMAP)]Bent Normal Map", 2D) = "bump" { }

        _Parallax ("[Hide]Height Scale", Range(0.005, 0.08)) = 0.02
        _ParallaxMap ("[IfDef(!_TILEMODE_NO_TILE)][SingleLine(_Parallax,_PARALLAXMAP)]Height Map", 2D) = "white" { }
        [Toggle(_PARALLAX_OCCLUSION)] _UseParallaxOcclusion ("[IfDef(_PARALLAXMAP)]Use Parallax Occlusion ( ! Slow ! )", Float) = 0

        [HDR] _EmissionColor ("[Hide]Emission Color", Color) = (0, 0, 0, 1)
        _EmissionMap ("[SingleLine(_EmissionColor)]Emission", 2D) = "white" { }
        [Emission]
        [ToggleUI] _AlbedoAffectEmissive ("Albedo Affect Emissive", Float) = 0.0

        _Anisotropy ("[Hide]Anisotropy", Range(-1, 1)) = 0.5
        _TangentMap ("[SingleLine(_Anisotropy,_ANISOTROPY)]Anisotropy", 2D) = "red" { }

        _SubsurfaceThickness ("[ShurikenHeader(Subsurface Inputs)][Hide]Thickness", Range(0, 1)) = 0.5
        _SubsurfaceThicknessMap ("[SingleLine(_SubsurfaceThickness)]Thickness Map", 2D) = "white" { }
        _SubsurfacePower ("Subsurface Power", Float) = 12.234
        _SubsurfaceColor ("Subsurface Color", Color) = (1, 1, 1, 1)
        _SubsurfaceAlbedoBlend ("Albedo Blend", Range(0, 1)) = 0.0
        _SubsurfaceDistortion ("Distortion", Range(0, 1)) = 1.0

        _DetailMap ("[ShurikenHeader(Detail Inputs)][SingleLine(,_DETAIL_MAP)][ScaleOffset]Detail Map", 2D) = "grey" { }
        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3)] _UVSec ("[IfDef(_DETAIL_MAP)]UV Set", Float) = 0
        _DetailAlbedoScale ("[IfDef(_DETAIL_MAP)]Albedo Scale", Range(0, 2)) = 1.0
        _DetailNormalScale ("[IfDef(_DETAIL_MAP)]Normal Scale", Range(0, 2)) = 1.0
        _DetailSmoothnessScale ("[IfDef(_DETAIL_MAP)]Smoothness Scale", Range(0, 2)) = 1.0

        _ClearCoat ("[ShurikenHeader(Clear Coat,_CLEAR_COAT)][IfDef(_CLEAR_COAT)]Clear Coat", Range(0, 1)) = 1.0
        _ClearCoatRoughness ("[IfDef(_CLEAR_COAT)]Clear Coat Roughness", Range(0, 1)) = 0.0

        [Toggle(CAPSULE_AO)] _Capsule_AO ("[ShurikenHeader(Experimental)]Capsule AO", float) = 0.0
        _Capsule_AOStrength ("[IfDef(CAPSULE_AO)]Capsule AO Strength", Range(0, 1)) = 0.8
        _Capsule_ShadowStrength ("[IfDef(CAPSULE_AO)]Capsule Shadow Strength", Range(0, 1)) = 0.5
        [KeywordEnum(Cube, Cylinder, Additional_Box)] Reflection_Space ("Reflection Space", Float) = 0.0
        [IntRange] _SkyboxFog ("Skybox Fog", Range(0, 7)) = 0.0
        _DirectionalLightEstimation ("Directional Light Estimation", Range(0, 1)) = 1.0
        [Toggle(VERTEX_LIGHT_AS_PIXEL_LIGHT)] _VertexLightAsPixelLight ("Use Vertex Light As Pixel Light", float) = 0.0
        _VertexLightRangeMultiplier ("Vertex Light Range Multiplier", Range(0.01, 25)) = 1.0
        _SpecularAO ("Specular AO", Range(0, 1)) = 0.8
        [Toggle(LTCGI)] _LTCGI ("LTCGI", Int) = 0
        [Toggle(LIGHTVOLUMES)] _LIGHTVOLUMES ("Light Volumes", Int) = 0

        [HideInInspector][NonModifiableTextureData] _DFG ("_DFG", 2D) = "black" { }

        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask ("__am", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

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
            Tags { "LightMode" = "ForwardBase" "LTCGI" = "_LTCGI" }

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
            #pragma shader_feature_local LIGHTVOLUMES

            #include "Include/GeneLit_Core.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }

            Cull [_CullMode]
            Blend [_SrcBlend] One
            Fog
            {
                Color(0, 0, 0, 0)
            }
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
            #pragma shader_feature_local _ _PARALLAX_OCCLUSION _PARALLAXMAP
            #pragma shader_feature_local _DETAIL_MAP
            #pragma shader_feature_local CAPSULE_AO

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
    CustomEditor "MomomaAssets.GeneLit.GeneLitGUI"
}
