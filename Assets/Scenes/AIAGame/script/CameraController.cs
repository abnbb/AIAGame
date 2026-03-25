using UnityEngine;

public class CameraController : MonoBehaviour
{
    [Header("相机旋转设置")]
    public float rotateSpeed = 5f;
    public float smoothTime = 0.1f;

    [Header("平行光设置")]
    public Light directionalLight; // 在 Inspector 中拖入主光源
    public float lightRotateSpeed = 2f;

    private float _rotationX = 0f;
    private float _rotationY = 0f;

    void Start()
    {
        // 初始化旋转角度为当前物体的角度
        Vector3 rot = transform.localRotation.eulerAngles;
        _rotationX = rot.y;
        _rotationY = rot.x;
    }

    void Update()
    {
        // 只有按下鼠标右键时才触发旋转
        if (Input.GetMouseButton(1))
        {
            float mouseX = Input.GetAxis("Mouse X") * rotateSpeed;
            float mouseY = Input.GetAxis("Mouse Y") * rotateSpeed;

            // 如果按住左边 Alt 键，则旋转灯光
            if (Input.GetKey(KeyCode.LeftAlt) && directionalLight != null)
            {
                RotateLight(mouseX, mouseY);
            }
            else
            {
                // 否则旋转相机
                RotateCamera(mouseX, mouseY);
            }
        }
    }

    void RotateCamera(float x, float y)
    {
        _rotationX += x;
        _rotationY -= y; // 纵向旋转通常需要取反，否则操作感是反的

        // 限制仰角和俯角，防止相机翻转
        _rotationY = Mathf.Clamp(_rotationY, -80f, 80f);

        transform.localRotation = Quaternion.Euler(_rotationY, _rotationX, 0);
    }

    void RotateLight(float x, float y)
    {
        // 让平行光随着鼠标移动旋转
        // 平行光旋转会改变场景的阴影方向和明暗
        directionalLight.transform.Rotate(Vector3.up, x, Space.World);
        directionalLight.transform.Rotate(Vector3.right, -y, Space.Self);
    }
}