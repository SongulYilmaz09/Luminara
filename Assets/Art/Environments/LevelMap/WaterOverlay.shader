Shader "UI/Luminara Water Overlay"
{
    Properties
    {
        [PerRendererData] _MainTex ("Water Mask", 2D) = "white" {}
        _FlowTex ("Flow Texture", 2D) = "white" {}
        _Color ("Water Color", Color) = (0.08, 0.55, 0.95, 1)
        _FlowSpeed ("Flow Speed", Float) = 0.25
        _FlowStrength ("Flow Strength", Range(0,2)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalPipeline"
            "IgnoreProjector"="True"
        }

        Pass
        {
            Name "WaterOverlay"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_FlowTex);
            SAMPLER(sampler_FlowTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _FlowSpeed;
                float _FlowStrength;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.color = IN.color;
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float mask = SAMPLE_TEXTURE2D(
                    _MainTex,
                    sampler_MainTex,
                    IN.uv
                ).r;

                float t = _Time.y * _FlowSpeed;

                float2 uv1 = IN.uv;
                uv1.x = frac(uv1.x + t);

                float2 uv2 = IN.uv;
                uv2.x = frac(uv2.x + t * 0.65);

                float wave1 = SAMPLE_TEXTURE2D(
                    _FlowTex,
                    sampler_FlowTex,
                    uv1
                ).r;

                float wave2 = SAMPLE_TEXTURE2D(
                    _FlowTex,
                    sampler_FlowTex,
                    uv2 + float2(0.17, 0.04)
                ).r;

                float waves = saturate(
                    wave1 * 0.75 +
                    wave2 * 0.35
                );

                float3 waterColor = lerp(
                    _Color.rgb,
                    float3(0.8, 0.96, 1.0),
                    waves
                );

                float alpha = mask * waves * 0.75 * _FlowStrength;

                return half4(
                    waterColor,
                    saturate(alpha)
                ) * IN.color;
            }

            ENDHLSL
        }
    }
}
