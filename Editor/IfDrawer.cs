using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    sealed class IfDrawer : MaterialPropertyDrawer
    {
        static readonly float s_helpBoxHeight = EditorStyles.helpBox.CalcHeight(GUIContent.none, 0f);

        readonly string _conditionsName;
        readonly float _value;

        public IfDrawer(string conditionsName, float value)
        {
            _conditionsName = conditionsName;
            _value = value;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            var conditionsProp = MaterialEditor.GetMaterialProperty(prop.targets, _conditionsName);
            if (conditionsProp.hasMixedValue)
                return s_helpBoxHeight;
            else if (conditionsProp.floatValue == _value)
                return base.GetPropertyHeight(prop, label, editor);
            else
                return 0;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            var conditionsProp = MaterialEditor.GetMaterialProperty(prop.targets, _conditionsName);
            if (conditionsProp.hasMixedValue)
                EditorGUI.HelpBox(position, $"{prop.displayName} is hidden because {conditionsProp.displayName} has mixed value.", MessageType.Info);
            else if (conditionsProp.floatValue == _value)
                editor.DefaultShaderProperty(position, prop, label);
        }
    }

    sealed class IfNotDrawer : MaterialPropertyDrawer
    {
        static readonly float s_helpBoxHeight = EditorStyles.helpBox.CalcHeight(GUIContent.none, 0f);

        readonly string _conditionsName;
        readonly float _value;

        public IfNotDrawer(string conditionsName, float value)
        {
            _conditionsName = conditionsName;
            _value = value;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            var conditionsProp = MaterialEditor.GetMaterialProperty(prop.targets, _conditionsName);
            if (conditionsProp.hasMixedValue)
                return s_helpBoxHeight;
            else if (conditionsProp.floatValue != _value)
                return base.GetPropertyHeight(prop, label, editor);
            else
                return 0;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            var conditionsProp = MaterialEditor.GetMaterialProperty(prop.targets, _conditionsName);
            if (conditionsProp.hasMixedValue)
                EditorGUI.HelpBox(position, $"{prop.displayName} is hidden because {conditionsProp.displayName} has mixed value.", MessageType.Info);
            else if (conditionsProp.floatValue != _value)
                editor.DefaultShaderProperty(position, prop, label);
        }
    }
}
