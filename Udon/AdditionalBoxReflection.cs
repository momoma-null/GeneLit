
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace MomomaAssets.Udon
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    sealed class AdditionalBoxReflection : UdonSharpBehaviour
    {
        const string POSITION_PROPERTY = "_UdonAdditionalBoxPosition";
        const string ROTATION_PROPERTY = "_UdonAdditionalBoxRotation";
        const string SIZE_PROPERTY = "_UdonAdditionalBoxSize";
        const int ADDITIONAL_BOX_COUNT = 4;

        [Header("Max 4")]
        [SerializeField]
        BoxCollider[] boxRange;

        void Start()
        {
            var positionProperty = VRCShader.PropertyToID(POSITION_PROPERTY);
            var rotationProperty = VRCShader.PropertyToID(ROTATION_PROPERTY);
            var sizeProperty = VRCShader.PropertyToID(SIZE_PROPERTY);
            var positions = new Vector4[ADDITIONAL_BOX_COUNT];
            var rotations = new Vector4[ADDITIONAL_BOX_COUNT];
            var sizes = new Vector4[ADDITIONAL_BOX_COUNT];
            var count = boxRange == null ? 0 : Mathf.Min(boxRange.Length, ADDITIONAL_BOX_COUNT);
            for (var i = 0; i < count; ++i)
            {
                var box = boxRange[i];
                var boxTransform = box.transform;
                var rotation = boxTransform.rotation;
                positions[i] = boxTransform.position + rotation * box.center;
                rotations[i] = new Vector4(rotation.x, rotation.y, rotation.z, rotation.w);
                sizes[i] = box.size;
                box.enabled = false;
            }
            VRCShader.SetGlobalVectorArray(positionProperty, positions);
            VRCShader.SetGlobalVectorArray(rotationProperty, rotations);
            VRCShader.SetGlobalVectorArray(sizeProperty, sizes);
        }
    }
}
