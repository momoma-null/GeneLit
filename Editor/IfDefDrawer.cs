using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class IfDefDecorator : MaterialPropertyDrawer
    {
        readonly string _keyword;

        public IfDefDecorator(string keyword)
        {
            _keyword = keyword;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (!enabled)
            {
                prop.SkipRemainingDrawers(this);
            }
            else
            {
                for (var i = 1; i < materials.Length; ++i)
                {
                    if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    {
                        prop.SkipRemainingDrawers(this);
                        break;
                    }
                }
            }
            return 0;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (!enabled)
            {
                prop.SkipRemainingDrawers(this);
            }
            else
            {
                for (var i = 1; i < materials.Length; ++i)
                {
                    if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    {
                        prop.SkipRemainingDrawers(this);
                        break;
                    }
                }
            }
        }
    }

    sealed class IfNDefDecorator : MaterialPropertyDrawer
    {
        static readonly float s_helpBoxHeight = EditorStyles.helpBox.CalcHeight(GUIContent.none, 0f);

        readonly string _keyword;

        public IfNDefDecorator(string keyword)
        {
            _keyword = keyword;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (enabled)
            {
                prop.SkipRemainingDrawers(this);
            }
            else
            {
                for (var i = 1; i < materials.Length; ++i)
                {
                    if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    {
                        prop.SkipRemainingDrawers(this);
                        break;
                    }
                }
            }
            return 0;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            var materials = Array.ConvertAll(prop.targets, o => o as Material);
            var enabled = materials[0].IsKeywordEnabled(_keyword);
            if (enabled)
            {
                prop.SkipRemainingDrawers(this);
            }
            else
            {
                for (var i = 1; i < materials.Length; ++i)
                {
                    if (materials[i].IsKeywordEnabled(_keyword) != enabled)
                    {
                        prop.SkipRemainingDrawers(this);
                        break;
                    }
                }
            }
        }
    }
}
