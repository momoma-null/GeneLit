
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class GeneLitGUI : ShaderGUI
    {
        static readonly Dictionary<string, ShurikenHeader> _shurikenHeaders = new();
        static readonly Dictionary<string, HideDecorator> _hideDecorators = new();
        static readonly Dictionary<string, SingleLineDrawer> _singleLineDrawers = new();

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            base.AssignNewShaderToMaterial(material, oldShader, newShader);

            var propertyCount = newShader.GetPropertyCount();
            for (var i = 0; i < propertyCount; ++i)
            {
                var displayName = newShader.GetPropertyDescription(i);
                var key = GetKey(newShader, displayName);

                if (TryGetShurikenHeader(key, displayName, out var shurikenHeader))
                {
                    shurikenHeader.ApplyMaterial(material);
                }
                if (TryGetSingleLineDrawer(key, displayName, out var singleLineDrawer))
                {
                    singleLineDrawer.ApplyMaterial(material, newShader.GetPropertyName(i));
                }
            }
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            var shader = (materialEditor.targets[0] as Material).shader;

            materialEditor.SetDefaultGUIWidths();

            foreach (var prop in properties)
            {
                if ((prop.flags & MaterialProperty.PropFlags.HideInInspector) != 0) continue;

                var displayName = prop.displayName;
                var displayNameSpan = displayName.AsSpan();
                var key = GetKey(shader, displayName);

                if (TryGetShurikenHeader(key, displayNameSpan, out var shurikenHeader))
                {
                    shurikenHeader.OnGUI(materialEditor);
                    displayNameSpan = displayNameSpan[shurikenHeader.NameOffset..];
                }

                if (TryGetHideDecorator(key, displayNameSpan, out var hideDecorator))
                {
                    if (hideDecorator.IsHidden(materialEditor)) continue;
                    displayNameSpan = displayNameSpan[hideDecorator.NameOffset..];
                }

                if (TryGetSingleLineDrawer(key, displayNameSpan, out var singleLineDrawer))
                {
                    singleLineDrawer.OnGUI(materialEditor, prop, properties);
                    continue;
                }

                materialEditor.ShaderProperty(prop, displayNameSpan.ToString());
            }

            EditorGUILayout.Space();
            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
            materialEditor.DoubleSidedGIField();
        }

        public static bool IsKeywordEnabled(UnityEngine.Object[] materials, string keyword)
        {
            foreach (Material mat in materials)
            {
                if (!mat.IsKeywordEnabled(keyword)) return false;
            }
            return true;
        }

        public static bool IsKeywordDisabled(UnityEngine.Object[] materials, string keyword)
        {
            foreach (Material mat in materials)
            {
                if (mat.IsKeywordEnabled(keyword)) return false;
            }
            return true;
        }

        public static (bool mixed, bool enabled) GetKeyword(UnityEngine.Object[] materials, string keyword)
        {
            if (materials.Length < 1) return (false, false);

            var enabled = (materials[0] as Material).IsKeywordEnabled(keyword);
            for (var i = 1; i < materials.Length; ++i)
            {
                if ((materials[i] as Material).IsKeywordEnabled(keyword) != enabled)
                {
                    return (true, enabled);
                }
            }
            return (false, enabled);
        }

        public static (bool mixed, int index) GetKeyword(UnityEngine.Object[] materials, string[] keywords)
        {
            if (materials.Length < 1) return (false, 0);

            var initialMaterial = materials[0] as Material;
            var index = GetKeyword(initialMaterial, keywords);
            var keyword = keywords[index];
            for (var i = 1; i < materials.Length; ++i)
            {
                if ((materials[i] as Material).IsKeywordEnabled(keyword)) continue;
                return (true, index);
            }
            return (false, index);
        }

        public static int GetKeyword(Material mat, string[] keywords)
        {
            for (var i = 0; i < keywords.Length; ++i)
            {
                if (mat.IsKeywordEnabled(keywords[i])) return i;
            }
            return 0;
        }

        public static void SetKeyword(UnityEngine.Object[] materials, string keyword, bool enabled)
        {
            foreach (Material mat in materials)
            {
                SetKeyword(mat, keyword, enabled);
            }
        }

        public static void SetKeyword(UnityEngine.Object[] materials, string[] keywords, int index)
        {
            foreach (Material mat in materials)
            {
                SetKeyword(mat, keywords, index);
            }
        }

        public static void SetKeyword(Material mat, string[] keywords, int index)
        {
            for (var i = 0; i < keywords.Length; ++i)
            {
                SetKeyword(mat, keywords[i], i == index);
            }
        }

        public static void SetKeyword(Material mat, string keyword, bool enabled)
        {
            if (enabled)
                mat.EnableKeyword(keyword);
            else
                mat.DisableKeyword(keyword);
        }

        public static bool TryGetAttributeWithArgument(ReadOnlySpan<char> chars, ReadOnlySpan<char> attr, out int index, out int length)
        {
            var startIndex = chars.IndexOf(attr);
            if (startIndex < 0)
            {
                index = length = 0;
                return false;
            }
            index = startIndex + attr.Length;
            length = chars[index..].IndexOf(")]");
            if (length < 0) return false;
            return true;
        }

        public static bool HasAttribute(ReadOnlySpan<char> chars, ReadOnlySpan<char> attr)
        {
            return chars.IndexOf(attr) > -1;
        }

        string GetKey(Shader shader, string displayName)
        {
            return shader.GetInstanceID() + '_' + displayName;
        }

        static bool TryGetShurikenHeader(string key, ReadOnlySpan<char> displayName, out ShurikenHeader shurikenHeader)
        {
            if (!_shurikenHeaders.TryGetValue(key, out shurikenHeader))
            {
                ShurikenHeader.TryGetDecorator(displayName, out shurikenHeader);
                _shurikenHeaders[key] = shurikenHeader;
            }
            return shurikenHeader != null;
        }

        static bool TryGetHideDecorator(string key, ReadOnlySpan<char> displayName, out HideDecorator hideDecorator)
        {
            if (!_hideDecorators.TryGetValue(key, out hideDecorator))
            {
                HideDecorator.TryGetDecorator(displayName, out hideDecorator);
                _hideDecorators[key] = hideDecorator;
            }
            return hideDecorator != null;
        }

        static bool TryGetSingleLineDrawer(string key, ReadOnlySpan<char> displayName, out SingleLineDrawer singleLineDrawer)
        {
            if (!_singleLineDrawers.TryGetValue(key, out singleLineDrawer))
            {
                SingleLineDrawer.TryGetDrawer(displayName, out singleLineDrawer);
                _singleLineDrawers[key] = singleLineDrawer;
            }
            return singleLineDrawer != null;
        }
    }
}
