using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class LightmapFlagsDecorator : MaterialPropertyDrawer
    {
        public LightmapFlagsDecorator() { }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return EditorGUIUtility.singleLineHeight;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            editor.RegisterPropertyChangeUndo("Lightmap Emission");
            editor.LightmapEmissionProperty(position, 0);
        }
    }
}
