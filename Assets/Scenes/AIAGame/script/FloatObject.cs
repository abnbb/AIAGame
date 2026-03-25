using UnityEngine;

public class FloatObject : MonoBehaviour
{
    [Header("浮动设置")]
    public float degreesPerSecond = 15.0f; // 旋转速度 (设为0则不旋转)
    public float amplitude = 0.5f;         // 浮动振幅 (上下波动的幅度)
    public float frequency = 1f;           // 浮动频率 (完成一次波动的时间)

    public Transform pivote;
    private Vector3 _startPosition;
    private Vector3 _tempPosition;

    void Start()
    {
        // 记录初始位置
        _startPosition = pivote.position;
    }

    void Update()
    {
        // 1. 处理自转 (可选，增加动态感)
        if (degreesPerSecond != 0)
        {
            transform.Rotate(new Vector3(0f, Time.deltaTime * degreesPerSecond, 0f), Space.World);
        }

        // 2. 使用正弦函数计算垂直位移
        // y = A * sin(ωt)
        _tempPosition = _startPosition;
        _tempPosition.y += Mathf.Sin(Time.fixedTime * Mathf.PI * frequency) * amplitude;

        transform.position = _tempPosition;
    }
}