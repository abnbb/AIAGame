using UnityEngine;

public partial class GameExitHandler : MonoBehaviour
{
    void Update()
    {
        // 检测按下 Esc 键
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Debug.Log("正在退出游戏...");
            Application.Quit();
        }
    }
    public void ClickToExit()
    {
        Application.Quit();
    }
}