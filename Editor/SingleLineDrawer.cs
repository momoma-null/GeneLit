using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class SingleLineDrawer : MaterialPropertyDrawer
    {
        static bool s_drawing;

        readonly string _extraPropName;
        readonly string _keyword;

        public SingleLineDrawer() : this(default, default) { }

        public SingleLineDrawer(string extraPropName) : this(extraPropName, default) { }

        public SingleLineDrawer(string extraPropName, string keyword)
        {
            _extraPropName = extraPropName;
            _keyword = keyword;
        }

        public override void Apply(MaterialProperty prop)
        {
            if (!string.IsNullOrEmpty(_keyword))
            {
                foreach (Material mat in prop.targets)
                {
                    if (mat.GetTexture(prop.name) != null)
                        mat.EnableKeyword(_keyword);
                    else
                        mat.DisableKeyword(_keyword);
                }
            }
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            => 0;

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            if (s_drawing)
            {
                editor.DefaultShaderProperty(position, prop, label.text);
            }
            else if (prop.type == MaterialProperty.PropType.Texture)
            {
                var oldLabelWidth = EditorGUIUtility.labelWidth;
                EditorGUIUtility.labelWidth = 0f;
                s_drawing = true;
                try
                {
                    EditorGUI.BeginChangeCheck();
                    if (string.IsNullOrEmpty(_extraPropName))
                    {
                        editor.TexturePropertySingleLine(label, prop);
                    }
                    else
                    {
                        var extraProp = MaterialEditor.GetMaterialProperty(prop.targets, _extraPropName);
                        if (extraProp.type == MaterialProperty.PropType.Color && (extraProp.flags & MaterialProperty.PropFlags.HDR) > 0)
                            editor.TexturePropertyWithHDRColor(label, prop, extraProp, false);
                        else
                            editor.TexturePropertySingleLine(label, prop, extraProp);
                    }
                    if (EditorGUI.EndChangeCheck())
                    {
                        if (!string.IsNullOrEmpty(_keyword))
                        {
                            var useTexture = prop.textureValue != null;
                            foreach (Material mat in prop.targets)
                            {
                                if (useTexture)
                                    mat.EnableKeyword(_keyword);
                                else
                                    mat.DisableKeyword(_keyword);
                            }
                        }
                    }
                }
                finally
                {
                    s_drawing = false;
                    EditorGUIUtility.labelWidth = oldLabelWidth;
                }
            }
        }
    }
}
