using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class ScaleOffsetDecorator : MaterialPropertyDrawer
    {
        public ScaleOffsetDecorator() { }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return 2f * EditorGUIUtility.singleLineHeight + EditorGUIUtility.standardVerticalSpacing;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            position.y = position.yMax - (2f * EditorGUIUtility.singleLineHeight + 2.5f * EditorGUIUtility.standardVerticalSpacing);
            editor.TextureScaleOffsetProperty(position, prop);
        }
    }
}
