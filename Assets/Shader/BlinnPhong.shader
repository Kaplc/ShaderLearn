Shader "Unlit/BlinnPong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
        _MainTex_ST ("MainTex_ST", Vector) = (1, 1, 0, 0)
        _MainTexColor ("MainTexColor", Color) = (0, 0, 0, 0)
        _HightLightColor ("HightLightColor", Color) = (0, 0, 0, 0)
        _HightLightPow ("HightLightPow", Range(0, 1)) = 1
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


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 wNormal : TEXCOORD1;
                float3 wPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTexColor;
            float4 _HightLightColor;
            float _HightLightPow;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;

                float3 wNormal = normalize(i.wNormal);
                // float3 wNormal = i.wNormal;
                // 视角方向
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos);
                // 光源方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 半角
                float3 halfDir = normalize(viewDir + lightDir);
                // 判断是否在背面
                float isBack = dot(wNormal, lightDir);
                // 高光强度
                float3 hlIntensity = max(0, dot(wNormal, halfDir)) * isBack; // max是因为背部面不计算高光
                // 高光最终颜色
                float3 hightFinally = _LightColor0.rgb * _HightLightColor.rgb * pow(hlIntensity, _HightLightPow * 10);

                // 漫反射光强度
                float3 diffuseIntensity = max(0, dot(wNormal, lightDir));
                // 漫反射光最终颜色
                float3 diffuseFinally = col * diffuseIntensity;

                // // 环境光(环境光颜色 * 贴图自带颜色 * 环境光强度)
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT * col * _MainTexColor.rgb;

                float3 finalColor = ambient + diffuseFinally + hightFinally;

                return float4(finalColor, 1);
            }

            // float4 frag (v2f i) : SV_Target
            // {
            //     // 采样颜色
            //     float3 col = tex2D(_MainTex, i.uv).rgb;

            //     // 归一化世界法线
            //     float3 N = normalize(i.wNormal);

            //     // 光源方向（这里假设是方向光）
            //     float3 L = normalize(_WorldSpaceLightPos0.xyz);

            //     // 视线方向：从点指向相机
            //     float3 V = normalize(_WorldSpaceCameraPos.xyz - i.wPos);

            //     // 半角向量
            //     float3 H = normalize(L + V);

            //     // 漫反射：N·L
            //     float NdotL = max(0, dot(N, L));

            //     // 高光：只在 N·L > 0 时才有
            //     float NdotH = max(0, dot(N, H));
            //     float specIntensity = 0;
            //     if (NdotL > 0)
            //     {
            //         specIntensity = pow(NdotH, _HightLightPow * 10);
            //     }

            //     // 漫反射最终颜色
            //     float3 diffuseFinally = col * _LightColor0.rgb * NdotL;

            //     // 高光最终颜色
            //     float3 hightFinally = _LightColor0.rgb * _HightLightColor.rgb * specIntensity;

            //     // 环境光
            //     float3 ambient = UNITY_LIGHTMODEL_AMBIENT * col * _MainTexColor.rgb;

            //     float3 finalColor = ambient + diffuseFinally + hightFinally;
            //     return float4(finalColor, 1);
            // }
            ENDCG
        }
    }
}
