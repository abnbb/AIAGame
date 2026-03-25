using UnityEngine;

[RequireComponent(typeof(CharacterController))]
[RequireComponent(typeof(Animator))]
public class PlayerMovement : MonoBehaviour
{
    [Header("移动速度")]
    public float walkSpeed = 3.0f;
    public float runSpeed = 6.0f;
    public float rotationSpeed = 10.0f;
    public float gravity = 9.81f;
    public float disturbInten = 0.5f;

    [Header("加速设置")]
    public float acceleration = 10.0f; // 加速度
    public float deceleration = 12.0f; // 减速度
    private float currentInterpolatedSpeed = 0f; // 实际插值后的速度

    private CharacterController controller;
    private Animator animator;
    private Camera mainCamera; // 新增：引用主相机
    private float verticalVelocity;
    private Vector3 lastCharacterPos;

    void Start()
    {
        controller = GetComponent<CharacterController>();
        animator = GetComponent<Animator>();
        mainCamera = Camera.main; // 自动获取场景中的主相机
        lastCharacterPos = transform.position;
    }

    void Update()
    {
        // 1. 获取键盘输入
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");
        // Vector3 moveInput = new Vector3(horizontal, 0, vertical).normalized;

        Vector3 camForward = mainCamera.transform.forward;
        Vector3 camRight = mainCamera.transform.right;

        // 核心步骤：抹平 Y 轴高度差，确保角色不会因为相机往下看就往地里钻
        camForward.y = 0;
        camRight.y = 0;
        camForward.Normalize();
        camRight.Normalize();

        // 合成最终移动向量
        Vector3 moveInput = (camForward * vertical + camRight * horizontal).normalized;



        // 2. 检测 Shift 状态
        // 只有在按下 Shift 时才判定为 "想跑步"
        bool isShiftPressed = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
        bool isRotate = Input.GetKeyDown(KeyCode.R);
        AnimatorStateInfo stateInfo = animator.GetCurrentAnimatorStateInfo(0);
        bool isRotatingNow = stateInfo.IsName("rig_008_Rotate");

        // 判定玩家是否真的在移动（防止原地按下 Shift 也会播跑步动画）
        bool isMoving = moveInput.magnitude > 0.1f;

        // 3. 确定最终速度和动画状态
        // 只有 正在移动 且 按下Shift，才使用跑步速度和跑步动画
        // float currentSpeed = (isMoving && isShiftPressed) ? runSpeed : walkSpeed;
        float targetSpeed = 0f;
        if (isMoving)
        {
            targetSpeed = isShiftPressed ? runSpeed : walkSpeed;
        }

        // 使用 MoveTowards 实现匀加速/匀减速
        // 如果 targetSpeed 大于当前速度，使用 acceleration；反之使用 deceleration
        float speedChangeRate = (targetSpeed > currentInterpolatedSpeed) ? acceleration : deceleration;
        currentInterpolatedSpeed = Mathf.MoveTowards(currentInterpolatedSpeed, targetSpeed, speedChangeRate * Time.deltaTime);

        // 状态判定：只有实际速度超过一定阈值才认为在移动
        bool isActuallyMoving = currentInterpolatedSpeed > 0.1f;

        if (isMoving && !isRotatingNow)
        {
            // 旋转：平滑转向移动方向
            Quaternion targetRotation = Quaternion.LookRotation(moveInput);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeed);
        }

        if (isActuallyMoving && !isRotatingNow)
        {


            // 移动计算
            Vector3 moveVector = moveInput * currentInterpolatedSpeed;

            // 应用重力
            if (controller.isGrounded) verticalVelocity = -0.5f;
            else verticalVelocity -= gravity * Time.deltaTime;

            moveVector.y = verticalVelocity;

            // 执行移动
            controller.Move(moveVector * Time.deltaTime);
        }


        // --- 核心逻辑：动画同步 ---

        // 设置是否处于“跑步状态”的布尔值
        // 逻辑：只有同时满足 [在移动] 和 [按下Shift] 才会变为 true
        animator.SetBool("IsRun", isActuallyMoving && isShiftPressed);
        if (isActuallyMoving)
        {
            if (isShiftPressed)
            {
                // 如果按下 Shift，且正在移动，设置为跑步动画
                animator.SetBool("IsRun", true);
                animator.SetBool("IsWalk", false);
            }
            else
            {
                // 如果没有按下 Shift，但正在移动，设置为走路动画
                animator.SetBool("IsWalk", true);
                animator.SetBool("IsRun", false);
            }
        }
        else
        {
            animator.SetBool("IsWalk", false);
            animator.SetBool("IsRun", false);
        }
        if (isRotate && !isRotatingNow)
        {
            animator.SetTrigger("IsRotate");
        }


        UpdatePostionWS();

    }
    // 当控制器撞到带有碰撞体的东西时调用
    void OnControllerColliderHit(ControllerColliderHit hit)
    {
        Rigidbody body = hit.collider.attachedRigidbody;

        // 检查碰撞物体是否有刚体，且不是开动力的
        if (body == null || body.isKinematic) return;

        // 不要推脚底下的东西
        if (hit.moveDirection.y < -0.3f) return;

        // 计算推力方向（水平方向）
        Vector3 pushDir = new Vector3(hit.moveDirection.x, 0, hit.moveDirection.z);

        // 应用推力（可以根据力量设置一个系数）
        float pushPower = 2.0f;
        body.velocity = pushDir * pushPower;
    }
    void UpdatePostionWS()
    {
        Shader.SetGlobalVector("_lastCharacterPos", lastCharacterPos);
        Shader.SetGlobalVector("_CharacterPosWS", transform.position);
        Shader.SetGlobalFloat("_DistubInten", disturbInten);
        lastCharacterPos = transform.position;
    }
}

