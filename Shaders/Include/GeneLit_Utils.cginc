#ifndef GENELIT_UTILS_INCLUDED
    #define GENELIT_UTILS_INCLUDED

    //------------------------------------------------------------------------------
    // Common math
    //------------------------------------------------------------------------------

    /** @public-api */
    #define PI                 3.14159265359
    /** @public-api */
    #define HALF_PI            1.570796327

    #define MEDIUMP_FLT_MAX    65504.0
    #define MEDIUMP_FLT_MIN    0.00006103515625

    #ifdef TARGET_MOBILE
        #define FLT_EPS            MEDIUMP_FLT_MIN
        #define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)
    #else
        #define FLT_EPS            1e-5
        #define saturateMediump(x) x
    #endif

    // #define atan2(x, y)        atan(y, x)

    //------------------------------------------------------------------------------
    // Scalar operations
    //------------------------------------------------------------------------------

    /**
    * Computes x^5 using only multiply operations.
    *
    * @public-api
    */
    float pow5(float x) {
        float x2 = x * x;
        return x2 * x2 * x;
    }

    /**
    * Computes x^2 as a single multiplication.
    *
    * @public-api
    */
    float sq(float x) {
        return x * x;
    }

    //------------------------------------------------------------------------------
    // floattor operations
    //------------------------------------------------------------------------------

    /**
    * Returns the maximum component of the specified floattor.
    *
    * @public-api
    */
    float max3(const float3 v) {
        return max(v.x, max(v.y, v.z));
    }

    float vmax(const float2 v) {
        return max(v.x, v.y);
    }

    float vmax(const float3 v) {
        return max(v.x, max(v.y, v.z));
    }

    float vmax(const float4 v) {
        return max(max(v.x, v.y), max(v.y, v.z));
    }

    /**
    * Returns the minimum component of the specified floattor.
    *
    * @public-api
    */
    float min3(const float3 v) {
        return min(v.x, min(v.y, v.z));
    }

    float vmin(const float2 v) {
        return min(v.x, v.y);
    }

    float vmin(const float3 v) {
        return min(v.x, min(v.y, v.z));
    }

    float vmin(const float4 v) {
        return min(min(v.x, v.y), min(v.y, v.z));
    }

    //------------------------------------------------------------------------------
    // Trigonometry
    //------------------------------------------------------------------------------

    /**
    * Approximates acos(x) with a max absolute error of 9.0x10^-3.
    * Valid in the range -1..1.
    */
    float acosFast(float x) {
        // Lagarde 2014, "Inverse trigonometric functions GPU optimization for AMD GCN architecture"
        // This is the approximation of degree 1, with a max absolute error of 9.0x10^-3
        float y = abs(x);
        float p = -0.1565827 * y + 1.570796;
        p *= sqrt(1.0 - y);
        return x >= 0.0 ? p : PI - p;
    }

    /**
    * Approximates acos(x) with a max absolute error of 9.0x10^-3.
    * Valid only in the range 0..1.
    */
    float acosFastPositive(float x) {
        float p = -0.1565827 * x + 1.570796;
        return p * sqrt(1.0 - x);
    }

    //------------------------------------------------------------------------------
    // Matrix and quaternion operations
    //------------------------------------------------------------------------------

    /**
    * Multiplies the specified 3-component floattor by the 4x4 matrix (m * v) in
    * high precision.
    *
    * @public-api
    */
    float4 mulMat4x4Float3(const  float4x4 m, const  float3 v) {
        return v.x * m[0] + (v.y * m[1] + (v.z * m[2] + m[3]));
    }

    /**
    * Multiplies the specified 3-component floattor by the 3x3 matrix (m * v) in
    * high precision.
    *
    * @public-api
    */
    float3 mulMat3x3Float3(const  float4x4 m, const  float3 v) {
        return v.x * m[0].xyz + (v.y * m[1].xyz + (v.z * m[2].xyz));
    }

    /**
    * Extracts the normal floattor of the tangent frame encoded in the specified quaternion.
    */
    void toTangentFrame(const  float4 q, out  float3 n) {
        n = float3( 0.0,  0.0,  1.0) +
        float3( 2.0, -2.0, -2.0) * q.x * q.zwx +
        float3( 2.0,  2.0, -2.0) * q.y * q.wzy;
    }

    /**
    * Extracts the normal and tangent floattors of the tangent frame encoded in the
    * specified quaternion.
    */
    void toTangentFrame(const  float4 q, out  float3 n, out  float3 t) {
        toTangentFrame(q, n);
        t = float3( 1.0,  0.0,  0.0) +
        float3(-2.0,  2.0, -2.0) * q.y * q.yxw +
        float3(-2.0,  2.0,  2.0) * q.z * q.zwx;
    }

    float3x3 cofactor(const  float3x3 m) {
        float a = m[0][0];
        float b = m[1][0];
        float c = m[2][0];
        float d = m[0][1];
        float e = m[1][1];
        float f = m[2][1];
        float g = m[0][2];
        float h = m[1][2];
        float i = m[2][2];

        float3x3 cof;
        cof[0][0] = e * i - f * h;
        cof[0][1] = c * h - b * i;
        cof[0][2] = b * f - c * e;
        cof[1][0] = f * g - d * i;
        cof[1][1] = a * i - c * g;
        cof[1][2] = c * d - a * f;
        cof[2][0] = d * h - e * g;
        cof[2][1] = b * g - a * h;
        cof[2][2] = a * e - b * d;
        return cof;
    }

    #if defined(TARGET_MOBILE)
        // min roughness such that (MIN_PERCEPTUAL_ROUGHNESS^4) > 0 in fp16 (i.e. 2^(-14/4), rounded up)
        #define MIN_PERCEPTUAL_ROUGHNESS 0.089
        #define MIN_ROUGHNESS            0.007921
    #else
        #define MIN_PERCEPTUAL_ROUGHNESS 0.045
        #define MIN_ROUGHNESS            0.002025
    #endif

    #define MIN_N_DOT_V 1e-4

    float clampNoV(float NoV) {
        // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
        return max(NoV, MIN_N_DOT_V);
    }

    float3 computeDiffuseColor(const float4 baseColor, float metallic) {
        return baseColor.rgb * (1.0 - metallic);
    }

    float3 computeF0(const float4 baseColor, float metallic, float reflectance) {
        return baseColor.rgb * metallic + (reflectance * (1.0 - metallic));
    }

    float computeDielectricF0(float reflectance) {
        return 0.16 * reflectance * reflectance;
    }

    float computeMetallicFromSpecularColor(const float3 specularColor) {
        return max3(specularColor);
    }

    float computeRoughnessFromGlossiness(float glossiness) {
        return 1.0 - glossiness;
    }

    float perceptualRoughnessToRoughness(float perceptualRoughness) {
        return perceptualRoughness * perceptualRoughness;
    }

    float roughnessToPerceptualRoughness(float roughness) {
        return sqrt(roughness);
    }

    float iorToF0(float transmittedIor, float incidentIor) {
        return sq((transmittedIor - incidentIor) / (transmittedIor + incidentIor));
    }

    float f0ToIor(float f0) {
        float r = sqrt(f0);
        return (1.0 + r) / (1.0 - r);
    }

    float3 f0ClearCoatToSurface(const float3 f0) {
        // Approximation of iorTof0(f0ToIor(f0), 1.5)
        // This assumes that the clear coat layer has an IOR of 1.5
        #if FILAMENT_QUALITY == FILAMENT_QUALITY_LOW
            return saturate(f0 * (f0 * 0.526868 + 0.529324) - 0.0482256);
        #else
            return saturate(f0 * (f0 * (0.941892 - 0.263008 * f0) + 0.346479) - 0.0285998);
        #endif
    }

    inline float sum(const float3 v)
    {
        return v.x + v.y + v.z;
    }

    inline float sum(const float4 v)
    {
        return v.x + v.y + v.z + v.w;
    }

    inline float2 hash22(float2 p)
    {
        static const float2 k = float2(0.3183099, 0.3678794);
        p = p * k + k.yx;
        return frac(16.0 * k * frac(p.x * p.y * (p.x + p.y))) * 2.0 - 1.0;
    }

    inline float3 rotateAroundAxis(float3 p, float3 v, float t)
    {
        float s, c;
        sincos(t, s, c);
        return c * p + v * dot(v, p) * (1 - c) + cross(v, p) * s;
    }

    inline float ComputeTextureLOD(float2 uv, float2 texelSize)
    {
        float2 ddx_ = texelSize * ddx(uv);
        float2 ddy_ = texelSize * ddy(uv);
        float  d = max(dot(ddx_, ddx_), dot(ddy_, ddy_));
        return max(0.5 * log2(d), 0.0);
    }
#endif
