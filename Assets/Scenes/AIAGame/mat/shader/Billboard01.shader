Shader "Custom/Billboard01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
        [HideInInspector]_BillboardRotation("Rotation", vector) = (0,0,0,0)
		[HideInInspector]_BillboardScale("Scale", vector) = (1,1,1,0)
        [HideInInspector]_BillboardMatrix0("Matrix1", vector) = (0,0,0,0)
		[HideInInspector]_BillboardMatrix1("Matrix2", vector) = (0,0,0,0)
		[HideInInspector]_BillboardMatrix2("Matrix3", vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
        ZTest LEqual
        Stencil
        {
            Ref 2
            Comp NotEqual // 只有当像素值不等于 2 时才渲染 A
            Pass Keep     // 不改变值
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posClip : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _BillboardMatrix0;
            float4 _BillboardMatrix1;
            float4 _BillboardMatrix2;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                float3 objTrans;
                objTrans = v.vertex.xzy;
                float3x3 m ;
                m[0] = _BillboardMatrix0.xyz;
                m[1] = _BillboardMatrix1.xyz;
                m[2] = _BillboardMatrix2.xyz;

                float3 center =  unity_ObjectToWorld._14_24_34;
                objTrans = mul(m, objTrans);

                float3 viewDir = normalize((_WorldSpaceCameraPos - center));
                float3 viewRight = normalize(cross(viewDir*float3(1,0,1),float3(0,1,0)));
                float3 viewUp = cross(viewRight,viewDir);
                float3x3 rot;
                rot[0] = float3(viewRight.x, viewUp.x, viewDir.x);
                rot[1] = float3(viewRight.y, viewUp.y, viewDir.y);
                rot[2] = float3(viewRight.z, viewUp.z, viewDir.z);
                objTrans = mul(rot, objTrans);

                o.vertex = mul(UNITY_MATRIX_VP,float4(objTrans+center,1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                
                float4 col = tex2D(_MainTex, i.uv);
                // float emissive = smoothstep(0.9, 1, col.r);
                // float3 color = lerp(col.rgb, _Color.rgb, 1-emissive);
                return float4(col*_Color.rgb, pow(col.r,1.1));
            }
            ENDCG
        }
        // Pass
        // {
        //     Name "DepthOnly"
        //     Tags
        //     {
        //         "LightMode" = "DepthOnly"
        //     }

        //     // -------------------------------------
        //     // Render State Commands
        //     ZWrite On
        //     ColorMask R

        //     HLSLPROGRAM
        //     #pragma target 2.0

        //     // -------------------------------------
        //     // Shader Stages
        //     #pragma vertex DepthOnlyVertex
        //     #pragma fragment DepthOnlyFragment

        //     // -------------------------------------
        //     // Material Keywords
        //     #pragma shader_feature_local _ALPHATEST_ON

        //     // -------------------------------------
        //     // Unity defined keywords
        //     #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

        //     //--------------------------------------
        //     // GPU Instancing
        //     #pragma multi_compile_instancing
        //     #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

        //     // -------------------------------------
        //     // Includes
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
        //     ENDHLSL
        // }

    }
    CustomEditor"MyaBillboardGUI"
}
