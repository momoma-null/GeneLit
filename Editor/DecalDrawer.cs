
using UnityEditor;
using UnityEngine;

namespace MomomaAssets.GeneLit
{
    sealed class DecalDrawer : MaterialPropertyDrawer
    {
        readonly GUIContent[] options = new[] { new GUIContent("None"), new GUIContent("Decal") };
        readonly int[] optionValues = new[] { 0, -1 };

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            MaterialEditor.BeginProperty(position, prop);
            using (var change = new EditorGUI.ChangeCheckScope())
            {
                var newValue = EditorGUI.IntPopup(position, label, (int)prop.floatValue, options, optionValues);
                if (change.changed)
                {
                    prop.floatValue = newValue;
                }
            }
            MaterialEditor.EndProperty();
        }
    }
}
