
using System;
using UnityEditor;

namespace MomomaAssets.GeneLit
{
    class HideDecorator
    {
        static readonly HideDecorator Default = new(0);

        public static bool TryGetDecorator(ReadOnlySpan<char> name, out HideDecorator decorator)
        {
            if (GeneLitGUI.HasAttribute(name, "[Hide]"))
            {
                decorator = Default;
                return true;
            }
            else if (GeneLitGUI.TryGetAttributeWithArgument(name, "[IfDef(", out var index, out var length))
            {
                var nameOffset = index + length + 2;
                if (name[index] == '!')
                {
                    var keyword = name.Slice(index + 1, length - 1).ToString();
                    decorator = new IfNDefDecorator(keyword, nameOffset);
                }
                else
                {
                    var keyword = name.Slice(index, length).ToString();
                    decorator = new IfDefDecorator(keyword, nameOffset);
                }
                return true;
            }
            decorator = null;
            return false;
        }

        public int NameOffset { get; }

        protected HideDecorator(int nameoffset) => NameOffset = nameoffset;

        public virtual bool IsHidden(MaterialEditor materialEditor) => true;
    }

    sealed class IfDefDecorator : HideDecorator
    {
        readonly string _keyword;

        public IfDefDecorator(string keyword, int nameOffset) : base(nameOffset)
        {
            _keyword = keyword;
        }

        public override bool IsHidden(MaterialEditor materialEditor)
        {
            return !GeneLitGUI.IsKeywordEnabled(materialEditor.targets, _keyword);
        }
    }

    sealed class IfNDefDecorator : HideDecorator
    {
        readonly string _keyword;

        public IfNDefDecorator(string keyword, int nameOffset) : base(nameOffset)
        {
            _keyword = keyword;
        }

        public override bool IsHidden(MaterialEditor materialEditor)
        {
            return !GeneLitGUI.IsKeywordDisabled(materialEditor.targets, _keyword);
        }
    }
}
