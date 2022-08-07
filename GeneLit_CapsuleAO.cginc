#ifndef FILAMENT_CAPSULE_AO_INCLUDED
    #define FILAMENT_CAPSULE_AO_INCLUDED

    #include "UnityCG.cginc"

    #define CAPSULE_COUNT 16

    float4 _topAndRadius[CAPSULE_COUNT];
    float4 _bottom[CAPSULE_COUNT];

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
        return o * o * 0.8 + 0.2;
    }

    // The MIT License
    // Copyright © 2019 Inigo Quilez
    // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    float capShadow(float3 ro, float3 rd, float3 a, float3 b, float r, float k)
    {
        float3 ba =  b - a;
        float3 oa = ro - a;

        // closest distance between ray and segment
        float3 n = normalize(cross(ba, cross(ba, oa)));
        float3 oar = oa;// - r * n * sign(dot(n, -rd));
        float oad  = dot(oar, rd);
        float dba  = dot(rd, ba);
        float baba = dot(ba, ba);
        float oaba = dot(oar, ba);
        float th = saturate((oaba - oad * dba) / (baba - dba * dba + 0.000001));

        float3 p = a + ba * th;
        // float pd = max(abs(dot(p - ro, rd)), 0.0001);
        // float3 q = ro + rd * pd;
        // float d = length(p - q) - r;

        float3 oc = ro - p;
        float ocd = dot(oc, rd);
        float c = dot(oc, oc) - r * r;
        float h = ocd - c / ocd;

        // fake shadow
        // float s = saturate(k * d / pd + 0.5);
        float s = saturate(h * k);
        return r > 0 ? s * s * (3.0 - 2.0 * s) : 1;// ;
    }

    half3 GetSHLength()
    {
        half3 x, x1;
        x.r = length(unity_SHAr);
        x.g = length(unity_SHAg);
        x.b = length(unity_SHAb);
        x1.r = length(unity_SHBr);
        x1.g = length(unity_SHBg);
        x1.b = length(unity_SHBb);
        return x + x1;
    }

    float clculateAllCapOcclusion(float3 p, float3 n, out float shadow)
    {
        float ao = 1;
        shadow = 1;
        float3 l = normalize(GetSHLength() + float3(0, 1e-6, 0));
        UNITY_UNROLL
        for (uint i = 0; i < CAPSULE_COUNT; ++i)
        {
            float4 t = _topAndRadius[i];
            ao *= capOcclusion(p, n, t.xyz, _bottom[i].xyz, t.w);
            //shadow *= capShadow(p, l, t.xyz, _bottom[i].xyz, t.w, 4.0);
        }
        return ao;
    }
#endif
