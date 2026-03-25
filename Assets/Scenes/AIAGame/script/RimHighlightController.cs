using UnityEngine;
using System.Collections;
using System.Collections.Generic; // 必须引用

public class MultiRimHighlightController : MonoBehaviour
{
    [Header("Shader 属性名 (必须是 Reference 名)")]
    public string rimColorName = "_RimColor";
    public string rimWidthName = "_RimWidth";

    [Header("高亮参数")]
    [ColorUsage(true, true)]
    public Color highlightColor = new Color(0.2f, 1.0f, 0.2f) * 3.0f; // 强度加到3
    public float highlightWidth = 0.5f;
    public float duration = 0.8f;

    private List<Material> _materials = new List<Material>();
    private float _initialWidth;
    private Color _initialColor;
    private Coroutine _activeEffect;

    void Awake()
    {
        // 1. 获取自身及所有子物体的所有 Renderer
        Renderer[] renderers = GetComponentsInChildren<Renderer>();

        if (renderers.Length > 0)
        {
            foreach (var r in renderers)
            {
                // 2. 将每个 Renderer 的材质加入列表
                // 注意：使用 .material 会创建实例，不会影响项目资源文件
                if (r.material != null)
                {
                    _materials.Add(r.material);
                }
            }

            // 3. 以第一个材质为基准记录初始值（假设它们初始值一样）
            if (_materials.Count > 0)
            {
                if (_materials[0].HasProperty(rimColorName))
                    _initialColor = _materials[0].GetColor(rimColorName);
                if (_materials[0].HasProperty(rimWidthName))
                    _initialWidth = _materials[0].GetFloat(rimWidthName);
            }
        }
        else
        {
            Debug.LogWarning($"[RimEffect] 在 {gameObject.name} 下没找到任何 Renderer!");
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        // 确保碰撞体标签匹配 且 列表不为空
        if (other.CompareTag("HealItem") && _materials.Count > 0)
        {
            Debug.Log("触发治疗高亮！");
            if (_activeEffect != null) StopCoroutine(_activeEffect);
            _activeEffect = StartCoroutine(PlayMultiHighlight());
        }
    }

    IEnumerator PlayMultiHighlight()
    {
        float elapsed = 0f;
        float halfDuration = duration / 2f;

        // 渐变到高亮
        while (elapsed < halfDuration)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / halfDuration;
            float smoothT = Mathf.SmoothStep(0, 1, t);

            Color currCol = Color.Lerp(_initialColor, highlightColor, smoothT);
            float currWidth = Mathf.Lerp(_initialWidth, highlightWidth, smoothT);

            // 同时给所有材质赋值
            UpdateAllMaterials(currCol, currWidth);
            yield return null;
        }

        // 渐变回初始
        elapsed = 0f;
        while (elapsed < halfDuration)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / halfDuration;
            float smoothT = Mathf.SmoothStep(0, 1, t);

            Color currCol = Color.Lerp(highlightColor, _initialColor, smoothT);
            float currWidth = Mathf.Lerp(highlightWidth, _initialWidth, smoothT);

            UpdateAllMaterials(currCol, currWidth);
            yield return null;
        }

        // 确保回到初始值
        UpdateAllMaterials(_initialColor, _initialWidth);
    }

    // 辅助方法：统一更新
    void UpdateAllMaterials(Color col, float width)
    {
        foreach (var mat in _materials)
        {
            if (mat != null)
            {
                mat.SetColor(rimColorName, col);
                mat.SetFloat(rimWidthName, width);
            }
        }
    }
}