using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class modelSmoothNormal : MonoBehaviour
{
    // Start is called before the first frame update
    private void Awake()
    {
        Mesh mesh = GetComponent<SkinnedMeshRenderer>().sharedMesh;

        IEnumerable<IEnumerable<KeyValuePair<Vector3, int>>> groups = mesh.vertices
            .Select((vertex, index) => new KeyValuePair<Vector3, int>(vertex, index))
            .GroupBy(pair => pair.Key);

        Vector3[] normals = mesh.normals;
        Vector4[] smoothNormals = normals.Select((normal, index) => new Vector4(normal.x, normal.y, normal.z)).ToArray();

        foreach (IEnumerable<KeyValuePair<Vector3, int>> group in groups)
        {
            if (group.Count() == 1)
            {
                continue;
            }

            Vector3 smoothNormal = Vector3.zero;

            foreach (KeyValuePair<Vector3, int> pair in group)
            {
                smoothNormal += normals[pair.Value];
            }

            smoothNormal.Normalize();

            foreach (KeyValuePair<Vector3, int> pair in group)
            {
                smoothNormals[pair.Value] = new Vector4(smoothNormal.x, smoothNormal.y, smoothNormal.z);
            }
        }

        mesh.tangents = smoothNormals;
    }
}
