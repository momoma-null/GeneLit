using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    static class MaterialPropertyHandlerUtility
    {
        static readonly Type s_MaterialPropertyHandlerType = typeof(MaterialEditor).Assembly.GetType("UnityEditor.MaterialPropertyHandler");
        static readonly MethodInfo s_GetHandlerInfo = s_MaterialPropertyHandlerType.GetMethod("GetHandler", BindingFlags.NonPublic | BindingFlags.Static);
        static readonly FieldInfo s_m_PropertyDrawerInfo = s_MaterialPropertyHandlerType.GetField("m_PropertyDrawer", BindingFlags.NonPublic | BindingFlags.Instance);
        static readonly FieldInfo s_m_DecoratorDrawersInfo = s_MaterialPropertyHandlerType.GetField("m_DecoratorDrawers", BindingFlags.NonPublic | BindingFlags.Instance);
        static readonly Dictionary<object, EmptyDrawer> s_emptyDrawers = new Dictionary<object, EmptyDrawer>();
        static readonly DefaultDrawer s_defaultDrawer = new DefaultDrawer();

        static object GetHandler(MaterialProperty prop)
            => s_GetHandlerInfo.Invoke(null, new object[] { (prop.targets[0] as Material).shader, prop.name });

        public static void SkipRemainingDrawers(this MaterialProperty prop, MaterialPropertyDrawer drawer)
        {
            var handler = GetHandler(prop);
            if (!s_emptyDrawers.TryGetValue(handler, out var emptyDrawer))
            {
                emptyDrawer = new EmptyDrawer();
                s_emptyDrawers.Add(handler, emptyDrawer);
            }
            if (emptyDrawer.onEnded != null)
                return;
            var oldDrawer = s_m_PropertyDrawerInfo.GetValue(handler);
            if (oldDrawer == null)
                oldDrawer = s_defaultDrawer;
            var oldDecorators = s_m_DecoratorDrawersInfo.GetValue(handler) as List<MaterialPropertyDrawer>;
            var newDecorators = new List<MaterialPropertyDrawer>(oldDecorators.Count);
            foreach (var i in oldDecorators)
            {
                newDecorators.Add(i);
                if (i == drawer)
                    break;
            }
            s_m_PropertyDrawerInfo.SetValue(handler, emptyDrawer);
            s_m_DecoratorDrawersInfo.SetValue(handler, newDecorators);
            emptyDrawer.onEnded = () =>
            {
                s_m_PropertyDrawerInfo.SetValue(handler, oldDrawer);
                s_m_DecoratorDrawersInfo.SetValue(handler, oldDecorators);
                emptyDrawer.onEnded = null;
            };
        }

        public static void ReplacePostDecorator(this MaterialProperty prop, MaterialPropertyDrawer postDecorator)
        {
            var handler = GetHandler(prop);
            var drawer = s_m_PropertyDrawerInfo.GetValue(handler) as MaterialPropertyDrawer;
            if (drawer == null)
                drawer = s_defaultDrawer;
            s_m_PropertyDrawerInfo.SetValue(handler, new WrapDrawer(drawer, postDecorator));
            var oldDecorators = s_m_DecoratorDrawersInfo.GetValue(handler) as List<MaterialPropertyDrawer>;
            var newDecorators = new List<MaterialPropertyDrawer>(oldDecorators.Count - 1);
            foreach (var i in oldDecorators)
            {
                if (i != postDecorator)
                    newDecorators.Add(i);
            }
            s_m_DecoratorDrawersInfo.SetValue(handler, newDecorators);
        }

        sealed class EmptyDrawer : MaterialPropertyDrawer
        {
            public Action onEnded;

            public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            {
                onEnded?.Invoke();
                return -EditorGUIUtility.standardVerticalSpacing;
            }

            public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
                => onEnded?.Invoke();
        }

        sealed class DefaultDrawer : MaterialPropertyDrawer
        {
            public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
                => MaterialEditor.GetDefaultPropertyHeight(prop);
            public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
                => editor.DefaultShaderProperty(position, prop, label);
        }

        sealed class WrapDrawer : MaterialPropertyDrawer
        {
            readonly MaterialPropertyDrawer _mainDrawer;
            readonly MaterialPropertyDrawer _postDecorator;

            internal WrapDrawer(MaterialPropertyDrawer mainDrawer, MaterialPropertyDrawer postDecorator)
            {
                _mainDrawer = mainDrawer;
                _postDecorator = postDecorator;
            }

            public override void Apply(MaterialProperty prop)
            {
                _mainDrawer.Apply(prop);
            }

            public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
                => 0;

            public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
            {
                position = EditorGUILayout.GetControlRect(true, _mainDrawer.GetPropertyHeight(prop, label.text, editor), EditorStyles.layerMaskField);
                _mainDrawer.OnGUI(position, prop, label, editor);
                position = EditorGUILayout.GetControlRect(true, _postDecorator.GetPropertyHeight(prop, label.text, editor), EditorStyles.layerMaskField);
                _postDecorator.OnGUI(position, prop, label, editor);
            }
        }
    }
}
