using UnityEngine;
using Varjo.XR;

public class LocalizedBlurEffect : MonoBehaviour
{
    public Material blurMaterial;
    public EyeTracking eyeTracking;

    [Header("Blur Settings")]
    [Range(0.01f, 0.1f)] public float neighborhoodSize = 0.03f;
    [Range(1.0f, 50.0f)] public float sigma = 10.0f;
    [Range(0.05f, 0.5f)] public float blurRadius = 0.2f;
    [Range(1, 50)] public int iterations = 10;

    [Header("Editor Preview")]
    public bool simulateWithoutVarjo = true;

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Vector2 gaze = GetGazePosition();

        blurMaterial.SetVector("_GazePos", new Vector4(gaze.x, gaze.y, 0, 0));
        blurMaterial.SetFloat("_Radius", blurRadius);
        blurMaterial.SetFloat("_Sigma", sigma);
        blurMaterial.SetFloat("_NeighborhoodSize", neighborhoodSize);
        blurMaterial.SetFloat("_Iterations", iterations);

        RenderTexture temp = RenderTexture.GetTemporary(src.width, src.height, 0);

        // Vertical blur pass
        blurMaterial.SetVector("_BlurDirection", new Vector4(0, 1, 0, 0));
        blurMaterial.SetTexture("_OriginalTex", src); // original unblurred image
        Graphics.Blit(src, temp, blurMaterial);

        // Horizontal blur pass
        blurMaterial.SetVector("_BlurDirection", new Vector4(1, 0, 0, 0));
        blurMaterial.SetTexture("_OriginalTex", src); // again use original for masking
        Graphics.Blit(temp, dest, blurMaterial);

        RenderTexture.ReleaseTemporary(temp);
    }

    private Vector2 GetGazePosition()
    {
//#if UNITY_EDITOR
//        Vector2 mousePos = Input.mousePosition;
//        return new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
//#else
        if (eyeTracking != null)
        {
            Vector2 gaze = eyeTracking.GetNormalizedGazePosition();
            gaze.y = 1.0f - gaze.y; // Flip Y for UV
            return new Vector2(Mathf.Clamp01(gaze.x), Mathf.Clamp01(gaze.y));
        }
        return new Vector2(0.5f, 0.5f); // fallback center
//#endif
    }
}
