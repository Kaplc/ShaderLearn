Shader "Unlit/BlinnPong1"
{
    Properties
    {
        // 光照模型
        _MainTex ("Texture", 2D) = "" {}
        _MainTexColor ("MainTexColor", Color) = (1, 1, 1, 1)

        // 高光
        _HightLightColor ("HightLightColor", Color) = (1, 1, 1, 1)
        _HightLightPow ("HightLightPow", Range(1, 100)) = 1
        _HightLightIntensity ("HightLightIntensity", Range(0, 1)) = 1

        // 环境光
        _AmbientIntensity ("AmbientIntensity", Range(0, 10)) = 1

        // 法线贴图
        _NormalTex ("NormalTex", 2D) = "" {}
        _NormalIntensity ("NormalIntensity", Range(0, 2)) = 1

        // 渐变纹理
        _GradientTex ("GradientTex", 2D) = "" {}
        _GradientIntensity ("GradientIntensity", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members normal)
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc" 

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTexColor;

            float4 _HightLightColor;
            float _HightLightPow;
            float _HightLightIntensity;

            float _AmbientIntensity;

            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            float _NormalIntensity;

            sampler2D _GradientTex;
            float4 _GradientTex_ST;
            float _GradientIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; // 切线
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 wNormal : TEXCOORD1;
                float3 wPos : TEXCOORD2;

                float3x3 tbn  : TEXCOORD3;
            };

            float3 NormalIntensityCalc(float3 normal, float intensity)
            {
                float2 newNormalXY = clamp(normal.xy * intensity, -1, 1);
                float newNormalZ = sqrt(1 - newNormalXY.x * newNormalXY.x - newNormalXY.y * newNormalXY.y); // 重新算 z，让它回到单位半球（保证 z ≥ 0）x^2 + y^2 + z^2 = 1

                return float3(newNormalXY, newNormalZ);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                float3 wNormal = UnityObjectToWorldNormal(v.normal);
                float3 wTangent =  UnityObjectToWorldDir(v.tangent);
                float3 wBinormal = cross(wNormal, wTangent) * v.tangent.w; // 乘上 v.tangent.w，就是在修正这个“左右手坐标系”的问题，让切线空间和法线贴图约定的坐标系一致。

                // 构建切线空间转换矩阵
                float3 tbn0 = float3(wTangent.x, wBinormal.x, wNormal.x);  
                float3 tbn1 = float3(wTangent.y, wBinormal.y, wNormal.y);
                float3 tbn2 = float3(wTangent.z, wBinormal.z, wNormal.z);

                o.tbn = float3x3(tbn0, tbn1, tbn2);

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;

                // float3 wNormal = normalize(i.wNormal);
                float3 pNormal = UnpackNormal(tex2D(_NormalTex, i.uv)).xyz; // 解包法线信息
                float3 wNormal = normalize(mul(i.tbn, NormalIntensityCalc(pNormal, _NormalIntensity)));
                // 视角方向
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos);
                // 光源方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 半角
                float3 halfDir = normalize(viewDir + lightDir);
                // 判断是否在背面
                float isBack = max(0, dot(wNormal, lightDir)); // 取0是防止负数还渲染黑色高光
                // 高光强度
                float3 hlIntensity = max(0, dot(wNormal, halfDir)); // max是因为背部面不计算高光
                // 高光最终颜色
                float3 hightFinally = _LightColor0.rgb * _HightLightColor.rgb * pow(hlIntensity, _HightLightPow) * isBack * _HightLightIntensity;

                // 漫反射光强度
                float3 diffuseIntensity = max(0, dot(wNormal, lightDir));
                // 渐变纹理接管漫反射颜色
                float3 gradientCol = tex2D(_GradientTex, float2(dot(wNormal, lightDir), 0.5f)).rgb * _GradientIntensity; // 点乘数据来取颜色
                // 漫反射光最终颜色
                float3 diffuseFinally = col * _LightColor0.rgb * gradientCol;

                // // 环境光(环境光颜色 * 贴图自带颜色 * 环境光强度)
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT * col * _MainTexColor.rgb * _AmbientIntensity;

                float3 finalColor = ambient + diffuseFinally + hightFinally;

                return float4(finalColor, 1);
            }

            // struct appdata
            // {
            //     float4 vertex  : POSITION;
            //     float2 uv      : TEXCOORD0;
            //     float3 normal  : NORMAL;
            //     float4 tangent : TANGENT;   // 为法线贴图准备切线
            // };

            // struct v2f
            // {
            //     float2 uv      : TEXCOORD0;
            //     float4 pos     : SV_POSITION;
            //     float3 wPos    : TEXCOORD1; // 世界空间位置
            //     float3 tspace0 : TEXCOORD2; // TBN 第 0 行
            //     float3 tspace1 : TEXCOORD3; // TBN 第 1 行
            //     float3 tspace2 : TEXCOORD4; // TBN 第 2 行
            // };


            // v2f vert (appdata v)
            // {
            //     v2f o;
            //     o.pos  = UnityObjectToClipPos(v.vertex);
            //     o.uv   = TRANSFORM_TEX(v.uv, _MainTex);
            //     o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;

            //     // 世界空间 TBN
            //     float3 N = UnityObjectToWorldNormal(v.normal);
            //     float3 T = UnityObjectToWorldDir(v.tangent.xyz);
            //     float3 B = cross(N, T) * v.tangent.w;

            //     // 把 T、B、N 作为矩阵的三行
            //     o.tspace0 = float3(T.x, B.x, N.x);
            //     o.tspace1 = float3(T.y, B.y, N.y);
            //     o.tspace2 = float3(T.z, B.z, N.z);

            //     return o;
            // }

            // float3 ApplyNormalIntensity(float3 nTS, float intensity)
            // {
            //     // nTS 为切线空间法线（单位向量）
            //     float2 xy = clamp(nTS.xy * intensity, -1.0, 1.0);
            //     float  z  = sqrt(saturate(1.0 - dot(xy, xy)));
            //     return float3(xy, z);
            // }

            // float4 frag (v2f i) : SV_Target
            // {
            //     // 贴图颜色
            //     float3 albedo = tex2D(_MainTex, i.uv).rgb;

            //     // 1. 法线贴图采样（切线空间）
            //     float3 tNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
            //     // 2. 应用法线强度
            //     tNormal = ApplyNormalIntensity(tNormal, _NormalIntensity);

            //     // 3. 切线 → 世界：TBN * n
            //     float3 wNormal;
            //     wNormal.x = dot(i.tspace0, tNormal);
            //     wNormal.y = dot(i.tspace1, tNormal);
            //     wNormal.z = dot(i.tspace2, tNormal);
            //     wNormal   = normalize(wNormal);

            //     // 光照向量（世界空间）
            //     float3 L = normalize(_WorldSpaceLightPos0.xyz);             // 方向光方向
            //     float3 V = normalize(_WorldSpaceCameraPos.xyz - i.wPos);    // 视线方向
            //     float3 H = normalize(L + V);                                // 半角向量

            //     float NdotL = max(0.0, dot(wNormal, L));
            //     float NdotH = max(0.0, dot(wNormal, H));

            //     // 漫反射
            //     float3 lightColor = _LightColor0.rgb;
            //     float3 diffuse    = albedo * lightColor * NdotL;

            //     // 高光（只在正面，乘上 NdotL 做门）
            //     float specFactor = (NdotL > 0.0) ? pow(NdotH, _HightLightPow * 10.0) * NdotL : 0.0;
            //     float3 specular  = lightColor * _HightLightColor.rgb * specFactor;

            //     // 环境光
            //     float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo * _MainTexColor.rgb * _AmbientIntensity;

            //     float3 finalColor = ambient + diffuse + specular;
            //     return float4(finalColor, 1.0);
            // }

            ENDCG
        }
    }
}
