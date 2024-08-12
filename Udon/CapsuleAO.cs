
# if UDONSHARP
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace MomomaAssets.Udon
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    sealed class CapsuleAO : UdonSharpBehaviour
    {
        const string TOP_RADIUS_PROPERTY = "_UdonTopAndRadius";
        const string BOTTOM_PROPERTY = "_UdonBottom";
        const int CAPSULE_COUNT = 16;

        readonly VRCPlayerApi[] players = new VRCPlayerApi[CAPSULE_COUNT];
        readonly Vector4[] topAndRadius = new Vector4[CAPSULE_COUNT];
        readonly Vector4[] bottom = new Vector4[CAPSULE_COUNT];

        int topAndRadiusID;
        int bottomID;

        void Start()
        {
            topAndRadiusID = VRCShader.PropertyToID(TOP_RADIUS_PROPERTY);
            bottomID = VRCShader.PropertyToID(BOTTOM_PROPERTY);
        }

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            ReloadPlayers();
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            ReloadPlayers();
        }

        void ReloadPlayers()
        {
            VRCPlayerApi.GetPlayers(players);
            for (var i = 0; i < players.Length; ++i)
            {
                topAndRadius[i] = Vector4.zero;
                bottom[i] = Vector4.zero;
            }
        }

        void LateUpdate()
        {
            for (var i = 0; i < players.Length; ++i)
            {
                var player = players[i];
                if (player == null || !player.IsValid())
                    continue;
                var footPos = (player.GetBonePosition(HumanBodyBones.LeftFoot) + player.GetBonePosition(HumanBodyBones.RightFoot)) * 0.5f;
                if (footPos.Equals(Vector3.zero))
                    footPos = player.GetPosition();
                var headPos = player.GetBonePosition(HumanBodyBones.Head);
                if (headPos.Equals(Vector3.zero))
                    headPos = footPos + Vector3.up * player.GetAvatarEyeHeightAsMeters();
                topAndRadius[i] = headPos * 0.75f + footPos * 0.25f;
                topAndRadius[i].w = (headPos - footPos).magnitude * 0.25f;
                bottom[i] = headPos * 0.25f + footPos * 0.75f;
            }
            VRCShader.SetGlobalVectorArray(topAndRadiusID, topAndRadius);
            VRCShader.SetGlobalVectorArray(bottomID, bottom);
        }
    }
}
#endif
