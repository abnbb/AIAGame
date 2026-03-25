using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    [Header("追踪目标")]
    public Transform target;
    public Animator targetAnimator; // 需要拖入角色的 Animator

    [Header("基础位置偏移")]
    public float defaultDistance = 5.0f;
    public float height = 2.5f;
    public Vector3 lookAtOffset = new Vector3(0, 1.5f, 0);

    [Header("跑步动态效果")]
    public float runDistanceOffset = 1.5f; // 跑步时额外拉远的距离
    public float runFOVOffset = 10f;       // 跑步时增加的 FOV 值
    public float transitionSpeed = 2.0f;   // 过度平滑度 (值越大越快)

    [Header("平滑参数")]
    public float smoothSpeed = 5.0f;
    public bool followRotation = true;

    private Camera _cam;
    private float _defaultFOV;
    private float _currentDistance;
    private float _currentFOV;

    void Start()
    {
        _cam = GetComponent<Camera>();
        if (_cam != null) _defaultFOV = _cam.fieldOfView;

        _currentDistance = defaultDistance;
        _currentFOV = _defaultFOV;

        // 如果没有手动拖入，尝试自动获取
        if (targetAnimator == null && target != null)
            targetAnimator = target.GetComponent<Animator>();
    }

    void LateUpdate()
    {
        if (target == null) return;

        // 1. 检测是否处于跑步状态
        // 假设你 Animator 里的跑步参数叫 "IsRun"
        bool isRunning = targetAnimator != null && targetAnimator.GetBool("IsRun");

        // 2. 计算目标参数
        float targetDist = isRunning ? (defaultDistance + runDistanceOffset) : defaultDistance;
        float targetFOV = isRunning ? (_defaultFOV + runFOVOffset) : _defaultFOV;

        // 3. 平滑过渡参数 (使用 Lerp 让数值变化更自然)
        _currentDistance = Mathf.Lerp(_currentDistance, targetDist, Time.deltaTime * transitionSpeed);
        _currentFOV = Mathf.Lerp(_currentFOV, targetFOV, Time.deltaTime * transitionSpeed);

        // 应用 FOV
        if (_cam != null) _cam.fieldOfView = _currentFOV;

        // 4. 计算相机位置
        Vector3 targetPosition;
        if (followRotation)
        {
            // 使用平滑后的 _currentDistance
            targetPosition = target.position - (target.forward * _currentDistance) + (Vector3.up * height);
        }
        else
        {
            targetPosition = target.position + new Vector3(0, height, -_currentDistance);
        }

        // 5. 应用位置和转向
        transform.position = Vector3.Lerp(transform.position, targetPosition, Time.deltaTime * smoothSpeed);
        transform.LookAt(target.position + lookAtOffset);
    }
}