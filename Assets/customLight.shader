Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {} // 텍스트 1개만 받는 기본 쉐이더로 설정함.
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        /*
             커스텀 라이트 구현 시, Standard 라고 써있던 걸 Test 라고 바꿔 줌. 

             이 이름은 맘대로 지정할 수 있지만, 
             이제 아래에 작성할 커스텀 라이트 함수는 

             무조건 여기에서 지정한 이름을 사용해야 
             유니티가 커스텀 라이트 함수로 인식함!
        */
        #pragma surface surf Test noambient

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }

        /*
            커스텀 라이트 함수 작성 시 필수사항


            1. 리턴값의 타입은 float4 로 한다.
            
            커스텀 조명 함수는 어쨋거나 무조건 최종적으로 어떤 "색상"을
            계산해줘야 하기 때문에, 리턴값은 무조건 
            r, g, b, a 채널을 모두 담을 수 있는 float4 로 지정한다.


            2. 함수 이름은 반드시 
            'Lighting' + '위에서 지정한 커스텀 라이트 이름' 
            와 같은 구조를 지켜서 정해준다.

            위와 같이 함수 이름을 작성해줘야
            유니티가 라이트 함수로 인식하기 때문에 
            반드시 저렇게 함수이름을 작성해줄 것!
        */
        float4 LightingTest(SurfaceOutput s, float3 lightDir, float atten) {
            return float4(1, 0, 0, 1);
        }

        ENDCG
    }
    FallBack "Diffuse"
}

/*
    라이팅 함수의 인자 설명 (p.299 ~ 300 참고)

    라이팅 함수를 사용할 경우, 아래의 3가지 인자만 받도록 
    규격이 정해져있음. 따라서 커스텀 조명 함수라고 해도 
    함부로 바꿀 수 없고, 주어진 값들만 사용해야 함.


    1. SurfaceOutput s

    얘는 앞서 유니티에 내장된 램버트 및 블린 퐁 라이트 함수에서
    사용하던 라이트 입력 구조체임.

    위에 void surf() 함수에서 o.Albedo, o.Alpha 등에 값을 넣어주면,
    그 값들이 담긴 구조체를 우리가 만든 커스텀 라이트 함수의 
    첫 번째 인자로 넣어주는 것임!

    이 값들을 이제 s.Albedo 이런 식으로 꺼내쓰는 것!


    2. float3 lightDir

    조명방향 벡터를 의미함.
    그런데 노멀벡터와 방향이 반대이면 가장 밝아야할 지점들의
    각도가 180도로 나와버려서 내적값이 -1이 되어버림.

    이를 방지하기 위해 lightDir 은 실제 조명벡터를
    음수화해서 거꾸로 뒤집어 줌. (p.288 참고)

    또한, 내적계산을 수월하게 하기 위해 길이를 
    1로 정규화하여 맞춰놓은 상태의 값이 들어옴.


    3. float atten

    그림자나 거리가 멀어지면서
    빛이 점점 어두워지는 감쇠현상을
    구현하기 위해 받는 값
*/