using System;
using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class ToggleHeaderDecorator : MaterialPropertyDrawer
    {
        public static class Styles
        {
            public static readonly GUIStyle HeaderStyle = new GUIStyle("ShurikenModuleTitle")
            {
                font = new GUIStyle(EditorStyles.boldLabel).font,
                border = new RectOffset(15, 7, 4, 4),
                fixedHeight = 22f,
                contentOffset = new Vector2(20f, -2f)
            };
        }

        readonly static float s_lineHeight = Styles.HeaderStyle.CalcHeight(GUIContent.none, 0) + EditorGUIUtility.standardVerticalSpacing;

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
            var oldLabelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth = 0f;
            try
            {
                EditorGUI.showMixedValue = mixed;
                EditorGUI.BeginChangeCheck();
                GUI.Box(position, GUIContent.none, Styles.HeaderStyle);
                position.xMin += 4f;
                enabled = EditorGUI.Toggle(position, _title, enabled);
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
                EditorGUIUtility.labelWidth = oldLabelWidth;
            }
        }
    }
}
