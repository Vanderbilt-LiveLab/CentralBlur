Shader "Custom/StereoShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  // Define a texture property
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Include Unity's shader include files
            #include "UnityCG.cginc"

            // Define structures for the shader
            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;

            // Vertex function handling stereo transformation
            v2f vert(appdata_t v)
            {
                v2f o;
                #if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                    o.pos = UnityStereoTransformVertex(v.vertex);
                #else
                    o.pos = mul(UNITY_MATRIX_VP, v.vertex);
                #endif
                o.uv = v.uv;
                return o;
            }

            // Fragment function
            fixed4 frag(v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
