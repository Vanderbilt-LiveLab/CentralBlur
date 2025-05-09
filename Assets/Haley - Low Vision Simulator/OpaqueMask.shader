Shader "Custom/OpaqueMask"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_MaskTex("Mask Texture", 2D) = "white" {}
		_MaskColor("Mask Color", Color) = (0,0,0,1)
		_MaskValue("Mask Value", Range(0,6)) = 0.5
		_MaskSpread("Mask Spread", Range(0,1)) = 0.5

		[Toggle(INVERT_MASK)] INVERT_MASK("Mask Invert", Float) = 0

		_XScale("X Scale", Float) = 1
		_YScale("Y Scale", Float) = 1
		_XTrans("X Scale", Float) = 1
		_YTrans("Y Scale", Float) = 1
    }
    SubShader
    {
		Tags{ "Queue" = "Overlay" }
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

			#pragma shader_feature INVERT_MASK
			float4 _MainTex_TexelSize;
			float _XScale;
			float _YScale;
			float _XTrans;
			float _YTrans;

            struct appdata
            {
                float4 vertex	: POSITION;
                float2 uv		: TEXCOORD0;
				float2 uv2		: TEXCOORD1;
            };

            struct v2f
            {
                float2 uv		: TEXCOORD0;
				float2 uv2		: TEXCOORD1;
                float4 vertex	: SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);                
				// manipulate based on eye screen dimensions/resolution
				o.uv = v.uv;
				o.uv2 = float2((v.uv2.x*_XScale) - _XTrans, (v.uv2.y*_YScale) - _YTrans); // import this factor from start

				#if UNITY_UV_STARTS_AT_TOP	//VERTICAL FLIP IF NECESSARY 
					if (_MainTex_TexelSize.y < 0) {
						o.uv.y = 1 - o.uv.y;
						o.uv2.y = 1 - o.uv2.y;
					}
				#endif

                return o;
            }

			sampler2D _MainTex;
			sampler2D _MaskTex;
			float4 _MaskColor;
			float _MaskValue;
			float _MaskSpread;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				float4 mask = tex2D(_MaskTex, i.uv2);
				float4 p = i.vertex;	   // true pixel value

				// Scale 0..255 to 0..254 range.
				float alpha = mask.a * (1 - 1 / 255.0);
				float weight = 0;
			
				if (mask.a >= 0.01) {
					weight = smoothstep(_MaskValue - _MaskSpread, _MaskValue, alpha);
				}

				// If the mask value is greater than the alpha value,
				// we want to draw the mask.
				#if INVERT_MASK
					weight = 1 - weight;
				#endif

				// Blend in mask color depending on the weight
				col.rgb = lerp(_MaskColor, col.rgb, weight);
				// Additionally also apply a blend between mask and scene
				//col.rgb = lerp(col.rgb, lerp(_MaskColor.rgb, col.rgb, weight), _MaskColor.a);


                return col;
            }
            ENDCG
        }
    }
}
