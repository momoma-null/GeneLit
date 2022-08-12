using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class EmissionDecorator : MaterialPropertyDrawer
    {
        const string k_EmissionKeyword = "_EMISSION";

        bool _initialized = false;

        public EmissionDecorator() { }

        public override void Apply(MaterialProperty prop)
        {
            foreach (Material mat in prop.targets)
            {
                MaterialEditor.FixupEmissiveFlag(mat);
                if (0 != (mat.globalIlluminationFlags & MaterialGlobalIlluminationFlags.AnyEmissive))
                    mat.EnableKeyword(k_EmissionKeyword);
                else
                    mat.DisableKeyword(k_EmissionKeyword);
            }
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            if (!_initialized)
            {
                prop.ReplacePostDecorator(this);
                _initialized = true;
            }
            EditorGUI.BeginChangeCheck();
            editor.RegisterPropertyChangeUndo("Emission");
            editor.LightmapEmissionProperty(position, 0);
            if (EditorGUI.EndChangeCheck())
            {
                Apply(prop);
            }
        }
    }
}
