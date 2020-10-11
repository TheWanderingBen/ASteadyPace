// ------------------------------------------------
// This class generates a point cloud using physics raycasts pointing downwards
// It's mostly based on Sam Wronski's point cloud system which you can see here: https://github.com/WorldOfZero/UnityVisualizations/tree/master/Unity%20Terrain/Grass
// And he does an excellent job walking through it on his YouTube channel here: https://www.youtube.com/watch?v=b2AlyCNbYmY
// ------------------------------------------------

using System.Collections.Generic;
using UnityEngine;

namespace Grass
{

[RequireComponent(typeof(MeshFilter)), ExecuteAlways]
public class GrassPointCloudGenerator : MonoBehaviour
{
    [SerializeField, Tooltip("How many blades of grass get generated")] int numBlades;
    [SerializeField, Tooltip("The height we raycast down from")] float startHeight = 1000f;
    [SerializeField, Tooltip("How big of a grass plane this is")] Vector2 size;
    
    MeshFilter meshFilter;

    void Awake()
    {
        meshFilter = GetComponent<MeshFilter>();
    }
    
#if !UNITY_EDITOR
    void Start()
    {
        GenerateGrass();
    }
#else
    int lastNumBlades;
    float lastStartHeight;
    Vector2 lastSize;
    Vector3 lastPosition;
    
    void Update()
    {
        if (lastNumBlades != numBlades ||
            lastStartHeight != startHeight ||
            lastSize != size ||
            lastPosition != transform.position)
        {
            GenerateGrass();
            lastPosition = transform.position;
            lastNumBlades = numBlades;
            lastStartHeight = startHeight;
            lastSize = size;
        }
    }
#endif

    void GenerateGrass()
    {
        List<Vector3> vertices = new List<Vector3>();
        List<int> indices = new List<int>();
        for (int i = 0; i < numBlades; i++)
        {
            Vector3 origin = transform.position;
            origin.y = startHeight;
            origin.x += size.x * Random.Range(-0.5f, 0.5f);
            origin.z += size.y * Random.Range(-0.5f, 0.5f);

            Ray ray = new Ray(origin, Vector3.down);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                origin = hit.point;
                vertices.Add(origin);
                indices.Add(i);
            }
        }

        Mesh mesh = new Mesh();
        mesh.SetVertices(vertices);
        mesh.SetIndices(indices, MeshTopology.Points, 0);
        meshFilter.mesh = mesh;
    }
}
}
