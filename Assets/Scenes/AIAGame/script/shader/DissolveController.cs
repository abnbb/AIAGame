using UnityEngine;
using System.Collections;

public class DissolveController : MonoBehaviour
{
    public Renderer targetRenderer;
    public float dissolveDuration = 2.0f; // 消散持续时间

    private MaterialPropertyBlock _propBlock;
    private static readonly int DissolveAmountID = Shader.PropertyToID("_Dissthreshold");

    void Start()
    {
        _propBlock = new MaterialPropertyBlock();
    }

    // 当角色死亡时调用此方法
    public void StartDissolve()
    {
        StartCoroutine(DissolveRoutine());
    }

    IEnumerator DissolveRoutine()
    {
        float elapsedTime = 0;
        targetRenderer.material.EnableKeyword("_DISSOLVE_ON");

        while (elapsedTime < dissolveDuration)
        {
            elapsedTime += Time.deltaTime;
            // 计算当前消散值 (0 到 1)
            float lerpValue = Mathf.Clamp01(elapsedTime / dissolveDuration);

            // 使用 PropertyBlock 更新 Shader 参数，不产生材质实例
            targetRenderer.GetPropertyBlock(_propBlock);
            // _propBlock.EnableKeyword("_DISSOLVE_ON");
            _propBlock.SetFloat(DissolveAmountID, lerpValue);
            targetRenderer.SetPropertyBlock(_propBlock);

            yield return null;
        }

        // 消散完成后销毁物体
        Destroy(gameObject);
    }
}