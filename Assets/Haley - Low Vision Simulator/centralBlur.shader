Shader "Custom/centralBlur"
{
    Properties
    {
        _MaskTex("Scotoma Mask", 2D) = "white" {}    // Black Blur Mask (black center, blurred edges)
        _BlurStrength("Blur Strength", Range(0, 30)) = 15
        _Transparency("Transparency", Range(0, 1)) = 1.0

        // Stencil settings to force rendering on top
        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _ColorMask("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Overlay"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
        }

        Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }

        Lighting Off
        Cull Off
        ZTest Always
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            sampler2D _MaskTex;
            float _BlurStrength;
            float _Transparency;

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                return o;
            }

        fixed4 frag(v2f i) : SV_Target
        {
            float2 uv = saturate(i.texcoord);  // Keep UVs in range
    
            // Sample the scotoma mask
            fixed4 maskColor = tex2D(_MaskTex, uv);

            // Debugging: Display the mask texture directly
            return maskColor; 
            // Sample the scotoma mask (black = fully occluded, white = visible)
            float maskValue = tex2D(_MaskTex, uv).r; 

            // Base color (default black)
            fixed4 outputColor = fixed4(0, 0, 0, 1); 

            // Apply Gaussian blur in the gray transition area
            if (maskValue > 0.2)  
            {
                float4 blurredColor = float4(0, 0, 0, 0);
                float totalWeight = 0.0;

                // 9-tap Gaussian blur kernel
                float2 offsets[9] = {
                    float2(-1, -1), float2(0, -1), float2(1, -1),
                    float2(-1,  0), float2(0,  0), float2(1,  0),
                    float2(-1,  1), float2(0,  1), float2(1,  1)
                };

                float weights[9] = { 1, 2, 1, 2, 4, 2, 1, 2, 1 };

                for (int j = 0; j < 9; j++)
                {
                    float2 offset = offsets[j] * 0.005 * _BlurStrength;
                    blurredColor += tex2D(_MaskTex, uv + offset) * weights[j];
                    totalWeight += weights[j];
                }

                blurredColor /= totalWeight;

                // Blend blur effect with the original color
                outputColor.rgb = lerp(outputColor.rgb, blurredColor.rgb, maskValue * _BlurStrength);
            }

            // Keep the center of the scotoma fully black
            if (maskValue < 0.2)
            {
                outputColor.rgb = float3(0, 0, 0);
            }

            // Apply transparency based on the mask
            outputColor.a = maskValue * _Transparency;

            return outputColor;
        }

            ENDCG
        }
    }
}
