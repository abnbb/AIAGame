using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class tailAttck : MonoBehaviour
{
    // Start is called before the first frame update
    public GameObject weapon;
    private Collider _weaponCollider;

    void Start()
    {
        _weaponCollider = weapon.GetComponent<Collider>();
    }

    // Update is called once per frame
    void Update()
    {

    }
    // 由动画事件调用：开启碰撞
    public void EnableWeaponCollider()
    {
        _weaponCollider.enabled = true;
        // Debug.Log("武器碰撞已开启");
    }

    // 由动画事件调用：关闭碰撞
    public void DisableWeaponCollider()
    {
        _weaponCollider.enabled = false;
        // Debug.Log("武器碰撞已关闭");
    }
}
