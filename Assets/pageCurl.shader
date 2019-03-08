
//ref: http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.72.2262&rep=rep1&type=pdf
Shader "Custom/pageCurl"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_backSideTex("backSideTex",2D)="white"{}
		_theta("theta",Range(0.01,89.99))=45
		_Ay("Ay",Range(-1,0))=0
		_rotationAngle("rotationAngle",Range(-180,0))=0
		_zOffset("zOffset",Range(0,1))=0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}
		LOD 100
		cull off
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

		

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			

			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 worldPos:TEXCOORD2;
				float3 worldNormal: TEXCOORD3;
			
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _theta;
			float _Ay;
			float _rotationAngle;
			sampler2D _backSideTex;
			float _zOffset;
			v2f vert (appdata v)
			{
				v2f o;

				//------vertex
				const float L=0.02;
				const float pi=3.1415926;
				float Px=-v.vertex.x;//transform unity coordinate system to paper coordinate system
				float Py=v.vertex.y*1.3;
				float Pz=v.vertex.z;
				float R=sqrt(Px*Px+(Py-_Ay)*(Py-_Ay));
				float r=R*sin(_theta/180*pi);

				float alpha=asin(Px/R);
				float beta=alpha/sin(_theta/180*pi);

				float Tx=r*sin(beta);
				float Ty=R+_Ay-r*(1-cos(beta))*sin(_theta/180*pi);
				float Tz=r*(1-cos(beta))*cos(_theta/180*pi);
				float3 T=float3(Tx,Ty,Tz);






				//------normal
				float3 M=float3(0,R+_Ay,R*tan(_theta/180*pi));
				float3 normal=normalize(M-T);

				//------bitangent and tangent

				float3 bitangent=normalize(T-float3(0,_Ay,0));
				float3 tangent=cross(bitangent,normal);

				//------bump
				//bumpZ
				float maxBumpR=0.002;
				float maxBumpZ=0.0004;
				maxBumpZ=lerp(maxBumpZ,-maxBumpZ,_rotationAngle/(-180));
				float bumpZ_PxLessThanMaxBumpR=sqrt(max(0,1-(Px/maxBumpR-1)*(Px/maxBumpR-1)))*maxBumpZ;
				float bumpZ=Px<maxBumpR?bumpZ_PxLessThanMaxBumpR:maxBumpZ;
				//bumpNormal (in tangent space)
				float3 bumpNormal_PxLessThanMaxBumpR=normalize(float3(-(maxBumpR-Px)*maxBumpZ*maxBumpZ,0,maxBumpR*maxBumpR*bumpZ_PxLessThanMaxBumpR));
				if(maxBumpZ<0){
					bumpNormal_PxLessThanMaxBumpR.z=-bumpNormal_PxLessThanMaxBumpR.z;
				}
				float3 bumpNormal=Px<maxBumpR?bumpNormal_PxLessThanMaxBumpR:float3(0,0,1);
				//use bumpZ to do displacement
				T.z+=bumpZ;

				//------transform paper coordinate system to unity coordinate system
				normal.x=-normal.x;
			    T.x=-T.x;
			    bitangent.x=-bitangent.x;
			    tangent.x=-tangent.x;
			    bumpNormal.x=-bumpNormal.x;

			    //------rotate vertex and normal
				//rotate vertex
				//_Ty=Ty
				//_Tx=Tx*cos(_rotationAngle/180*pi)-Tz*sin(_rotationAngle/180*pi)
				//_Tz=Tz*cos(_rotationAngle/180*pi)+Tx*sin(_rotationAngle/180*pi)
				//T=(_Tx,_Ty,_Tz)
				float2x2 rot=float2x2(
					cos(_rotationAngle/180*pi),-sin(_rotationAngle/180*pi),
					sin(_rotationAngle/180*pi),cos(_rotationAngle/180*pi)
				);
				T.xz=mul(rot,T.xz);

				//rotate normal
				normal.xz=mul(rot,normal.xz);
		


				//------vertex zOffset
				T.z+=_zOffset;

				//------apply and transform vertex
				v.vertex.xyz = T;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;

			
				//------
				float3 worldNormal =UnityObjectToWorldDir(normal);
				float3 worldBitangent =UnityObjectToWorldDir(bitangent);
				float3 worldTangent =UnityObjectToWorldDir(tangent);

		
				o.worldNormal =dot(float3(0,0,1),bumpNormal)*worldNormal
									+dot(float3(0,1,0),bumpNormal)*worldBitangent
									+dot(float3(-1,0,0),bumpNormal)*worldTangent;
			

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 frontCol = tex2D(_MainTex, i.uv);
				fixed4 backCol=tex2D(_backSideTex,float2(1-i.uv.x,i.uv.y));


				//-----calculate side
				float3 lightDir=_WorldSpaceLightPos0.xyz;
				float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
				float frontSide=dot(i.worldNormal,viewDir);
				//-----select color based on side
				float4 col=frontSide>=0?frontCol:backCol;
				//-----flip normal based on side
				float3 worldNormal=frontSide>=0?i.worldNormal:-i.worldNormal;
			
				//-----calculate diffuse
				float NdotL=saturate(dot(lightDir,worldNormal));
				col*=NdotL*0.5+0.5;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
