using UnityEngine;

public class WeaponDamage : MonoBehaviour
{
    [Header("战斗参数")]
    public float pushForce = 15.0f;    // 弹开的力度
    public float liftForce = 2.0f;    // 稍微带一点向上浮空的效果，手感更好
    private Collider _weaponCollider;
    private Transform _owner;

    void Start()
    {
        _weaponCollider = GetComponent<Collider>();
        _weaponCollider.enabled = false; // 初始状态关闭
        _owner = transform.root;
    }

    // // 由动画事件调用：开启碰撞
    // public void EnableWeaponCollider(Collider _weaponCollider)
    // {
    //     _weaponCollider.enabled = true;
    //     Debug.Log("武器碰撞已开启");
    // }

    // // 由动画事件调用：关闭碰撞
    // public void DisableWeaponCollider(Collider _weaponCollider)
    // {
    //     _weaponCollider.enabled = false;
    //     Debug.Log("武器碰撞已关闭");
    // }

    private void OnTriggerEnter(Collider other)
    {
        // 1. 检查对方是否有刚体
        Rigidbody targetRb = other.attachedRigidbody;
        // Debug.Log($"击中了物体: {other.name}");
        if (other.CompareTag("Enemy"))//标签判断
        {
            //击飞
            if (targetRb != null)//可击飞判断
            {
                // 2. 计算弹开方向：从玩家指向敌人的水平向量
                Vector3 pushDir = other.transform.position - _owner.position;
                pushDir.y = 0; // 抹平高度差，只保留水平推力
                pushDir.Normalize();

                // 3. 合成最终作用力（水平推力 + 微弱上升力）
                Vector3 finalForce = (pushDir * pushForce) + (Vector3.up * liftForce);

                // 4. 应用冲量 (Impulse)
                // 使用 VelocityChange 可以忽略质量影响，让反馈非常直接
                targetRb.AddForce(finalForce, ForceMode.VelocityChange);

                // Debug.Log($"弹开了物体: {other.name}");

                // 5. 击中反馈（可选）：在此处触发顿帧或特效
            }
            // 敌人受击逻辑
            EnemyHealth health = other.GetComponent<EnemyHealth>();
            if (health != null)//确保敌人有Health组件
            {
                health.TakeHit(); // 增加受击计数
            }
        }

    }
}