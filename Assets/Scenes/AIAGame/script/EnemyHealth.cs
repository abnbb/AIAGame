using UnityEngine;

public class EnemyHealth : MonoBehaviour
{
    [Header("受击设置")]
    public int maxHitCount = 3;       // 最大受击次数
    private int _currentHitCount = 0; // 当前受击计数
    private DissolveController _dissolveCtrl;
    private EnemyAI _aiScript;
    private bool _isDead = false;

    private Renderer[] _targetRenderers;

    [Header("音效设置")]
    public AudioClip hitSound;          // 拖入你的受击音效文件
    [Range(0, 1)]
    public float volume = 0.8f;         // 音量控制
    public bool pitchRandomness = true; // 是否开启随机音调（让听感不单调）

    private AudioSource _audioSource;

    void Start()
    {
        _dissolveCtrl = GetComponent<DissolveController>();
        _aiScript = GetComponent<EnemyAI>();
        _targetRenderers = GetComponentsInChildren<Renderer>();

        _audioSource = GetComponent<AudioSource>();
        if (_audioSource == null)
        {
            _audioSource = gameObject.AddComponent<AudioSource>();
        }
        _audioSource.playOnAwake = false;
    }

    // 该方法由玩家武器的 OnTriggerEnter 调用
    public void TakeHit()
    {
        if (_isDead) return;

        _currentHitCount++;
        // Debug.Log($"{gameObject.name} 被击中次数: {_currentHitCount}");

        // 播放受击动画（如果有的话）
        // GetComponent<Animator>().SetTrigger("GetHit");

        if (_currentHitCount >= maxHitCount)
        {
            Die();
        }
        PlayHitAudio();
    }
    void PlayHitAudio()
    {
        if (hitSound != null && _audioSource != null)
        {
            // 随机音调：每次受击声音略微不同，二次元游戏常用技巧
            if (pitchRandomness)
            {
                _audioSource.pitch = Random.Range(0.9f, 1.1f);
            }

            // PlayOneShot 的好处是：多个声音可以重叠播放
            _audioSource.PlayOneShot(hitSound, volume);
        }
    }

    void trunOffShadow()
    {
        if (_targetRenderers.Length > 0)
        {
            foreach (var r in _targetRenderers)
            {
                r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            }
        }
    }


    void Die()
    {
        _isDead = true;

        // 1. 禁用 AI 和 导航，防止死后还在追人
        if (_aiScript) _aiScript.enabled = false;
        if (TryGetComponent<UnityEngine.AI.NavMeshAgent>(out var agent))
        {
            agent.isStopped = true;
            agent.enabled = false;
        }

        // 2. 禁用碰撞体，防止挡路
        // if (TryGetComponent<Collider>(out var col)) col.enabled = false;

        // 3. 触发消散特效
        if (_dissolveCtrl)
        {
            _dissolveCtrl.StartDissolve();
            // trunOffShadow();
        }
        else
        {
            // 如果没挂溶解脚本，直接销毁
            Destroy(gameObject);
        }
    }
}