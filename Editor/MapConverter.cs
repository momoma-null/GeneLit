using System.IO;
using UnityEditor;
using UnityEngine;
using static UnityEngine.Object;

namespace MomomaAssets.GeneLit
{
    static class MapConverter
    {
        static class Shaders
        {
            public static readonly Shader standardShader = Shader.Find("Standard");
            public static readonly Shader standardRoughnessShader = Shader.Find("Autodesk Interactive");
            public static readonly Shader converterShader = Shader.Find("Hidden/MS_MapConverter");
        }

        [MenuItem("CONTEXT/Material/Convert to Mask Map", false, 184)]
        static void ConvertToMaskMap(MenuCommand menuCommand)
        {
            if (menuCommand.context is Material material)
            {
                if (material.shader == Shaders.standardShader)
                    ConvertToMaskMap_Internal(material, false);
                else if (material.shader == Shaders.standardRoughnessShader)
                    ConvertToMaskMap_Internal(material, true);
            }
        }

        static void ConvertToMaskMap_Internal(Material material, bool isRoughness)
        {
            var convertMat = new Material(Shaders.converterShader);
            try
            {
                convertMat.CopyPropertiesFromMaterial(material);
                var ids = convertMat.GetTexturePropertyNameIDs();
                var width = 0;
                var height = 0;
                var path = string.Empty;
                foreach (var i in ids)
                {
                    var tex = convertMat.GetTexture(i);
                    if (tex != null)
                    {
                        width = Mathf.Max(tex.width, width);
                        height = Mathf.Max(tex.height, height);
                        if (string.IsNullOrEmpty(path) && AssetDatabase.Contains(tex))
                        {
                            path = AssetDatabase.GetAssetPath(tex);
                        }
                    }
                }
                if (width < 1 || height < 1)
                    return;
                if (string.IsNullOrEmpty(path))
                    path = Application.dataPath;
                path = Path.Combine(Path.GetDirectoryName(path), $"{material.name}_mask.png");
                if (isRoughness)
                    convertMat.SetFloat("_UseRoughnessMap", 1f);
                var descriptor = new RenderTextureDescriptor(width, height) { sRGB = false };
                var renderTexture = RenderTexture.GetTemporary(descriptor);
                var dstTexture = new Texture2D(width, height, TextureFormat.RGBA32, false, false);
                try
                {
                    Graphics.Blit(convertMat.mainTexture, renderTexture, convertMat);
                    Graphics.SetRenderTarget(renderTexture);
                    dstTexture.ReadPixels(new Rect(0, 0, width, height), 0, 0, false);
                    dstTexture.Apply();
                    Graphics.SetRenderTarget(null);
                    var bytes = dstTexture.EncodeToPNG();
                    File.WriteAllBytes(path, bytes);
                    AssetDatabase.ImportAsset(path);
                    if (AssetImporter.GetAtPath(path) is TextureImporter importer)
                    {
                        importer.sRGBTexture = false;
                        importer.SaveAndReimport();
                    }
                }
                finally
                {
                    RenderTexture.ReleaseTemporary(renderTexture);
                    DestroyImmediate(dstTexture);
                }
            }
            finally
            {
                DestroyImmediate(convertMat);
            }
        }
    }
}
