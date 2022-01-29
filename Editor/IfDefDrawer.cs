using System;
using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class IfDefDrawer : MaterialPropertyDrawer
    {
        readonly string _keyword;

        public IfDefDrawer(string keyword)
        {
            _keyword = keyword;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (!enabled)
                return 0;
            for (var i = 1; i < materials.Length; ++i)
                if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    return 0;
            return MaterialEditor.GetDefaultPropertyHeight(prop);
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (!enabled)
                return;
            for (var i = 1; i < materials.Length; ++i)
                if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    return;
            editor.DefaultShaderProperty(position, prop, label);
        }
    }

    sealed class IfNDefDrawer : MaterialPropertyDrawer
    {
        static readonly float s_helpBoxHeight = EditorStyles.helpBox.CalcHeight(GUIContent.none, 0f);

        readonly string _keyword;

        public IfNDefDrawer(string keyword)
        {
            _keyword = keyword;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (enabled)
                return 0;
            for (var i = 1; i < materials.Length; ++i)
                if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    return 0;
            return MaterialEditor.GetDefaultPropertyHeight(prop);
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (enabled)
                return;
            for (var i = 1; i < materials.Length; ++i)
                if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    return;
            editor.DefaultShaderProperty(position, prop, label);
        }
    }
}
