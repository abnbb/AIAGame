using UnityEngine;

public class CameraFollowAndRotate : MonoBehaviour
{
    [Header("跟随设置")]
    public Transform target;        // 角色
    public Vector3 offset = new Vector3(0, 5, -10); // 相对角色的偏移
    public float followSmooth = 5f;

    [Header("旋转设置")]
    public float rotateSpeed = 5f;
    public Light directionalLight;

    private float _rotationX = 0f;
    private float _rotationY = 0f;
    private bool _isRotating = false;

    void Start()
    {
        // 初始化角度
        Vector3 rot = transform.localRotation.eulerAngles;
        _rotationX = rot.y;
        _rotationY = rot.x;
    }

    void LateUpdate() // 相机逻辑建议放在 LateUpdate
    {
        if (target == null) return;

        // 1. 检测是否按下右键进入自由视角
        if (Input.GetMouseButton(1))
        {
            _isRotating = true;
            HandleRotation();
        }
        else
        {
            _isRotating = false;
            HandleFollow();
        }
    }

    void HandleFollow()
    {
        // 传统的跟随逻辑：平滑移动到角色后方特定位置
        Vector3 targetPosition = target.position + offset;
        transform.position = Vector3.Lerp(transform.position, targetPosition, Time.deltaTime * followSmooth);

        // 传统的锁定逻辑：始终盯着角色
        transform.LookAt(target.position + Vector3.up * 1.5f);

        // 同步旋转变量，防止切换回自由视角时瞬间“弹跳”
        Vector3 rot = transform.localRotation.eulerAngles;
        _rotationX = rot.y;
        _rotationY = rot.x;
    }

    void HandleRotation()
    {
        float mouseX = Input.GetAxis("Mouse X") * rotateSpeed;
        float mouseY = Input.GetAxis("Mouse Y") * rotateSpeed;

        if (Input.GetKey(KeyCode.LeftAlt) && directionalLight != null)
        {
            // 旋转灯光
            directionalLight.transform.Rotate(Vector3.up, mouseX, Space.World);
            directionalLight.transform.Rotate(Vector3.right, -mouseY, Space.Self);
        }
        else
        {
            // 自由旋转相机角度
            _rotationX += mouseX;
            _rotationY -= mouseY;
            _rotationY = Mathf.Clamp(_rotationY, -80f, 80f);
            transform.localRotation = Quaternion.Euler(_rotationY, _rotationX, 0);

            // 注意：自由旋转时，相机依然可以跟着角色移动（保持距离），但不强制锁定角度
            transform.position = Vector3.Lerp(transform.position, target.position + offset, Time.deltaTime * followSmooth);
        }
    }
}