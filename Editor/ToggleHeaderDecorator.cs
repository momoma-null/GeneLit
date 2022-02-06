using System;
using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class ToggleHeaderDecorator : MaterialPropertyDrawer
    {
        readonly static float s_lineHeight = EditorStyles.toolbar.CalcHeight(GUIContent.none, 0) + EditorGUIUtility.standardVerticalSpacing;

        readonly GUIContent _title;
        readonly string _keyword;

        public ToggleHeaderDecorator(string title, string keyword)
        {
            _title = EditorGUIUtility.TrTextContent(title);
            _keyword = keyword;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            => s_lineHeight;

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            position.height -= s_lineHeight - EditorGUIUtility.singleLineHeight;
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            var mixed = false;
            for (var i = 1; i < materials.Length; ++i)
            {
                if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                {
                    mixed = true;
                    break;
                }
            }
            try
            {
                EditorGUI.showMixedValue = mixed;
                EditorGUI.BeginChangeCheck();
                GUI.Box(position, GUIContent.none, EditorStyles.toolbar);
                enabled = EditorGUI.ToggleLeft(position, _title, enabled);
                if (EditorGUI.EndChangeCheck())
                {
                    editor.RegisterPropertyChangeUndo("Material Keyword");
                    foreach (var mat in materials)
                    {
                        if (enabled)
                            mat.EnableKeyword(_keyword);
                        else
                            mat.DisableKeyword(_keyword);
                    }
                }
            }
            finally
            {
                EditorGUI.showMixedValue = false;
            }
        }
    }
}
