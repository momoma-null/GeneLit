﻿using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class BlendModeDrawer : MaterialPropertyDrawer
    {
        static readonly GUIContent[] s_options = new[] {
            new GUIContent("Opaque"),
            new GUIContent("Cutout"),
            new GUIContent("Fade"),
            new GUIContent("Transparent"),
            new GUIContent("Additive"),
            new GUIContent("Multiply") };

        public override void Apply(MaterialProperty prop)
        {
            foreach (Material mat in prop.targets)
            {
                SetupBlendMode(mat, mat.GetInt(prop.name), false);
            }
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            MaterialEditor.BeginProperty(position, prop);
            EditorGUI.BeginChangeCheck();
            var newValue = EditorGUI.Popup(position, label, (int)prop.floatValue, s_options);
            if (EditorGUI.EndChangeCheck())
            {
                editor.RegisterPropertyChangeUndo("Rendering Mode");
                prop.floatValue = newValue;
                foreach (Material material in prop.targets)
                {
                    SetupBlendMode(material, newValue, true);
                }
            }
            MaterialEditor.EndProperty();
        }

        static void SetupBlendMode(Material material, int blendMode, bool overrideRenderQueue)
        {
            var renderQueue = -1;
            switch (blendMode)
            {
                case 0:
                    if (material.IsKeywordEnabled("REFRACTION_TYPE_SOLID") || material.IsKeywordEnabled("REFRACTION_TYPE_THIN"))
                        material.SetOverrideTag("RenderType", "Transparent");
                    else
                        material.SetOverrideTag("RenderType", "");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.SetInt("_AlphaToMask", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    renderQueue = -1;
                    break;
                case 1:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.SetInt("_AlphaToMask", 1);
                    material.EnableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case 2:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaToMask", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case 3:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaToMask", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                    renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case 4:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaToMask", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case 5:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.DstColor);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaToMask", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                    renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
            }
            if (overrideRenderQueue)
            {
                material.renderQueue = renderQueue;
            }
        }
    }
}
