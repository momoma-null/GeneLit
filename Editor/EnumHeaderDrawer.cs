using System;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class EnumHeaderDrawer : MaterialPropertyDrawer
    {
        readonly static float s_lineHeight = EditorStyles.toolbar.CalcHeight(GUIContent.none, 0) + EditorGUIUtility.standardVerticalSpacing;

        readonly GUIContent[] _keywords;

        public EnumHeaderDrawer(string kw1, string kw2) : this(new[] { kw1, kw2 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3) : this(new[] { kw1, kw2, kw3 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4) : this(new[] { kw1, kw2, kw3, kw4 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4, string kw5) : this(new[] { kw1, kw2, kw3, kw4, kw5 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4, string kw5, string kw6) : this(new[] { kw1, kw2, kw3, kw4, kw5, kw6 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4, string kw5, string kw6, string kw7) : this(new[] { kw1, kw2, kw3, kw4, kw5, kw6, kw7 }) { }
        public EnumHeaderDrawer(params string[] keywords)
        {
            _keywords = keywords.Select(i => new GUIContent(i)).ToArray();
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            => s_lineHeight;

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            position.height -= s_lineHeight - EditorGUIUtility.singleLineHeight;
            try
            {
                var value = (int)prop.floatValue;
                EditorGUI.showMixedValue = prop.hasMixedValue;
                EditorGUI.BeginChangeCheck();
                GUI.Box(position, GUIContent.none, EditorStyles.toolbar);
                value = EditorGUI.Popup(position, label, value, _keywords);
                if (EditorGUI.EndChangeCheck())
                {
                    prop.floatValue = value;
                    editor.RegisterPropertyChangeUndo("Material Keyword");
                    for (var i = 0; i < _keywords.Length; ++i)
                    {
                        var keyword = GetKeywordName(prop.name, _keywords[i].text);
                        foreach (Material mat in prop.targets)
                        {
                            if (value == i)
                                mat.EnableKeyword(keyword);
                            else
                                mat.DisableKeyword(keyword);
                        }
                    }
                }
            }
            finally
            {
                EditorGUI.showMixedValue = false;
            }
        }

        static string GetKeywordName(string propName, string name)
        {
            string n = propName + "_" + name;
            return n.Replace(' ', '_').ToUpperInvariant();
        }
    }
}
