import 'dart:convert';

import 'package:flutter/material.dart';

import '../../internal/sdk/zim/Define/zim_define.dart';
import '../../internal/sdk/utils/flutter_extension.dart';
import '../../internal/sdk/zim/Define/zim_room_request.dart';
import '../../live_audio_room_manager.dart';
import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';
import '../common/zego_switch_camera_button.dart';
import '../common/zego_toggle_camera_button.dart';
import '../common/zego_toggle_microphone_button.dart';

class ZegoLiveBottomBar extends StatefulWidget {
  const ZegoLiveBottomBar({
    this.applying,
    super.key,
  });

  final ValueNotifier<bool>? applying;

  @override
  State<ZegoLiveBottomBar> createState() => _ZegoLiveBottomBarState();
}

class _ZegoLiveBottomBarState extends State<ZegoLiveBottomBar> {
  RoomRequest? myRoomRequest;

  @override
  Widget build(BuildContext context) {
    if (ZEGOSDKManager.instance.currentUser == null) {
      return Container();
    } else {
      return ValueListenableBuilder<ZegoLiveRole>(
        valueListenable: ZegoLiveStreamingManager.instance.currentUserRoleNoti,
        builder: (context, role, _) {
          return getBottomBar(role);
        },
      );
    }
  }

  Widget getBottomBar(ZegoLiveRole role) {
    return buttonView(role);
  }

  Widget buttonView(ZegoLiveRole role) {
    if (role == ZegoLiveRole.host) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          switchCameraButton(),
        ],
      );
    } else if (role == ZegoLiveRole.audience) {
      return ValueListenableBuilder<bool>(
        valueListenable: widget.applying!,
        builder: (context, state, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 50, height: 50),
              const SizedBox(width: 50, height: 50),
              const SizedBox(width: 50, height: 50),
              if (state) cancelApplyCohostButton() else applyCoHostButton(),
            ],
          );
        },
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          switchCameraButton(),
          endCohostButton(),
        ],
      );
    }
  }

  Widget toggleMicButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleMicrophoneButton(),
      );
    });
  }

  Widget toggleCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleCameraButton(),
      );
    });
  }

  Widget switchCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: ZegoSwitchCameraButton(),
      );
    });
  }

  Widget applyCoHostButton() {
    return SizedBox(
      width: 120,
      height: 40,
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: const BorderSide(width: 1, color: Colors.white)),
          onPressed: () {
            final signaling = jsonEncode({
              'room_request_type': RoomRequestType.audienceApplyToBecomeCoHost,
            });
            ZEGOSDKManager.instance.zimService
                .sendRoomRequest(ZegoLiveStreamingManager.instance.hostNoti.value?.userID ?? '', signaling)
                .then((value) {
              widget.applying?.value = true;
              myRoomRequest = ZEGOSDKManager.instance.zimService
                  .roomRequestMapNoti.value[value.requestID];
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('apply to co-host failed: $error')));
            });
          },
          child: const Text(
            'Apply to co-host',
            style: TextStyle(color: Colors.white),
          )),
    );
  }

  Widget cancelApplyCohostButton() {
    return SizedBox(
      width: 120,
      height: 40,
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: const BorderSide(width: 1, color: Colors.white)),
          onPressed: () {
            ZEGOSDKManager.instance.zimService
                .cancelRoomRequest(myRoomRequest?.requestID ?? '')
                .then((value) {
              widget.applying?.value = false;
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Cancel the application failed: $error')));
            });
          },
          child: const Text(
            'Cancel the application',
            style: TextStyle(color: Colors.white),
          )),
    );
  }

  Widget endCohostButton() {
    return SizedBox(
      width: 120,
      height: 40,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
            side: const BorderSide(width: 1, color: Colors.white)),
        onPressed: () {
          ZegoLiveStreamingManager.instance.endCoHost();
        },
        child: const Text('End co-host', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
