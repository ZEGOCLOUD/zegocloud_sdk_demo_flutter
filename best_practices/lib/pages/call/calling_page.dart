import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/call/zego_cancel_button.dart';
import '../../components/call/zego_speaker_button.dart';
import '../../components/call/zego_switch_camera_button.dart';
import '../../components/call/zego_toggle_camera_button.dart';
import '../../components/call/zego_toggle_microphone_button.dart';
import '../../components/common/zego_audio_video_view.dart';
import '../../internal/business/call/call_data.dart';
import '../../utils/zegocloud_token.dart';
import '../../zego_call_manager.dart';
import '../../zego_sdk_manager.dart';
import '../../zego_sdk_key_center.dart';

class CallingPage extends StatefulWidget {
  const CallingPage({required this.callData, required this.otherUserInfo, super.key});

  final ZegoCallData callData;
  final ZegoSDKUser otherUserInfo;

  @override
  State<CallingPage> createState() => _CallingPageState();
}

class _CallingPageState extends State<CallingPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<String> streamIDList = [];

  bool micIsOn = true;
  bool cameraIsOn = true;
  bool isFacingCamera = true;
  bool isSpeaker = true;

  ValueNotifier<ZegoSDKUser?> otherUserInfoNoti = ValueNotifier(null);

  @override
  void initState() {
    super.initState();

    subscriptions.addAll(
        [ZEGOSDKManager.instance.expressService.roomUserListUpdateStreamCtrl.stream.listen(onRoomUserListUpdate)]);

    String? token;
    if (kIsWeb) {
      // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
      // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
      token = ZegoTokenUtils.generateToken(
          SDKKeyCenter.appID, SDKKeyCenter.serverSecret, ZEGOSDKManager().currentUser?.userID ?? '');
    }
    final roomID = widget.callData.callID;
    ZEGOSDKManager.instance
        .loginRoom(
            roomID,
            widget.callData.callType == ZegoCallType.voice
                ? ZegoScenario.StandardVoiceCall
                : ZegoScenario.StandardVideoCall,
            token: token)
        .then((value) {
      if (value.errorCode == 0) {
        ZEGOSDKManager.instance.expressService.turnMicrophoneOn(micIsOn);
        ZEGOSDKManager.instance.expressService.setAudioRouteToSpeaker(isSpeaker);
        if (widget.callData.callType == ZegoCallType.voice) {
          cameraIsOn = false;
          ZEGOSDKManager.instance.expressService.turnCameraOn(cameraIsOn);
        } else {
          ZEGOSDKManager.instance.expressService.turnCameraOn(cameraIsOn);
          ZEGOSDKManager.instance.expressService.startPreview();
        }
        ZEGOSDKManager.instance.expressService.startPublishingStream(ZegoCallManager().getMainStreamID());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('join room fail: ${value.errorCode},${value.extendedData}')),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
    ZegoCallManager().clearCallData();
    for (String streamID in streamIDList) {
      ZEGOSDKManager.instance.expressService.stopPlayingStream(streamID);
    }
    ZEGOSDKManager.instance.expressService.stopPreview();
    ZEGOSDKManager.instance.expressService.stopPublishingStream();
    ZEGOSDKManager.instance.expressService.logoutRoom(widget.callData.callID);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Stack(
        children: [
          largetVideoView(),
          smallVideoView(),
          bottomBar(),
        ],
      ),
    ));
  }

  Widget largetVideoView() {
    return ValueListenableBuilder<ZegoSDKUser?>(
        valueListenable: otherUserInfoNoti,
        builder: (context, userInfo, _) {
          if (userInfo != null) {
            return Container(
              padding: EdgeInsets.zero,
              color: Colors.black,
              child: ZegoAudioVideoView(userInfo: userInfo),
            );
          } else {
            return Container(
              padding: EdgeInsets.zero,
              color: Colors.black,
            );
          }
        });
  }

  Widget smallVideoView() {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        margin: EdgeInsets.only(top: 100, left: constraints.maxWidth - 95.0 - 20),
        width: 95.0,
        height: 164.0,
        child: ZegoAudioVideoView(userInfo: ZEGOSDKManager().currentUser!),
      );
    });
  }

  Widget bottomBar() {
    return LayoutBuilder(builder: (context, containers) {
      return Padding(
        padding: EdgeInsets.only(left: 0, right: 0, top: containers.maxHeight - 70),
        child: buttonView(),
      );
    });
  }

  Widget buttonView() {
    if (widget.callData.callType == ZegoCallType.voice) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          endCallButton(),
          speakerButton(),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          endCallButton(),
          speakerButton(),
          switchCameraButton(),
        ],
      );
    }
  }

  Widget endCallButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoCancelButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  Widget toggleMicButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleMicrophoneButton(
          onPressed: () {
            micIsOn = !micIsOn;
            ZEGOSDKManager.instance.expressService.turnMicrophoneOn(micIsOn);
          },
        ),
      );
    });
  }

  Widget toggleCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleCameraButton(
          onPressed: () {
            cameraIsOn = !cameraIsOn;
            ZEGOSDKManager.instance.expressService.turnCameraOn(cameraIsOn);
          },
        ),
      );
    });
  }

  Widget switchCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoSwitchCameraButton(
          onPressed: () {
            isFacingCamera = !isFacingCamera;
            ZEGOSDKManager.instance.expressService.useFrontCamera(isFacingCamera);
          },
        ),
      );
    });
  }

  Widget speakerButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return SizedBox(
        width: 50,
        height: 50,
        child: ZegoSpeakerButton(
          onPressed: () {
            isSpeaker = !isSpeaker;
            ZEGOSDKManager.instance.expressService.setAudioRouteToSpeaker(isSpeaker);
          },
        ),
      );
    });
  }

  // void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
  //   for (var stream in event.streamList) {
  //     if (event.updateType == ZegoUpdateType.Add) {
  //       streamIDList.add(stream.streamID);
  //       ZEGOSDKManager.instance.expressService.startPlayingStream(stream.streamID);
  //     } else {
  //       streamIDList.remove(stream.streamID);
  //       ZEGOSDKManager.instance.expressService.stopPlayingStream(stream.streamID);
  //     }
  //   }
  // }

  void onRoomUserListUpdate(ZegoRoomUserListUpdateEvent event) {
    for (var user in event.userList) {
      if (event.updateType == ZegoUpdateType.Delete) {
        if (user.userID == widget.otherUserInfo.userID) {
          otherUserInfoNoti.value = null;
          Navigator.pop(context);
        }
      } else {
        if (widget.otherUserInfo.userID == user.userID) {
          otherUserInfoNoti.value = ZEGOSDKManager().getUser(user.userID);
        }
      }
    }
  }
}
