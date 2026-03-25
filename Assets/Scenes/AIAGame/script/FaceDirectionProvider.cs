using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Renderer))] // 确保物体上有 Renderer
public class FaceDirectionProvider : MonoBehaviour
{
    [Header("Transform Anchors")]
    public Transform head;
    public Transform faceForward;
    public Transform faceRight;

    private Renderer _faceRenderer;
    private MaterialPropertyBlock _propBlock;

    // 1. 缓存 Shader 属性 ID，避免每帧进行字符串哈希计算（关键优化）
    private static readonly int FaceForwardID = Shader.PropertyToID("_FaceForward");
    private static readonly int FaceRightID = Shader.PropertyToID("_FaceRight");

    void OnEnable() // 使用 OnEnable 确保在编辑器和运行时都能正确初始化
    {
        _faceRenderer = GetComponent<Renderer>();
        if (_propBlock == null)
        {
            _propBlock = new MaterialPropertyBlock();
        }
    }

    void LateUpdate()
    {
        // 2. 快速判空，防止在未配置时控制台报错
        if (!_faceRenderer || !head || !faceForward || !faceRight) return;

        // 3. 直接在计算时归一化，减少中间变量
        Vector3 forward = (faceForward.position - head.position).normalized;
        Vector3 right = (faceRight.position - head.position).normalized;

        // 4. 更新 MaterialPropertyBlock
        // 注意：GetPropertyBlock 会获取当前 Renderer 已有的属性块，避免覆盖掉其他脚本设置的属性
        _faceRenderer.GetPropertyBlock(_propBlock);

        // Vector3 可以隐式转换为 Vector4，无需手动创建 Vector4
        _propBlock.SetVector(FaceForwardID, forward);
        _propBlock.SetVector(FaceRightID, right);

        _faceRenderer.SetPropertyBlock(_propBlock);
    }

    // 5. 编辑器辅助：如果你在 Inspector 里手动拖放了物体，这能保证立即刷新
    void OnValidate()
    {
        if (_faceRenderer == null) _faceRenderer = GetComponent<Renderer>();
    }
}