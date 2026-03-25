using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class MyaBillboardGUI : ShaderGUI
{
    MaterialProperty billboardRotation = null;
    MaterialProperty billboardScale = null;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        billboardRotation = FindProperty("_BillboardRotation", props);
        billboardScale = FindProperty("_BillboardScale", props);
        materialEditor.PropertiesDefaultGUI(props);
        Material material = materialEditor.targets[0] as Material;

        Vector3 eulerAngles =
            new Vector3(
                billboardRotation.vectorValue.x,
                billboardRotation.vectorValue.y,
                billboardRotation.vectorValue.z
                );
        Vector3 scales =
            new Vector3(
                billboardScale.vectorValue.x,
                billboardScale.vectorValue.y,
                billboardScale.vectorValue.z
                );

        float scaleZ = billboardScale.vectorValue.w;

        EditorGUI.BeginChangeCheck();
        {
            EditorGUIUtility.labelWidth = 0f;
            eulerAngles = EditorGUILayout.Vector3Field("Rotation", eulerAngles);
            scales = EditorGUILayout.Vector3Field("Scale", scales);

            scaleZ = EditorGUILayout.Slider("scaleZ", scaleZ, 0, 1);
            EditorGUILayout.Space();
            GUILayout.BeginHorizontal();
            {
                EditorGUILayout.Space();
                if (GUILayout.Button("Reset", GUILayout.Width(80)))
                {
                    scales = Vector3.one;
                    eulerAngles = Vector3.zero;
                    scaleZ = 0;

                }
            }
            GUILayout.EndHorizontal();
            EditorGUILayout.Space();

            materialEditor.SetDefaultGUIWidths();
        }
        if (EditorGUI.EndChangeCheck())
        {

            eulerAngles = WrapAngle(eulerAngles);
            billboardRotation.vectorValue = new Vector4(eulerAngles.x, eulerAngles.y, eulerAngles.z, 0);
            billboardScale.vectorValue = new Vector4(scales.x, scales.y, scales.z, scaleZ);
        }
        Quaternion rot = Quaternion.Euler(eulerAngles);
        Matrix4x4 m = Matrix4x4.TRS(Vector3.zero, rot, scales);

        material.SetVector("_BillboardMatrix0", m.GetColumn(0));
        material.SetVector("_BillboardMatrix1", m.GetColumn(1));
        material.SetVector("_BillboardMatrix2", -m.GetColumn(2) * scaleZ);//直接把Z轴压扁，就当是正交相机的效果了


        GUILayout.Space(10);
    }
    public float WrapAngle(float angle)
    {
        while (angle > 180f) angle -= 360f;
        while (angle < -180f) angle += 360f;
        return angle;
    }
    public Vector3 WrapAngle(Vector3 angles)
    {
        angles =
            new Vector3(
                WrapAngle(angles.x),
                WrapAngle(angles.y),
                WrapAngle(angles.z)
                );
        return angles;
    }
}
