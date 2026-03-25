Shader "Custom/NPREnemy"
{
    Properties
    {
        _outlineWidth("OutlineWidth",Range(0,0.1)) = 0.02
        _RimColor("RimColor",Color)= (1,1,1,1)
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _ShadowColor("ShdaowColor",Color) = (0,0,0,0)
        _MidShadowColor("MidShadowColor",Color) = (0,0,0,1)
        _OutlineColor("OutlineColor",Color) = (0,0,0,1)

        _ToonMap("ToonMap", 2D) = "white" {}
        _ToonTexFrac("ToonTexFrac",  Range(0,1)) = 1

        _BaseMap("BaseMap", 2D) = "white" {}
        _BaseTexFrac("BaseTexFrac", Range(0,1)) = 1

        _LightMap("lightmap", 2D) = "black" {}
        _MetalMap("MetalMap",2D)  = "white"{}
        _SpecPow("SpecPow",float) = 32
        _RimWidth("RimWidth",Range(0,1)) = 0.5

        _Noise("Noise", 2D) = "black" {}
        _Dissthreshold("DissolveThreshold", Range(0,1)) = 0.5

        _NonMetalKS("NonMetalKS",Range(0,1)) = 0.3
        _MetalKS("MetalKS",Range(0,1)) = 0.3
        _Metallic("Metallic", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha 

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _DISSOLVE_ON
            // #define _DISSOLVE_ON

            // static const float4 kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)
            

           struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 staticLightmapUV   : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float4 worldTangent : TEXCOORD3;
                float4 vertex : SV_POSITION;
                float2 lightmapUV   : TEXCOORD4; // 传递Lightmap UV
                float3 vertexSH     : TEXCOORD5; // 传递顶点SH系数

            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_ToonMap);SAMPLER(sampler_ToonMap);
            TEXTURE2D(_MetalMap);SAMPLER(sampler_MetalMap);
            TEXTURE2D(_LightMap);SAMPLER(sampler_LightMap);
            TEXTURE2D(_Noise);SAMPLER(sampler_Noise);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _ShadowColor;
                float4 _MidShadowColor;
                float4 _RimColor;
                float _BaseTexFrac;
                float _ToonTexFrac;
                float _SpecPow;
                float _NonMetalKS;
                float _MetalKS;
                float _RimWidth;
                float _Metallic;
                float _Dissthreshold;
            CBUFFER_END


            v2f vert (appdata v)
            {
                v2f o;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldPos = worldPos;
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.worldNormal = normalInput.normalWS;
                
                real sign = v.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                o.worldTangent = tangentWS;
                o.vertex = TransformWorldToHClip(worldPos);
                o.uv = v.uv;
                // OUTPUT_LIGHTMAP_UV(v.staticLightmapUV, unity_LightmapST, o.lightmapUV);
                o.lightmapUV = 0;
                #if defined(LIGHTMAP_ON)
                    o.lightmapUV = v.staticLightmapUV*unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                
                // 直接传递顶点SH系数（Unity已在CPU端计算好）
                o.vertexSH = SampleSHVertex(normalInput.normalWS);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 NormalWS = i.worldNormal;

                half4 shadowMask = SAMPLE_SHADOWMASK(i.lightmapUV);
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                Light light = GetMainLight(shadowCoord,i.worldPos, shadowMask); 

                float3 lightDir = normalize(light.direction);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfdir = normalize(lightDir+viewDir);

                float NoH = saturate(dot(float3(NormalWS), halfdir));
                half LoH = half(saturate(dot(lightDir, halfdir)));
                float NdotL = dot(NormalWS, lightDir);
                half3 radiance = light.color *  (light.distanceAttenuation * light.shadowAttenuation);

                half3 noramlVS = normalize(mul((float3x3)UNITY_MATRIX_V, NormalWS));
                float2 metalcap_uv = noramlVS.xy*0.5+0.5;

                float4 BaseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                float4 toonTex = SAMPLE_TEXTURE2D(_ToonMap,sampler_ToonMap ,metalcap_uv);
                float4 lightmap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap ,i.uv);

                

                //diffuse
                float3 BaseColor = saturate(lerp(BaseTex, BaseTex *_BaseColor, 1-_BaseTexFrac));

                BaseColor = lerp(BaseColor, BaseColor*toonTex.rgb, _ToonTexFrac);

                float lambt = max(0,NdotL);
                float halfLambt = pow(lambt*0.5+0.5,2);
                float LambtStep = smoothstep(0.35,0.42,halfLambt);

                // BaseColor = lerp(BaseColor*_ShadowColor.rgb, BaseColor, LambtStep);

                // float mid = smoothstep(0.30, 0.40, halfLambt) * (1.0 - smoothstep(0.35, 0.41, halfLambt));
                // BaseColor = lerp( BaseColor,BaseColor*_MidShadowColor.rgb, mid);

                float threshold1 = 0.35; // 深阴影与中间色的分界
                float threshold2 = 0.42; // 中间色与亮部的分界
                float f = 0.02;          // 过渡带的宽度（羽化值），值越小边缘越硬

                // 2. 计算两个平滑插值系数
                // t1: 0表示深阴影，1表示进入中间色
                float t1 = smoothstep(threshold1 - f, threshold1 + f, halfLambt);
                // t2: 0表示还在中间色，1表示进入全亮部
                float t2 = smoothstep(threshold2 - f, threshold2 + f, halfLambt);
                float3 shadowToMid = lerp(BaseColor * _ShadowColor.rgb, BaseColor * _MidShadowColor.rgb, t1);

                // 第二步：将上一步的结果与亮部进行插值
                BaseColor = lerp(shadowToMid, BaseColor, t2);



                //specular
                float BlinnPhong = pow(NoH,_SpecPow)*lambt;
                float3 NonMetalSpec = BlinnPhong*BaseColor*_NonMetalKS;
                float3 metalSpec = BlinnPhong*(LambtStep*0.8+0.2)*BaseColor*_MetalKS;

                float isMetal = step(0.8,lightmap.r);
                float3 specular = lerp(NonMetalSpec,metalSpec,isMetal);

                float3 metallic = SAMPLE_TEXTURE2D(_MetalMap,sampler_MetalMap, metalcap_uv).r*BaseColor;
                metallic = lerp(0,metallic,isMetal);


                float3 diffuse = BaseColor+specular+metallic;

                float fresnel = 1-saturate(dot(viewDir, NormalWS));

                fresnel = saturate(pow(fresnel,5)-1+_RimWidth);
                diffuse = lerp(diffuse, diffuse+_RimColor.rgb,fresnel);

                // giColor
                float3 ambientColor;
                #if defined(LIGHTMAP_ON)
                    ambientColor = SampleLightmap(i.lightmapUV,0,NormalWS);
                #else
                    ambientColor = SampleSHPixel(i.vertexSH, NormalWS);
                #endif
                float3 indirectDiffuse = ambientColor.rgb;
                float3 giColor = indirectDiffuse*BaseTex.rgb;

                
                // dissolve
                #if defined(_DISSOLVE_ON)
                    float noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, i.uv).r;
                    clip(noise - _Dissthreshold);
                    float edge = smoothstep(_Dissthreshold, _Dissthreshold + 0.05, noise);
                    float3 edgeColor = (1 - edge) * _RimColor.rgb * 5.0; // 使用边框色作为发光色
                    diffuse += edgeColor;
                #endif

                return float4(diffuse+giColor,1);
                
            }
            ENDHLSL
        }

        //outline
        Pass{
            Name "drawoutline"
            Tags{
                "RenderPipeline"="UniversalPipeline"
                "RenderType"="Opaque"
                "LightMode"="drawoutline"
            }

            Cull Front

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _DISSOLVE_ON
            // #define _DISSOLVE_ON

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normalOS     : NORMAL;
                half3 tangentOS    : TANGENT;
                half3 color :COLOR0; 
            };

            struct v2f{
                float2 uv:TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_Noise);SAMPLER(sampler_Noise);
            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float _outlineWidth;
                float _Dissthreshold;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = GetVertexPositionInputs(v.vertex.xyz+v.tangentOS.xyz*_outlineWidth*0.01).positionCS;
                // VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f input, bool IsFacing:SV_ISFRONTFACE):SV_TARGET
            {
                half3 base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);

                half3 color = base*_OutlineColor.rgb;
                #if defined(_DISSOLVE_ON)
                    float noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, input.uv).r;
                    clip(noise - _Dissthreshold);
                #endif
                return half4(color,_OutlineColor.a);
            }

            ENDHLSL
        }


        //DepthOnly
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };
            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }
            half DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                return input.positionCS.z;
            }

            ENDHLSL
        }

        //ShadowCaster
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment myShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            //dissovle
            #pragma multi_compile _ _DISSOLVE_ON
            #define _ALPHATEST_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            TEXTURE2D(_Noise);SAMPLER(sampler_Noise);
            CBUFFER_START(UnityPerMaterial)
                float _Dissthreshold;
                // float4 _BaseColor;
            CBUFFER_END

            half4 myShadowPassFragment(Varyings input) : SV_TARGET
            {
                #if defined(_DISSOLVE_ON)
                    float noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, input.uv).r;
                    clip(noise - _Dissthreshold);
                #endif

                #if defined(LOD_FADE_CROSSFADE)
                    LODFadeCrossFade(input.positionCS);
                #endif
                
                return 0;
            }
            
            ENDHLSL
        }
    }
}
