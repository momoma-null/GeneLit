#ifndef GENELIT_CAPSULE_AO_INCLUDED
    #define GENELIT_CAPSULE_AO_INCLUDED

    #include "UnityCG.cginc"

    #define CAPSULE_COUNT 16

    float4 _UdonTopAndRadius[CAPSULE_COUNT];
    float4 _UdonBottom[CAPSULE_COUNT];

    // The MIT License
    // Copyright © 2018 Inigo Quilez
    // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    float capOcclusion(float3 p, float3 n, float3 a, float3 b, float r)
    {
        float3 ba = b - a;
        float3 pa = p - a;
        float h = saturate(dot(pa, ba) / dot(ba, ba));
        float3 d = pa - h * ba;
        float l = length(d);
        float o = saturate(1.0 - dot(-d, n) * r * r / (l * l * l));
        return o * o;
    }

    float capShadow(float3 ro, float3 rd, float3 a, float3 b, float r, float k)
    {
        float3 ba =  b - a;
        float3 oa = ro - a;

        // closest distance between ray and segment
        float oard  = dot(oa, rd);
        float bard  = dot(ba, rd);
        float baba = dot(ba, ba);
        float oaba = dot(oa, ba);
        float th = saturate((oaba - oard * bard) / (baba - bard * bard + 0.000001));

        float3 p = a + ba * th;
        float3 oc = ro - p;
        float ocrd = dot(oc, rd);
        float h = saturate((dot(oc, oc) - ocrd * ocrd) / (r * r) + ocrd * ocrd / k);

        float s = h * h;
        return r > 0 && ocrd < 0 ? (s * s * (3.0 - 2.0 * s)) : 1;
    }

    void clculateAllCapOcclusion(float3 p, float3 n, float3 l, out float ao, out float shadow)
    {
        ao = 1;
        shadow = 1;
        UNITY_UNROLL
        for (uint i = 0; i < CAPSULE_COUNT; ++i)
        {
            float4 t = _UdonTopAndRadius[i];
            float3 b = _UdonBottom[i].xyz;
            ao *= capOcclusion(p, n, t.xyz, b, t.w);
            shadow = min(capShadow(p, l, t.xyz, b, t.w, 4.0), shadow);
        }
    }
#endif
