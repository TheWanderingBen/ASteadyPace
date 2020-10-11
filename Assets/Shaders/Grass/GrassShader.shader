// ------------------------------------------------
// This shader generates blades of grass
// It's mostly based on Jiadong Chen's grass system which you can find here: https://github.com/chenjd/Realistic-Real-Time-Grass-Rendering-With-Unity
// He made an excellent Medium post explaining its details here: https://medium.com/chenjd-xyz/using-the-geometry-shader-in-unity-to-generate-countless-of-grass-on-gpu-4ca6d78b3de6
// ------------------------------------------------

Shader "Unlit/GrassShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _AlphaTex ("Alpha (A)", 2D) = "white" {}
        _GrassHeight("Grass Height", float) = 3
        _GrassWidth("Grass Width", range(0,0.1)) = 0.05
    	_PBSDivisor("Physically Based Sky Divisor", float) = 3000
    }
    SubShader //TODO: What does SubShader mean?
    {
        Cull off //makes the shader render both front and back faces 
        Tags 
        { 
            "Queue" = "AlphaTest" //render this after we render the opaque stuff
            "RenderType" = "TransparentCutout" //this is a binary "on/off" transparency, not fading or anything
            "IgnoreProjector" = "True" //don't have Projectors affect this object
        }    

        Pass
        {
			Cull OFF
			Tags
            { 
                "LightMode" = "ForwardOnly" //forward rendering with ambient, directional, vertex, lightmaps -- NOT additive per-pixel lights
            }
			AlphaToMask On //turns on "alpha-to-coverage", which makes MSAA look less aliased
            
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            
            #pragma target 4.0 //DX11 shader model with geometry shaders

            sampler2D _MainTex;
			sampler2D _AlphaTex;

            float _GrassHeight;
            float _GrassWidth;
            float _PBSDivisor;

            struct v2g //defining a structure for what vertex shader outputs to geometry shader
            {                
				float4 pos : SV_POSITION;
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
            };
            
            struct g2f //defining a structure for what geometry shader outputs to fragment shader
			{
				float4 pos : SV_POSITION;
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
			};

            //pass the vertex data straight to the geometry shader
            v2g vert(appdata_full v)
			{
				v2g output;
				output.pos = v.vertex;
				output.norm = v.normal;
				output.uv = v.texcoord;
				return output;
			}

            //helper function to create empty vertex for geometry shader 
			g2f createGSOut()
            {
				g2f output;
				output.pos = float4(0, 0, 0, 0);
				output.norm = float3(0, 0, 0);
				output.uv= float2(0, 0);
				return output;
			}
            
            fixed rand(fixed seed)
            {
				return frac(dot(seed, fixed2(12.9898,78.233))) * 43758.5453;
			}

            //here's the meat of it: where we actually generate each blade of grass!
			[maxvertexcount(30)]
            void geom(point v2g points[1], inout TriangleStream<g2f> triStream)
			{
            	float4 root = points[0].pos;
            	const int vertexCount = 12;
            	float random = sin(UNITY_HALF_PI * frac(root.x) + UNITY_HALF_PI * frac(root.z));
    
            	_GrassHeight = _GrassHeight + random / 5;
				_GrassWidth = _GrassWidth + random / 50;
				float randomSeed = rand(random);   
            	float randomSin = sin(randomSeed);
				float randomCos = cos(randomSeed);
            	
            	//generate 12 vertices with default values
            	g2f v[vertexCount] = {
					createGSOut(), createGSOut(), createGSOut(), createGSOut(),
					createGSOut(), createGSOut(), createGSOut(), createGSOut(),
					createGSOut(), createGSOut(), createGSOut(), createGSOut()
				};
    
            	float currentV = 0;
				float offsetV = 1.f /(vertexCount / 2 - 1);
				float currentVertexHeight = 0;
    
            	for (int i = 0; i < vertexCount; ++i)
				{         
					v[i].norm =  float3(0, 0, 1); //set normals to be straight out, easy cuz flat
    
            		if (fmod(i , 2) == 0)
					{
            			//even vertices start a horizontal line
            			//we start at the root, then go -Width in X
						v[i].pos = UnityObjectToClipPos(float4(root.x - _GrassWidth * randomSin, root.y + currentVertexHeight, root.z - _GrassWidth * randomCos, 1));
    
            			//the UVs are mapped to [0, percent of height] so they take the correct color
						v[i].uv = float2(0, currentV);
					}
					else
					{
						//odd vertices continue the horizontal line
						//we start at the root, then go +Width in X 
						v[i].pos = UnityObjectToClipPos(float4(root.x + _GrassWidth * randomSin, root.y + currentVertexHeight, root.z+ _GrassWidth * randomCos, 1));
    
						//the UVs are mapped to [1, percent of height] so they take the correct color
						v[i].uv = float2(1, currentV);
    
						//now that we've created two vertices in a line, increment our counters
						currentV += offsetV;
						currentVertexHeight = currentV * _GrassHeight;
					}
    
            		//TODO: We will add wind here            		
            	}            	
  
            	for (int p = 0; p< vertexCount - 2; ++p)
            	{
            		//note that we give the triangle stream the i + 2 vertex before the i + 1 vertex
            		//TODO: I'm not sure why!
					triStream.Append(v[p]);
					triStream.Append(v[p + 2]);
					triStream.Append(v[p + 1]);
				}
            }

            // TODO: go through these concepts as well
            // we calculate the pixel color based our input textures and the direction light in our scene (the sun)
             half4 frag(g2f IN) : COLOR //TODO: I'm not sure what ": COLOR" here is
             {
             	//sample the color and alpha of the appropriate textures at these values
				fixed4 color = tex2D(_MainTex, IN.uv);
				fixed4 alpha = tex2D(_AlphaTex, IN.uv);
    
				//use Unity's built in shader function to calculate impacts of ambient light
				half3 worldNormal = UnityObjectToWorldNormal(IN.norm);
				fixed3 ambient = ShadeSH9(half4(worldNormal, 1)) / _PBSDivisor;

				//calculate a diffuse light based on the directional light
				//UnityWorldSpaceLightDir is defined in UnityCG and is the directional light's direction
				//_LightColor0 is defined in UnityLightingCommon and is the directional light's color
				fixed3 diffuseLight = saturate(dot(worldNormal, UnityWorldSpaceLightDir(IN.pos))) * _LightColor0;

				//calculate specular light based on the directional light
				//based on Blinn-Phong reflection model
				fixed3 halfVector = normalize(UnityWorldSpaceLightDir(IN.pos) + WorldSpaceViewDir(IN.pos));
				fixed3 specularLight = pow(saturate(dot(worldNormal, halfVector)), 15) * _LightColor0;

				//add all the different light sources togegther
				fixed3 light = ambient + diffuseLight + specularLight;

				return float4(color.rgb * light, alpha.g);
             }
            
            ENDCG
        }
    }
}
