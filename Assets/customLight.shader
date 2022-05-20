Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {} // 텍스트 1개만 받는 기본 쉐이더로 설정함.
        _BumpMap ("NormalMap", 2D) = "bump" {} // 유니티는 인터페이스로부터 입력받는 변수명을 '_BumpMap' 이라고 지으면, 텍스쳐 인터페이스는 노말맵을 넣을 것이라고 인지함.
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
        sampler2D _BumpMap;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;

            // UnpackNormal() 함수는 변환된 노말맵 텍스쳐 형식인 DXTnm 에서 샘플링해온 텍셀값 float4를 인자로 받아 float3 를 리턴해줌.
            // 이렇게 o.Normal 구조체 속성에 넣어준 노말값은 커스텀 라이팅 함수의 SurfaceOutput 으로 꺼내쓸 수 있음.
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); 
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
            /*
                각 버텍스의 노멀벡터
                (surf 에서 o.Normal 에 아무값도 안넣어줬더라도, 해당 모델의 버텍스에 기본적으로 노말값이 평범하게 들어가 있는 상태)
                와 조명벡터 (음수화해서 거꾸로 뒤집은 거) 를 내적해주면
                두 벡터의 각도에 따른 cos 값이 나옴. 
                
                이거를 float 하나짜리 변수로 받은 다음,
                바로 리턴해줘버리면 됨.

                float4 를 리턴하지 않았더라도,
                한 자리수 float 을 리턴해버리면
                알아서 셰이더가 float4(ndotl, ndotl, ndotl, ndotl) 로 
                변환해서 리턴해 줌.
            */
            // float ndotl = dot(s.Normal, lightDir); 

            /*
                내적의 결과값은 -1 ~ 1 사이의 값을 모두 포함하기 때문에
                각 픽셀이 색상값으로 음수값을 가지면 문제가 발생할 수 있음.

                예를 들어, 다른 조명을 추가할 시 값을 더해줘도 
                계속 음수값이어서 0과 똑같이 계속 어두운 색상으로 찍히는 경우가 있음.

                이러한 문제를 해결하기 위해, saturate(), max() 등의 함수로
                0미만의 음수값들은 다 0으로 초기화시켜주는 게 좋음.

                각 함수에 대한 자세한 설명은 p.304 참고.
            */
            // float ndotl = saturate(dot(s.Normal, lightDir));

            /*
                램버트 연산은 벡터를 내적하여 얻은 cos 값으로
                조명값을 계산하기 때문에, 그 특성상 음영 대비가 극심함.

                그래서 이런 음영 변화를 부드럽게 처리하기 위해,
                물리적으로 옳은 것은 아니지만,
                내적결과값에 '* 0.5 + 0.5' 를 해줌으로써,
                값의 범위를 0 ~ 1 사이로 Mapping 해줌.

                이 공식은 밸브 사 논문으로 발표된 '하프-램버트 공식' 이라고 함.

                근데 이게 뭐 전혀 새로운 공식이 아닌게
                카메라 NDC 좌표계를 2D 좌표계로 변환할 때에도
                이런 공식을 썼는데, 이걸 그냥 조명 계산에 응용한 것일 뿐임.

                이걸 사용하면 음영처리가 훨씬 부드럽게 되어서
                미적으로 더 보기 좋아짐.
            */
            float ndotl = dot(s.Normal, lightDir) * 0.5 + 0.5;

            // return ndotl; // +0.5 해보면 최솟값이 0.5가 됨에 따라 검은색이 아예 안보일거임. 즉, 최솟값이 0으로 모두 잘 초기화되었다는 뜻
            return pow(ndotl, 3); // 하프-램버트가 적용된 음영은 너무 부드러워서 비현실적임. 그래서 실무에서 쓸 때에는 이 정도를 좀 줄이고자 매핑된 내적값을 3제곱 해주기도 함.
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