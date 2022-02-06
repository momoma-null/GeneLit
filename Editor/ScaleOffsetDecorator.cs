using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class ScaleOffsetDecorator : MaterialPropertyDrawer
    {
        bool _initialized = false;

        public ScaleOffsetDecorator() { }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            if (!_initialized)
            {
                prop.ReplacePostDecorator(this);
                _initialized = true;
            }
            return 2f * EditorGUIUtility.singleLineHeight + EditorGUIUtility.standardVerticalSpacing;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            position.xMin += 15f;
            position.y = position.yMax - (2f * EditorGUIUtility.singleLineHeight + 2.5f * EditorGUIUtility.standardVerticalSpacing);
            editor.TextureScaleOffsetProperty(position, prop);
        }
    }
}
