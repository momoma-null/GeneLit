using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class ToggleHeaderDrawer : MaterialPropertyDrawer
    {
        readonly string _keyword;

        public ToggleHeaderDrawer(string keyword)
        {
            _keyword = keyword;
        }

        public override void Apply(MaterialProperty prop)
        {
            if (!string.IsNullOrEmpty(_keyword))
            {
                foreach (Material mat in prop.targets)
                {
                    if (mat.GetFloat(prop.name) != 0)
                        mat.EnableKeyword(_keyword);
                    else
                        mat.DisableKeyword(_keyword);
                }
            }
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            if (prop.type == MaterialProperty.PropType.Float)
            {
                EditorGUI.BeginChangeCheck();
                GUI.Box(position, GUIContent.none, EditorStyles.toolbar);
                var enable = EditorGUI.ToggleLeft(position, label, prop.floatValue != 0);
                if (EditorGUI.EndChangeCheck())
                {
                    prop.floatValue = enable ? 1f : 0f;
                    if (!string.IsNullOrEmpty(_keyword))
                    {
                        foreach (Material mat in prop.targets)
                        {
                            if (enable)
                                mat.EnableKeyword(_keyword);
                            else
                                mat.DisableKeyword(_keyword);
                        }
                    }
                }
            }
        }
    }
}
