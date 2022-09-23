using System;
using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class ShurikenHeaderDecorator : MaterialPropertyDrawer
    {
        public static class Styles
        {
            public static readonly GUIStyle HeaderStyle = new GUIStyle("ShurikenModuleTitle")
            {
                font = EditorStyles.label.font,
                fontSize = EditorStyles.label.fontSize,
                border = new RectOffset(7, 7, 4, 4),
                fixedHeight = 22f,
                contentOffset = new Vector2(4f, -2f)
            };

            public readonly static float HeaderHeight = Styles.HeaderStyle.CalcHeight(GUIContent.none, 0) + EditorGUIUtility.standardVerticalSpacing;
        }

        readonly GUIContent title;

        public ShurikenHeaderDecorator(string title)
        {
            this.title = new GUIContent(title);
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            => Styles.HeaderHeight;

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            GUI.Box(position, title, Styles.HeaderStyle);
        }
    }

    sealed class ToggleHeaderDecorator : MaterialPropertyDrawer
    {
        readonly GUIContent _title;
        readonly string _keyword;

        public ToggleHeaderDecorator(string title, string keyword)
        {
            _title = EditorGUIUtility.TrTextContent(title);
            _keyword = keyword;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            => ShurikenHeaderDecorator.Styles.HeaderHeight;

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            position.height -= ShurikenHeaderDecorator.Styles.HeaderHeight - EditorGUIUtility.singleLineHeight;
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
                GUI.Box(position, GUIContent.none, ShurikenHeaderDecorator.Styles.HeaderStyle);
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

    sealed class EnumHeaderDrawer : MaterialPropertyDrawer
    {
        readonly GUIContent[] _keywords;

        public EnumHeaderDrawer(string kw1, string kw2) : this(new[] { kw1, kw2 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3) : this(new[] { kw1, kw2, kw3 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4) : this(new[] { kw1, kw2, kw3, kw4 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4, string kw5) : this(new[] { kw1, kw2, kw3, kw4, kw5 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4, string kw5, string kw6) : this(new[] { kw1, kw2, kw3, kw4, kw5, kw6 }) { }
        public EnumHeaderDrawer(string kw1, string kw2, string kw3, string kw4, string kw5, string kw6, string kw7) : this(new[] { kw1, kw2, kw3, kw4, kw5, kw6, kw7 }) { }
        public EnumHeaderDrawer(params string[] keywords)
        {
            _keywords = Array.ConvertAll(keywords, i => new GUIContent(i));
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            => ShurikenHeaderDecorator.Styles.HeaderHeight;

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            position.height -= ShurikenHeaderDecorator.Styles.HeaderHeight - EditorGUIUtility.singleLineHeight;
            var oldLabelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth = 0f;
            try
            {
                var value = (int)prop.floatValue;
                EditorGUI.showMixedValue = prop.hasMixedValue;
                EditorGUI.BeginChangeCheck();
                GUI.Box(position, GUIContent.none, ShurikenHeaderDecorator.Styles.HeaderStyle);
                position.xMin += 4f;
                value = EditorGUI.Popup(position, label, value, _keywords);
                if (EditorGUI.EndChangeCheck())
                {
                    prop.floatValue = value;
                    editor.RegisterPropertyChangeUndo("Material Keyword");
                    SetKeyword(prop, value);
                }
            }
            finally
            {
                EditorGUI.showMixedValue = false;
                EditorGUIUtility.labelWidth = oldLabelWidth;
            }
        }

        public override void Apply(MaterialProperty prop)
        {
            base.Apply(prop);
            if (prop.hasMixedValue)
                return;
            SetKeyword(prop, (int)prop.floatValue);
        }

        void SetKeyword(MaterialProperty prop, int index)
        {
            for (var i = 0; i < _keywords.Length; ++i)
            {
                var keyword = GetKeywordName(prop.name, _keywords[i].text);
                foreach (Material mat in prop.targets)
                {
                    if (index == i)
                        mat.EnableKeyword(keyword);
                    else
                        mat.DisableKeyword(keyword);
                }
            }
        }

        static string GetKeywordName(string propName, string name)
        {
            string n = propName + "_" + name;
            return n.Replace(' ', '_').ToUpperInvariant();
        }
    }
}
