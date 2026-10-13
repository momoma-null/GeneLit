
using System;
using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    class ShurikenHeader
    {
        protected static class Styles
        {
            public static readonly GUIStyle HeaderStyle = new GUIStyle("ShurikenModuleTitle")
            {
                font = EditorStyles.label.font,
                fontSize = EditorStyles.label.fontSize,
                border = new RectOffset(7, 7, 4, 4),
                fixedHeight = 22f,
                contentOffset = new Vector2(4f, -2f)
            };
        }

        public static bool TryGetDecorator(ReadOnlySpan<char> name, out ShurikenHeader decorator)
        {
            if (GeneLitGUI.TryGetAttributeWithArgument(name, "[ShurikenHeader(", out var index, out var length))
            {
                var args = name.Slice(index, length).ToString().Split(',');
                var nameOffset = index + length + 2;
                if (args.Length == 1)
                {
                    decorator = new ShurikenHeader(args[0], nameOffset);
                    return true;
                }
                else if (args.Length == 2)
                {
                    decorator = new ShurikenHeaderToggle(args[0], nameOffset, args[1]);
                    return true;
                }
                else if (args.Length > 2)
                {
                    decorator = new ShurikenHeaderEnum(args[0], nameOffset, args);
                    return true;
                }
            }
            decorator = null;
            return false;
        }

        public int NameOffset { get; }

        protected readonly GUIContent _label;

        public ShurikenHeader(string label, int nameOffset)
        {
            _label = new GUIContent(label);
            NameOffset = nameOffset;
        }

        public virtual void OnGUI(MaterialEditor materialEditor)
        {
            GUILayout.Space(8f);
            GUILayout.Box(_label, Styles.HeaderStyle);
        }

        public virtual void ApplyMaterial(Material material) { }
    }

    sealed class ShurikenHeaderToggle : ShurikenHeader
    {
        readonly string _keyword;

        public ShurikenHeaderToggle(string label, int nameOffset, string keyword) : base(label, nameOffset)
        {
            _keyword = keyword;
        }

        public override void OnGUI(MaterialEditor materialEditor)
        {
            var (hasMixedValue, enabled) = GeneLitGUI.GetKeyword(materialEditor.targets, _keyword);
            var oldLabelWidth = EditorGUIUtility.labelWidth;
            try
            {
                EditorGUIUtility.labelWidth = 0f;
                EditorGUI.showMixedValue = hasMixedValue;

                GUILayout.Space(8f);
                GUILayout.Box(GUIContent.none, Styles.HeaderStyle);

                var position = GUILayoutUtility.GetLastRect();
                position.xMin += 4f;
                EditorGUI.BeginChangeCheck();
                enabled = EditorGUI.ToggleLeft(position, _label, enabled);
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Material Keyword");
                    GeneLitGUI.SetKeyword(materialEditor.targets, _keyword, enabled);
                }
            }
            finally
            {
                EditorGUI.showMixedValue = false;
                EditorGUIUtility.labelWidth = oldLabelWidth;
            }
        }
    }

    sealed class ShurikenHeaderEnum : ShurikenHeader
    {
        readonly GUIContent[] _options;
        readonly string[] _keywords;

        public ShurikenHeaderEnum(string label, int nameOffset, string[] args) : base(label, nameOffset)
        {
            var prefix = args[1];
            var length = args.Length - 2;
            _options = new GUIContent[length];
            _keywords = new string[length];
            for (var i = 0; i < length; ++i)
            {
                _options[i] = new GUIContent(args[i + 2]);
                _keywords[i] = (prefix + "_" + args[i + 2]).ToUpperInvariant();
            }
        }

        public override void OnGUI(MaterialEditor materialEditor)
        {
            var (hasMixedValue, selected) = GeneLitGUI.GetKeyword(materialEditor.targets, _keywords);
            var oldLabelWidth = EditorGUIUtility.labelWidth;
            try
            {
                EditorGUIUtility.labelWidth = 0f;
                EditorGUI.showMixedValue = hasMixedValue;

                GUILayout.Space(8f);
                GUILayout.Box(GUIContent.none, Styles.HeaderStyle);

                var position = GUILayoutUtility.GetLastRect();
                position.xMin += 4f;
                EditorGUI.BeginChangeCheck();
                selected = EditorGUI.Popup(position, _label, selected, _options);
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Material Keyword");
                    GeneLitGUI.SetKeyword(materialEditor.targets, _keywords, selected);
                }
            }
            finally
            {
                EditorGUI.showMixedValue = false;
                EditorGUIUtility.labelWidth = oldLabelWidth;
            }
        }

        public override void ApplyMaterial(Material material)
        {
            var keywordIndex = GeneLitGUI.GetKeyword(material, _keywords);
            GeneLitGUI.SetKeyword(material, _keywords, keywordIndex);
        }
    }
}
