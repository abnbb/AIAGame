Shader "Custom/ParallaxClouds"
{
    Properties
    {
        [Header(Cloud Settings)]
        _MainTex("Noise Texture (R)", 2D) = "white" {}
        _CloudColor("Cloud Color", Color) = (1, 1, 1, 1)
        _BaseColor("Sky Base Color", Color) = (0.2, 0.5, 0.8, 1)
        
        [Header(Speeds and Parallax)]
        _ScrollSpeed("Scroll Speed (XY)", Vector) = (0.01, 0.005, 0, 0)
        _ParallaxStrength("Parallax Strength", Range(0, 0.1)) = 0.02
        _CloudScale("Cloud Scale", Range(0.1, 5)) = 1.0
        
        [Header(Visuals)]
        _Cutoff("Cloud Sharpness", Range(0, 1)) = 0.5
        _Fuzziness("Cloud Fuzziness", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _CloudColor;
                float4 _BaseColor;
                float2 _ScrollSpeed;
                float _ParallaxStrength;
                float _CloudScale;
                float _Cutoff;
                float _Fuzziness;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                // 获取视角方向用于视差计算
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.viewDirWS = normalize(GetCameraPositionWS() - positionWS);
                
                return output;
            }

            // 简单的多层云混合函数
            float GetCloudLayer(float2 uv, float scale, float speedMultiplier, float2 parallaxOffset)
            {
                float2 scrolledUV = uv * scale + _ScrollSpeed * _Time.y * speedMultiplier + parallaxOffset;
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, scrolledUV).r;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 基于相机视角方向产生视差偏移
                float2 parallax = input.viewDirWS.xz * _ParallaxStrength;

                // 采样三层云，每层缩放、速度、视差权重都不同
                float layer1 = GetCloudLayer(input.uv, _CloudScale, 1.0, parallax * 1.0);
                float layer2 = GetCloudLayer(input.uv, _CloudScale, 0.6, parallax * 0.5);
                float layer3 = GetCloudLayer(input.uv, _CloudScale, 0.3, parallax * 0.2);

                // 混合三层噪声
                float combinedNoise = (layer1 * 0.5) + (layer2 * 0.3) + (layer3 * 0.2);

                // 使用 Smoothstep 处理边缘，控制云的软硬度
                float cloudAlpha = smoothstep(_Cutoff, _Cutoff + _Fuzziness, combinedNoise);

                // 最终颜色：背景色与云色插值
                float3 finalColor = lerp(_BaseColor.rgb, _CloudColor.rgb, cloudAlpha);
                
                return half4(finalColor, cloudAlpha);
            }
            ENDHLSL
        }
    }
}