using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyAI : MonoBehaviour
{
    [Header("范围设置")]
    public float detectRange = 10f;   // 发现玩家的距离
    public float attackRange = 2.2f;  // 攻击距离 (略大于停止距离)
    public float stopDistance = 2f;   // 导航停止距离

    [Header("攻击频率")]
    public float attackCooldown = 2.5f;
    private float _nextAttackTime;

    private UnityEngine.AI.NavMeshAgent _agent;
    private Animator _animator;
    private Transform _player;

    void Start()
    {
        _agent = GetComponent<UnityEngine.AI.NavMeshAgent>();
        _animator = GetComponent<Animator>();
        _agent.stoppingDistance = stopDistance;

        // 寻找玩家
        GameObject playerObj = GameObject.FindGameObjectWithTag("Player");
        if (playerObj != null) _player = playerObj.transform;
    }

    void Update()
    {
        if (_player == null) return;

        float distance = Vector3.Distance(transform.position, _player.position);

        if (distance <= attackRange)
        {
            // --- 状态：准备攻击 ---
            HandleAttack();
        }
        else if (distance <= detectRange)
        {
            // --- 状态：追逐角色 ---
            HandleFollow();
        }
        else
        {
            // --- 状态：超出范围，待机 ---
            HandleIdle();
        }
        Debug.Log(_agent.isStopped);
        // 实时同步行走动画
        // UpdateAnimation();
    }

    void HandleIdle()
    {
        _agent.isStopped = true;
        _animator.SetBool("PigWalk", false);
    }

    void HandleFollow()
    {
        _agent.isStopped = false;
        _agent.SetDestination(_player.position);
        Debug.Log("跟随");
        _animator.SetBool("PigWalk", true);
    }

    void HandleAttack()
    {
        _agent.isStopped = true;

        // 攻击时始终平滑转向玩家
        Vector3 direction = (_player.position - transform.position).normalized;
        Quaternion lookRotation = Quaternion.LookRotation(new Vector3(direction.x, 0, direction.z));
        transform.rotation = Quaternion.Slerp(transform.rotation, lookRotation, Time.deltaTime * 5f);
        _animator.SetBool("PigWalk", false);
        // 触发攻击动画
        if (Time.time >= _nextAttackTime)
        {

            _animator.SetTrigger("PigAttack");
            _nextAttackTime = Time.time + attackCooldown;
        }
        Debug.Log("攻击");
    }

    void UpdateAnimation()
    {
        // 计算当前移动速度的比例 (0 到 1)
        // 使用 _agent.velocity.magnitude 获取实际物理位移速度
        // float currentSpeed = _agent.velocity.magnitude / _agent.speed;

        // 设置 PigWalk 参数：0为待机，1为行走
        _animator.SetBool("PigWalk", _agent.velocity.magnitude >= _agent.speed);
        Debug.Log($"前进:{_agent.velocity.magnitude >= _agent.speed}");
    }

    // 在编辑器预览范围
    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawWireSphere(transform.position, detectRange);
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, attackRange);
    }
}
