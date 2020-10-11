// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Low Poly Shader developed as part of World of Zero: http://youtube.com/worldofzerodevelopment
// Based upon the example at: http://www.battlemaze.com/?p=153

Shader "Custom/Grass Geometry Shader" {
	Properties{
		[HDR]_BackgroundColor("Background Color", Color) = (1,0,0,1)
		[HDR]_ForegroundColor("Foreground Color", Color) = (0,0,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_Cutoff("Cutoff", Range(0,1)) = 0.25
		_GrassHeight("Grass Height", Float) = 0.25
		_GrassWidth("Grass Width", Float) = 0.25
		_WindSpeed("Wind Speed", Float) = 100
		_WindStength("Wind Strength", Float) = 0.05
	}
		SubShader{
		Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
		LOD 200

		Pass
	{

		CULL OFF

		CGPROGRAM
#include "UnityCG.cginc" 
#pragma vertex vert
#pragma fragment frag
#pragma geometry geom
//#pragma alphatest : _Cutoff

		// Use shader model 4.0 target, we need geometry shader support
#pragma target 4.0

		sampler2D _MainTex;

	struct v2g
	{
		float4 pos : SV_POSITION;
		float3 norm : NORMAL;
		float2 uv : TEXCOORD0;
		float3 color : TEXCOORD1;
	};

	struct g2f
	{
		float4 pos : SV_POSITION;
		float3 norm : NORMAL;
		float2 uv : TEXCOORD0;
		float3 diffuseColor : TEXCOORD1;
		//float3 specularColor : TEXCOORD2;
	};

	half _Glossiness;
	half _Metallic;
	fixed4 _BackgroundColor;
	fixed4 _ForegroundColor;
	half _GrassHeight;
	half _GrassWidth;
	half _Cutoff;
	half _WindStength;
	half _WindSpeed;

	v2g vert(appdata_full v)
	{
		float3 v0 = v.vertex.xyz;

		v2g OUT;
		OUT.pos = v.vertex;
		OUT.norm = v.normal;
		OUT.uv = v.texcoord;
		OUT.color = tex2Dlod(_MainTex, v.texcoord).rgb;
		return OUT;
	}

	[maxvertexcount(8)]
	void geom(point v2g IN[1], inout TriangleStream<g2f> triStream)
	{
		float3 perpendicularAngle = float3(0, 0, 1);
		float3 faceNormal = cross(perpendicularAngle, IN[0].norm);

		float3 v0 = IN[0].pos.xyz;
		float3 v1 = IN[0].pos.xyz + float3(0,_GrassHeight,0);

		float3 color = (IN[0].color);

		g2f OUT;

		// Quad 1

		OUT.pos = UnityObjectToClipPos(v0 + perpendicularAngle * 0.5 * _GrassHeight);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(1, 0);
		triStream.Append(OUT);

		OUT.pos = UnityObjectToClipPos(v1 + perpendicularAngle * 0.5 * _GrassHeight);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(1, 1);
		triStream.Append(OUT);

		OUT.pos = UnityObjectToClipPos(v0);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(0.5, 0);
		triStream.Append(OUT);

		OUT.pos = UnityObjectToClipPos(v1);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(0.5, 1);
		triStream.Append(OUT);

		OUT.pos = UnityObjectToClipPos(v1 - perpendicularAngle * 0.5 * _GrassHeight);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(0, 1);
		triStream.Append(OUT);

		OUT.pos = UnityObjectToClipPos(v0 - perpendicularAngle * 0.5 * _GrassHeight);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(0, 0);
		triStream.Append(OUT);

		OUT.pos = UnityObjectToClipPos(v0);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(0.5, 0);
		triStream.Append(OUT);

		OUT.pos = UnityObjectToClipPos(v1);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = float2(0.5, 1);
		triStream.Append(OUT);
	}

	half4 frag(g2f IN) : COLOR
	{
		return float4(1,1,1,1);
	}
		ENDCG

	}
	}
}