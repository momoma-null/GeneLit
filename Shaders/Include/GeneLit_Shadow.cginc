#ifndef GENELIT_SHADOW_INCLUDED
    #define GENELIT_SHADOW_INCLUDED

    #include "UnityCG.cginc"
    #include "GeneLit_Input.cginc"
    #include "GeneLit_Shading.cginc"

    #if (defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)) && defined(UNITY_USE_DITHER_MASK_FOR_ALPHABLENDED_SHADOWS) || defined(USE_REFRACTION)
        #define UNITY_STANDARD_USE_DITHER_MASK 1
    #endif

    // Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON) || defined(USE_REFRACTION)
        #define USE_SHADOW_UVS 1
    #endif

    #ifdef UNITY_STANDARD_USE_DITHER_MASK
        sampler3D   _DitherMaskLOD;
    #endif

    half ShadowGetOneMinusReflectivity(half2 uv)
    {
        #if defined(USE_METALLIC)
            half metallicity = GENELIT_ACCESS_PROP(_Metallic);
            #if defined(_MASKMAP)
                metallicity = UNITY_SAMPLE_TEX2D_SAMPLER(_MaskMap, _MainTex, uv).r;
            #endif
            return unity_ColorSpaceDielectricSpec.a - unity_ColorSpaceDielectricSpec.a * metallicity;
        #else
            return unity_ColorSpaceDielectricSpec.a;
        #endif
    }

    struct VertexInput
    {
        float4 vertex   : POSITION;
        float3 normal   : NORMAL;
        half4 tangent   : TANGENT;
        float2 texcoord : TEXCOORD0;
        float4 color    : COLOR;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f_shadow
    {
        UNITY_POSITION(pos);
        V2F_SHADOW_CASTER_NOPOS
        #if defined(USE_SHADOW_UVS)
            float2 tex : TEXCOORD1;
            #if defined(_PARALLAXMAP)
                half3 viewDirForParallax : TEXCOORD2;
            #endif
        #endif
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    v2f_shadow vertShadowCaster(VertexInput v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        v2f_shadow o;
        UNITY_INITIALIZE_OUTPUT(v2f_shadow, o)
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        #if defined(GENELIT_CUSTOM_VERTEX)
            GENELIT_CUSTOM_VERTEX(v)
        #endif
        TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos)
        #if defined(USE_SHADOW_UVS)
            o.tex = TRANSFORM_TEX(v.texcoord, _MainTex);
            #ifdef _PARALLAXMAP
                TANGENT_SPACE_ROTATION;
                o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
            #endif
        #endif
        return o;
    }

    half4 fragShadowCaster(v2f_shadow i) : SV_Target
    {
        half alpha = 1;
        #if defined(USE_SHADOW_UVS)
            #if defined(_PARALLAXMAP)
                half3 viewDirForParallax = normalize(i.viewDirForParallax);
                i.tex.xy = ParallaxOffset2Step(i.tex.xy, viewDirForParallax);
            #endif
            alpha = UNITY_SAMPLE_TEX2D(_MainTex, i.tex.xy).a * GENELIT_ACCESS_PROP(_Color).a;
            #if defined(_ALPHATEST_ON)
                clip(alpha - GENELIT_ACCESS_PROP(_Cutoff));
            #endif
            #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON) || defined(USE_REFRACTION)
                #if defined(_ALPHAPREMULTIPLY_ON)
                    half oneMinusReflectivity = ShadowGetOneMinusReflectivity(i.tex);
                    alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
                #endif
                #if defined(USE_REFRACTION)
                    half transmission = GENELIT_ACCESS_PROP(_Transmission);
                    alpha = 1 - transmission * lerp(1.0, 1.0 - alpha, GENELIT_ACCESS_PROP(_AlphaAffectTransmission));
                #endif
                #if defined(UNITY_STANDARD_USE_DITHER_MASK)
                    // Use dither mask for alpha blended shadows, based on pixel position xy
                    // and alpha level. Our dither texture is 4x4x16.
                    #ifdef LOD_FADE_CROSSFADE
                        #define _LOD_FADE_ON_ALPHA
                        alpha *= unity_LODFade.y;
                    #endif
                    half alphaRef = tex3D(_DitherMaskLOD, float3(i.pos.xy * 0.25, alpha * 0.9375)).a;
                    clip (alphaRef - 0.01);
                #endif
            #endif
        #endif // #if defined(USE_SHADOW_UVS)

        #ifdef LOD_FADE_CROSSFADE
            #ifdef _LOD_FADE_ON_ALPHA
                #undef _LOD_FADE_ON_ALPHA
            #else
                UnityApplyDitherCrossFade(i.pos.xy);
            #endif
        #endif

        SHADOW_CASTER_FRAGMENT(i)
    }
#endif
