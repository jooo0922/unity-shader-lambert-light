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
        #pragma surface surf Test // noambient
        // noambient 키워드는 환경광을 제거해서 순수한 색상을 확인할 때에만 넣어줌. 
        // 셰이더 코딩을 끝내고 나면, 다시 noambient 를 제거해서 환경광을 더해줘야 
        // 더 자연스러운 렌더링 결과를 볼 수 있음.

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
            // o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); 
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
            // float ndotl = dot(s.Normal, lightDir) * 0.5 + 0.5;

            // return ndotl; // +0.5 해보면 최솟값이 0.5가 됨에 따라 검은색이 아예 안보일거임. 즉, 최솟값이 0으로 모두 잘 초기화되었다는 뜻
            // return pow(ndotl, 3); // 하프-램버트가 적용된 음영은 너무 부드러워서 비현실적임. 그래서 실무에서 쓸 때에는 이 정도를 좀 줄이고자 매핑된 내적값을 3제곱 해주기도 함
        
            // 이제 atten(감쇄), Albedo, 조명 색 및 강도 등을 적용해주기 위해 saturate 함수로 음수값을 0으로 초기화한 상태에서 다시 시작함.
            // 하프 램버트로 해도 되기는 하는데, 감쇄 연산 적용시 좀 이상해져서 그냥 saturate() 함수로 음수값 조절한 상태에서 적용해주는 게 낫다고 함.
            
            // float ndotl = saturate(dot(s.Normal, lightDir));
            float ndotl = dot(s.Normal, lightDir) * 0.5 + 0.5; // 이번에는 완성된 Lambert 에 Half-Lambert 기법을 적용해볼거임.
            
            // Albedo 텍스쳐, 빛의 강도 및 색상(_LightColor 내장변수), 빛의 감쇄(attenuation) 를 적용하는 부분 -> 자세한 설명은 하단 comment 참고
            float4 final;
            // final.rgb = ndotl * s.Albedo * _LightColor0.rgb * atten;
            
            /*
                Half-Lambert 를 적용하면,
                atten 값에 1, 2번 효과(self shadow, receive shadow) 에 의해
                승모근 뒷쪽 부분에 그림자가 너무 티나게 어두워보이는 문제가 있음.

                이럴 경우 아래의 두 가지 방법 중 하나로 해결해주면 됨.
            */
            // final.rgb = ndotl * s.Albedo * _LightColor0.rgb; // 1. 아예 단순무식하게 atten 값을 없애버린다.
            final.rgb = pow(ndotl, 3) * s.Albedo * _LightColor0.rgb * atten; // 2. Half-Lambert 로 계산한 ndotl 내적값을 pow() 함수로 세 제곱 정도 해줘서 전반적으로 음영을 더 어둡게 깔아준다. (p.312 참고) -> 이러면 atten 에 의해 드리우는 그림자가 묻혀서 더 자연스러워 보임. 
            final.a = s.Alpha;
            
            return final;
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

/*
    빛의 감쇄, 색상 및 강도, Albedo 적용 

    final.rgb = ndotl * s.Albedo * _LightColor0.rgb * atten;

    위의 공식은 완전한 Lambert Lighting 을 구현하기 위해, 
    빛의 감쇄, 색상 및 강도, Albedo 를 적용하려는 것임. 그래서
    각각의 값이 들어있는 변수를 ndotl(내적결과값) 에 곱해준 것임.

    
    1. s.Albedo

    void surf() 함수에서 할당해준 
    구조체의 Albedo 텍스쳐의 색상값을
    가져다 쓰고 있는 거라고 보면 됨.

    얘를 노말텍스쳐의 노말값으로 내적해준 값에
    곱해줘야, 노말과 색상이 동시에 적용된,
    즉, 노말 텍스쳐와 Albedo 텍스쳐가 동시에 적용된 색상 결과값이 나오게 됨.


    2. _LightColor().rgb

    얘는 유니티의 내장변수로, 조명의 색상과 강도값을 가지고 있음.
    이 값을 곱해주면 원래의 색상에서 좀 더 누리끼리한 때깔로 바뀜.
    -> 조명의 색상과 강도값이 적용된 것.


    3. atten

    빛의 감쇄현상을 적용시킴.

    atten 은 3가지 효과를 적용하는데,
        3-1. self shadow 를 적용시킴. (자기 자신의 그림자를 자기가 받는 것)
        3-2. receive shadow 를 적용시킴. (다른 물체의 그림자를 자기가 받는 것)
        3-3. Point Light 에서 조명의 감쇄현상을 적용시킴. (현재 프로젝트는 Directional Light 을 사용하고 있어서 atten 값을 곱해줘도 잘 티가 안남.)

    self shadow 및 receive shadow 가 적용된 부분을 보려면, 
    승모근(?) 목 뒷쪽 부분에 그림자를 주고 있음.

    내적값에 의해 조명벡터를 계산하는 ndotl 을 지워주면,
    조명벡터값의 영향을 아예 없앨 수 있는데,
    이 상태에서 atten 을 없앤거랑 적용한거랑 비교해보면

    목 뒷쪽 부분에 그림자가 없어졌다가 생겼다가 하는 걸 볼 수 있음.
*/