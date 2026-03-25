using UnityEngine;

public class CollectItem : MonoBehaviour
{
    [Header("特效设置")]
    public GameObject collectEffect; // 可选：消失时的粒子特效

    private void OnTriggerEnter(Collider other)
    {
        // 1. 检查碰撞到的物体是不是玩家
        // 请确保你的角色 Inspector 面板顶部的 Tag 设为 "Player"
        if (other.CompareTag("Player"))
        {
            // 2. 触发逻辑（比如加分、回血）
            Debug.Log("玩家拾取了物品！");

            // 3. 实例化特效（如果有的话）
            if (collectEffect != null)
            {
                Instantiate(collectEffect, transform.position, Quaternion.identity);
            }

            // 4. 销毁物体本身
            Destroy(gameObject);
        }
    }
}