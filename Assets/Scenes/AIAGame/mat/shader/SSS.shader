Shader "Custom/SSS"
{
        Properties
    {
        _BaseMap("BaseMap", 2D) = "white" {}
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _NormalMap("NormalMap", 2D) = "bump" {}
        _MRO("MRO", 2D) = "white" {}
        _EnvReflectMap("EnvReflectMap", Cube) = "white" {}
        _Noise("Noise", 2D) = "white" {}
        _SSSColor("SSSColor", Color) = (1,1,1,1)
        _SSSPower("SSSPower", Float) = 1
        _SSSIntensity("SSSIntensity", Float) = 1

    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        LOD 100
        // ZTest Always
        Stencil
        {
            Ref 2
            Comp Always
            Pass Replace // 把 B 覆盖的所有像素标记为 2
        }
        

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        
        ENDHLSL
        //forward
        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            ZWrite On
            Cull Back
            // ZTest Equal

            HLSLPROGRAM
            #pragma vertex vert
            // #pragma vertex LitPassVertex
            #pragma fragment frag
            // #pragma fragment LitPassFragment

           
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"
            // #include"litpass.hlsl"
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            

            static const float MyPI = 3.1415926;
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

            TEXTURECUBE(_EnvReflectMap);SAMPLER(sampler_EnvReflectMap);
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            TEXTURE2D(_MRO);SAMPLER(sampler_MRO);
            TEXTURE2D(_Noise);SAMPLER(sampler_Noise);

            CBUFFER_START(UnityPerMaterial)
                float _Metallic;
                // float _Roughness;
                float4 _BaseColor;
                float _Smoothness;
                float _SSSPower;
                float _SSSIntensity;
                float4 _SSSColor;
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

            float fresnelSchlick(float3 h, float3 v, float f0){
                float cosTheta = max(0,dot(h,v));
                return f0+(1-f0)*pow(clamp(1-cosTheta,0.0,1.0),5);
            }
            

            float4 frag (v2f i) : SV_Target
            {

                float4 BaseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                float3 albedo = BaseColor.rgb * _BaseColor.rgb;
                // float4 EmissionColor = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv);
                float3 MRO = SAMPLE_TEXTURE2D(_MRO, sampler_MRO, i.uv).rgb;
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv));
                // float ao = SAMPLE_TEXTURE2D(_AO, sampler_AO, i.uv).r;

                float sgn = i.worldTangent.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(i.worldNormal.xyz, i.worldTangent.xyz);
                half3x3 tangentToWorld = half3x3(i.worldTangent.xyz, bitangent.xyz, i.worldNormal.xyz);
                float3 NormalWS = NormalizeNormalPerPixel(TransformTangentToWorld(normalTS, tangentToWorld));


                // float3 normal = normalize(i.worldNormal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                half4 shadowMask = SAMPLE_SHADOWMASK(i.lightmapUV);
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                Light light = GetMainLight(shadowCoord,i.worldPos, shadowMask); 

                float3 lightDir = normalize(light.direction);
                float3 halfdir = normalize(lightDir+viewDir);
                

                float _Roughness = MRO.g+MRO.r;
                float _Smoothness = 1-_Roughness;
                float _Metallic = MRO.b;


                half3 Lo = 0;
                float NoH = saturate(dot(float3(NormalWS), halfdir));
                half LoH = half(saturate(dot(lightDir, halfdir)));
                half NdotL = saturate(dot(NormalWS, lightDir));
                half3 radiance = light.color *  (NdotL*light.distanceAttenuation * light.shadowAttenuation);
                

                float roughness2 = _Roughness*_Roughness;
                float d = NoH * NoH * (roughness2-1) + 1.00001f;
                half LoH2 = LoH * LoH;

                half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * (_Roughness*4.0+2.0));
                float3 specular = lerp(kDieletricSpec.rgb, albedo, _Metallic);
                // Lo = specular*specularTerm;

                float3 ambient;// == brdf.diffuse
                // half oneMinusDielectricSpec = kDielectricSpec.a;
                // float oneMinusReflectivity =  oneMinusDielectricSpec - _Metallic * oneMinusDielectricSpec;
                // float reflectivity = 1.0-oneMinusReflectivity;
                // float reflectivity = specular;
                ambient = (1-specular)*albedo.rgb;
                float3 mainlight = (ambient)*radiance;


                float3 sssColor;

                float3 F0 = float3(0.04, 0.04, 0.04);
                F0 = lerp(F0, albedo, _Metallic);
                float vdotl = saturate(dot(-lightDir, viewDir));
                float noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, (i.uv*0.6)+_Time.y*0.01).r;
                float sssPower = clamp(pow(vdotl, _SSSPower),0.35,0.5) * _SSSIntensity;

                float3 fresnelFactor = 1-saturate(dot(viewDir, NormalWS));
                sssPower+=fresnelFactor*NdotL;
                sssColor = sssPower * _SSSColor * BaseColor*noise;

                
                float3 addmainLight;

                uint pixelLightCount = GetAdditionalLightsCount();
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light addlight = GetAdditionalLight(lightIndex, i.worldPos);

                        lightDir = normalize(addlight.direction);
                        halfdir = normalize(lightDir+viewDir);

                        LoH = half(saturate(dot(lightDir, halfdir)));
                        NdotL = saturate(dot(NormalWS, lightDir));
                        radiance = addlight.color *  NdotL;
                        NoH = saturate(dot(float3(NormalWS), halfdir));
                        d = NoH * NoH * (roughness2-1) + 1.00001f;
                        LoH2 = LoH * LoH;
                        specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * (_Roughness*4.0+2.0));
                        Lo = specular*specularTerm;
                        radiance = addlight.color *  (NdotL*addlight.distanceAttenuation * addlight.shadowAttenuation);
                        addmainLight += (ambient)*radiance;

                        vdotl = saturate(dot(-lightDir, viewDir));
                        float sssPower = pow(vdotl, _SSSPower) * _SSSIntensity;
                        sssColor += sssPower * _SSSColor * BaseColor*noise;
                LIGHT_LOOP_END


                half3 reflectVector = reflect(-viewDir, NormalWS);
                half NoV = saturate(dot(NormalWS, viewDir));
                
                float3 indirectDiffuse;
                #if defined(LIGHTMAP_ON)
                    indirectDiffuse = SampleLightmap(i.lightmapUV,0,NormalWS);
                #else
                    indirectDiffuse = SampleSHPixel(i.vertexSH, NormalWS);
                #endif

                // float3 EnvDiffuse = SAMPLE_TEXTURECUBE(_EnvDiffuseMap,sampler_EnvDiffuseMap,NormalWS).rgb;
                // indirectDiffuse = EnvDiffuse;

                uint mip = _Roughness * (1.7 - 0.7 * _Roughness)*6.0;
                half3 indirectSpecular = SAMPLE_TEXTURECUBE_LOD(_EnvReflectMap,sampler_EnvReflectMap,reflectVector, mip).rgb;
                float surfaceReduction = 1.0 / (roughness2 + 1.0);
                half fresnelTerm = Pow4(1.0 - NoV);
                
                half3 grazingTerm = saturate(_Smoothness + specular);
                half3 gispecular = half3(surfaceReduction * lerp(specular, grazingTerm, fresnelTerm));

                float3 giColor = indirectDiffuse*ambient;

                

                // 结合厚度图（如果有的话，没有可以用贴图采样或常数）
                
                
                return float4(mainlight+addmainLight+sssColor, 1.0);
            }
            ENDHLSL
        }

        //DepthNormals
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT // forward-only variant
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
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
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

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
            
            ENDHLSL
        }
    }
}
