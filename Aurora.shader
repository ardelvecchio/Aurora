Shader "Hidden/Aurora"
{
    Properties 
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader 
	{
		Tags { "LightMode"="ForwardBase" "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
		
		Pass
		{
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#pragma enable_d3d11_debug_symbols
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma vertex vert
			#pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };
			
            
            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            Varyings vert(Attributes input)
            {
            	
                Varyings output;
				output.uv = input.uv;
                output.positionHCS = TransformWorldToHClip(input.positionOS.xyz);
            	
                return output;
            }

            Texture2D _AuroraMap;
			SamplerState sampler_AuroraMap;
            Texture2D _BrushMap;
            SamplerState sampler_BrushMap;
            Texture2D _AuroraGradient;
            SamplerState sampler_AuroraGradient;
            Texture2D _opacityNoise;
            SamplerState sampler_opacityNoise;
            Texture2D _perlinCurl;
            SamplerState sampler_perlinCurl;
			Texture2D _OpacityGrad;
            SamplerState sampler_OpacityGrad;
            Texture2D _flickerMask;
            SamplerState sampler_flickerMask;
            TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
            
            float _innerRadius; float _outerRadius; float _height;
            half _numSteps; half4 _color; half _density;
            half _sphereHeight; half _scale; half _verticalIntensity;
            half _verticalFrequency; half _saturation; half _CurlStrength;
            half _opacitySpeed; half _FlickerSpeed; half _FlickerIntensity;
            half _CurlSpeed; half _earlyOutThreshold;
			float3 GetWorldPos(float2 uv)
			{
				 #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(uv);
                #else
                    // Adjust z to match NDC for OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
                #endif
                return ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
			}

            /*
            real ShadowAtten(real3 worldPosition)
            {
                return MainLightRealtimeShadow(TransformWorldToShadowCoord(worldPosition));
            }
            */
			
            float random(float2 st)
            {
	            return frac(sin(dot(st.xy, float2(12.9898, 78.233)))*43758.5453123);
            }
            
            float sphNormal(float3 pos, float4 sph)
			{
				return normalize(pos-sph.xyz);
			}

			float sphIntersect(float3 ro, float3 rd, float4 sph)
			{
				float3 oc = ro - sph.xyz;
				float b = dot(oc, rd);
				float c = dot(oc, oc) - sph.w*sph.w;
				float h = b*b - c;
				
				if(h<0.0)
				{
					return -1.0;
				}
				h = sqrt(h);
				return -b - h;
			}

            inline float2 RadialCoords(float3 a_coords)
            {
                float3 a_coords_n = normalize(a_coords);
                float lon = atan2(a_coords_n.z, a_coords_n.x);
                float lat = acos(a_coords_n.y);
                float2 sphereCoords = float2(lon, lat) * (1.0 / PI);
                return float2(sphereCoords.x * 0.5 + 0.5, 1 - sphereCoords.y);
            }
            
            float2 GetSphericalUVs(float3 pos)
			{
			    // Normalize the position vector
			    float3 nPos = pos;

			    // Calculate spherical coordinates
			    float theta = atan2(nPos.z, nPos.x);
			    float phi = acos(-nPos.y);

			    // Map spherical coordinates to UVs
			    float u = (theta + PI) / (2.0 * PI);
			    float v = phi / PI;

			    return float2(u, v);
			}

            float LinearizeDepth(float depth, float near, float far)
			{
			    float z = depth * 2.0 - 1.0; // Back to NDC 
			    return (2.0 * near * far) / (far + near - z * (far - near));
			}

            float3 SampleMain(float2 uv)
	        {
	            return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
	        }
            
            
            float4 frag (Varyings i) : SV_Target 
            {
            	float4 innerSph = float4(_WorldSpaceCameraPos.x, _sphereHeight, _WorldSpaceCameraPos.z, _innerRadius);
				float4 outerSph = float4(_WorldSpaceCameraPos.x, _sphereHeight, _WorldSpaceCameraPos.z, _outerRadius);
            	//don't want to map onto anything but skybox. This is temporary,
            	//will replace with y value threshold for auroras
            	float depth = SampleSceneDepth(i.uv);
            	
            	if(depth > 0.00001)
            	{
            		return float4(SampleMain(i.uv),1.0);
            	}
            	//get world position of pixel
            	float3 worldPos = GetWorldPos(i.uv);
            	//camera view ray
				float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos);

            	float endLen = sphIntersect(_WorldSpaceCameraPos, viewDir, outerSph);
            	//ray from center of sphere to edge of sphere
            	float startLen = sphIntersect(_WorldSpaceCameraPos, viewDir, innerSph);
            	//dist from camera to outer sphere

            	//get distance between spheres along ray direction
            	float dist = endLen-startLen;
            	//initialize variables for ray-march
            	half3 rayPos = viewDir*startLen;
                half3 rayDirection =  viewDir;
            	half stepLength = 40;//dist/_numSteps;
            	float4 color = 0;

            	int j;
            	[loop]
            	for(j = 0; j < _numSteps; j++)
            	{
            		float3 sphDir = normalize(innerSph.xyz-rayPos);
            		
            		float2 polar = GetSphericalUVs(float3(sphDir.x, sphDir.y, sphDir.z));
            		float2 savePolar = polar;
					half auroraStretch = SAMPLE_TEXTURE2D(_BrushMap, sampler_BrushMap, float2(polar.x*_verticalFrequency, 0.5)).r;
            		float2 noiseUV = GetSphericalUVs(sphDir+_SinTime.x/_CurlSpeed);
				    float2 curlNoise = SAMPLE_TEXTURE2D(_perlinCurl, sampler_perlinCurl, noiseUV).rg ; // Remap to [-1, 1]
					// Calculate time-based UV offset for flickering
				    

				    // Sample the flicker mask texture using flickerUV
            		//float2 flickerUV = polar + float2(_SinTime.x*_FlickerSpeed, 0);
				    //half flickerNoise = SAMPLE_TEXTURE2D(_flickerMask, sampler_flickerMask, flickerUV).r - 0.5;
					//float2 newUVs = GetSphericalUVs(float3(sphDir.x+flickerNoise*_FlickerIntensity, sphDir.y, sphDir.z+flickerNoise*_FlickerIntensity));
            		
				    // Apply the curl noise to the polar coordinates.
				    polar += curlNoise*_CurlStrength;
            		
				    // Ensure polar coordinates are wrapped properly.
				    polar = frac(polar);
            		polar *= _scale;
            		
            		//sample aurora map
            		
					half auroraMap = SAMPLE_TEXTURE2D(_AuroraMap, sampler_AuroraMap, polar).r;
					//get radial distance of rayPos from inner circle

            		//get aurora's color gradient
            		half3 auroraGrad = SAMPLE_TEXTURE2D(_AuroraGradient, sampler_AuroraGradient, GetSphericalUVs(float3(0.5, 0.5, j/_numSteps))).rgb;
            		//decrease opacity of aurora as you move up
            		half opacityGrad = SAMPLE_TEXTURE2D(_OpacityGrad, sampler_OpacityGrad, float2(j/_numSteps, 0.5)).r;
            		//break up auroras in the sky
            		half opacityNoise = SAMPLE_TEXTURE2D(_opacityNoise, sampler_opacityNoise, float2(savePolar.x, savePolar.y+(_SinTime.x/_opacitySpeed))).r;
            		opacityNoise = saturate(opacityNoise*8);
            		
            		//add aurora from sample to ray-march sum
            		float combinedIntensity = auroraMap * saturate(auroraStretch+_verticalIntensity*(1-j/_numSteps))*opacityNoise;
            		color.rgb += auroraGrad*combinedIntensity;
					color.a += combinedIntensity*_density;
					//march
            		rayPos += rayDirection*stepLength;

            		//if(color.a > _earlyOutThreshold)
            		//{
            		//	break;
            		//}
            	}
				color.a /= _numSteps;
            	color.rgb /= 2;
            	float3 backgroundColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;			//here make sure no aurora on horizon
				float4 foregroundColor = float4(color.rgb, saturate(color.a)*saturate(viewDir.y-_height)); // _color with alpha = 0.1
				float3 blendedColor = (1.0 - foregroundColor.a) * backgroundColor + foregroundColor.a * foregroundColor.rgb;
				return float4(blendedColor, 1.0); // Result is fully opaque for simplicity, adjust as needed
            }
            
			ENDHLSL
		}
	} 
	FallBack "Diffuse"
}
