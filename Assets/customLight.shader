Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {} // �ؽ�Ʈ 1���� �޴� �⺻ ���̴��� ������.
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        /*
             Ŀ���� ����Ʈ ���� ��, Standard ��� ���ִ� �� Test ��� �ٲ� ��. 

             �� �̸��� ����� ������ �� ������, 
             ���� �Ʒ��� �ۼ��� Ŀ���� ����Ʈ �Լ��� 

             ������ ���⿡�� ������ �̸��� ����ؾ� 
             ����Ƽ�� Ŀ���� ����Ʈ �Լ��� �ν���!
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
            Ŀ���� ����Ʈ �Լ� �ۼ� �� �ʼ�����


            1. ���ϰ��� Ÿ���� float4 �� �Ѵ�.
            
            Ŀ���� ���� �Լ��� ��¶�ų� ������ ���������� � "����"��
            �������� �ϱ� ������, ���ϰ��� ������ 
            r, g, b, a ä���� ��� ���� �� �ִ� float4 �� �����Ѵ�.


            2. �Լ� �̸��� �ݵ�� 
            'Lighting' + '������ ������ Ŀ���� ����Ʈ �̸�' 
            �� ���� ������ ���Ѽ� �����ش�.

            ���� ���� �Լ� �̸��� �ۼ������
            ����Ƽ�� ����Ʈ �Լ��� �ν��ϱ� ������ 
            �ݵ�� ������ �Լ��̸��� �ۼ����� ��!
        */
        float4 LightingTest(SurfaceOutput s, float3 lightDir, float atten) {
            return float4(1, 0, 0, 1);
        }

        ENDCG
    }
    FallBack "Diffuse"
}

/*
    ������ �Լ��� ���� ���� (p.299 ~ 300 ����)

    ������ �Լ��� ����� ���, �Ʒ��� 3���� ���ڸ� �޵��� 
    �԰��� ����������. ���� Ŀ���� ���� �Լ���� �ص� 
    �Ժη� �ٲ� �� ����, �־��� ���鸸 ����ؾ� ��.


    1. SurfaceOutput s

    ��� �ռ� ����Ƽ�� ����� ����Ʈ �� �� �� ����Ʈ �Լ�����
    ����ϴ� ����Ʈ �Է� ����ü��.

    ���� void surf() �Լ����� o.Albedo, o.Alpha � ���� �־��ָ�,
    �� ������ ��� ����ü�� �츮�� ���� Ŀ���� ����Ʈ �Լ��� 
    ù ��° ���ڷ� �־��ִ� ����!

    �� ������ ���� s.Albedo �̷� ������ �������� ��!


    2. float3 lightDir

    ������� ���͸� �ǹ���.
    �׷��� ��ֺ��Ϳ� ������ �ݴ��̸� ���� ��ƾ��� ��������
    ������ 180���� ���͹����� �������� -1�� �Ǿ����.

    �̸� �����ϱ� ���� lightDir �� ���� �����͸�
    ����ȭ�ؼ� �Ųٷ� ������ ��. (p.288 ����)

    ����, ��������� �����ϰ� �ϱ� ���� ���̸� 
    1�� ����ȭ�Ͽ� ������� ������ ���� ����.


    3. float atten

    �׸��ڳ� �Ÿ��� �־����鼭
    ���� ���� ��ο����� ����������
    �����ϱ� ���� �޴� ��
*/