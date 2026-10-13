using System;
using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class SingleLineDrawer
    {
        public static bool TryGetDrawer(ReadOnlySpan<char> name, out SingleLineDrawer drawer)
        {
            if (GeneLitGUI.TryGetAttributeWithArgument(name, "[SingleLine(", out var index, out var length))
            {
                var args = name.Slice(index, length);
                var arg1Index = args.IndexOf(',');
                var keyword = "";
                string extraPropName;
                if (arg1Index > -1)
                {
                    extraPropName = args[..arg1Index].ToString();
                    keyword = args[(arg1Index + 1)..].ToString();
                }
                else
                {
                    extraPropName = args.ToString();
                }
                var label = name[(name.LastIndexOf(']') + 1)..].ToString();
                var hasScaleOffset = GeneLitGUI.HasAttribute(name, "[ScaleOffset]");
                drawer = new SingleLineDrawer(extraPropName, keyword, label, hasScaleOffset);
                return true;
            }
            drawer = null;
            return false;
        }

        readonly string _extraPropName;
        readonly string _keyword;
        readonly GUIContent _label;
        readonly bool _hasScaleOffset;

        public SingleLineDrawer(string extraPropName, string keyword, string label, bool hasScaleOffset)
        {
            _extraPropName = extraPropName;
            _keyword = keyword;
            _label = new GUIContent(label);
            _hasScaleOffset = hasScaleOffset;
        }

        public void ApplyMaterial(Material material, string name)
        {
            if (!string.IsNullOrEmpty(_keyword))
            {
                var enabled = material.GetTexture(name) != null;
                GeneLitGUI.SetKeyword(material, _keyword, enabled);
            }
        }

        public void OnGUI(MaterialEditor materialEditor, MaterialProperty property, MaterialProperty[] properties)
        {
            var extraProp = Array.Find(properties, x => x.name == _extraPropName);
            var oldLabelWidth = EditorGUIUtility.labelWidth;
            try
            {
                EditorGUIUtility.labelWidth = 0f;
                EditorGUI.BeginChangeCheck();
                if (extraProp == null || (!string.IsNullOrEmpty(_keyword) && !GeneLitGUI.IsKeywordEnabled(materialEditor.targets, _keyword)))
                {
                    materialEditor.TexturePropertySingleLine(_label, property);
                }
                else
                {
                    if (extraProp.type == MaterialProperty.PropType.Color && (extraProp.flags & MaterialProperty.PropFlags.HDR) > 0)
                        materialEditor.TexturePropertyWithHDRColor(_label, property, extraProp, false);
                    else
                        materialEditor.TexturePropertySingleLine(_label, property, extraProp);
                }
                if (EditorGUI.EndChangeCheck())
                {
                    if (!string.IsNullOrEmpty(_keyword))
                    {
                        var useTexture = property.textureValue != null;
                        GeneLitGUI.SetKeyword(materialEditor.targets, _keyword, useTexture);
                    }
                }
                if (_hasScaleOffset && property.textureValue != null)
                {
                    using (new EditorGUI.IndentLevelScope(1))
                    {
                        materialEditor.TextureScaleOffsetProperty(property);
                    }
                }
            }
            finally
            {
                EditorGUIUtility.labelWidth = oldLabelWidth;
            }
        }
    }
}
