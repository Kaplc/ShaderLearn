Shader "Custom/BulinPhone"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        
        // 高光反射参数
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularStrength ("Specular Strength", Range(0,1)) = 0.5
        _Shininess ("Shininess", Range(0.1, 100)) = 32
        
        // 粗糙度控制
        _Roughness ("Roughness", Range(0,1)) = 0.4
        _Metallic ("Metallic", Range(0,1)) = 0.1
        
        // 菲涅尔效果
        _FresnelPower ("Fresnel Power", Range(1, 10)) = 3
        _FresnelColor ("Fresnel Color", Color) = (0.9,0.9,0.9,1)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0
        
        sampler2D _MainTex;
        fixed4 _Color;
        fixed4 _SpecularColor;
        half _SpecularStrength;
        half _Shininess;
        half _Roughness;
        half _Metallic;
        half _FresnelPower;
        fixed4 _FresnelColor;
        
        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };
        
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // 基础纹理采样
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
            o.Albedo = tex.rgb * _Color.rgb;
            o.Alpha = tex.a * _Color.a;
            
            // 计算法线方向（假设平面法线为(0,0,1)）
            float3 normal = float3(0, 0, 1);
            
            // 计算菲涅尔效果
            float fresnel = pow(1.0 - saturate(dot(normal, IN.viewDir)), _FresnelPower);
            o.Emission = _FresnelColor.rgb * fresnel * _SpecularStrength;
            
            // 高光反射
            float3 halfVector = normalize(IN.viewDir + normal);
            float NdotH = saturate(dot(normal, halfVector));
            float specular = pow(NdotH, _Shininess);
            o.Specular = _SpecularColor.rgb * specular * _SpecularStrength;
            
            // 粗糙度影响
            o.Smoothness = 1.0 - _Roughness;
            
            // 金属度
            o.Metallic = _Metallic;
        }
        ENDCG
    }
    
    FallBack "Diffuse"
}
