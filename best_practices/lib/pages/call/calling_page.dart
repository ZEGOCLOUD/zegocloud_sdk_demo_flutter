import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/call/add_user_button.dart';
import '../../components/call/zego_cancel_button.dart';
import '../../components/common/zego_speaker_button.dart';
import '../../components/common/zego_switch_camera_button.dart';
import '../../components/common/zego_toggle_camera_button.dart';
import '../../components/common/zego_toggle_microphone_button.dart';
import '../../internal/business/call/call_data.dart';
import '../../utils/zegocloud_token.dart';
import '../../zego_call_manager.dart';
import '../../zego_sdk_key_center.dart';
import '../../zego_sdk_manager.dart';
import 'call_container.dart';

class CallingPage extends StatefulWidget {
  const CallingPage({required this.callData, super.key});

  final ZegoCallData callData;

  @override
  State<CallingPage> createState() => _CallingPageState();
}

class _CallingPageState extends State<CallingPage> {
  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<String> streamIDList = [];

  @override
  void initState() {
    super.initState();

    subscriptions
        .addAll([ZEGOSDKManager().expressService.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate)]);

    String? token;
    if (kIsWeb) {
      // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
      // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
      token = ZegoTokenUtils.generateToken(
          SDKKeyCenter.appID, SDKKeyCenter.serverSecret, ZEGOSDKManager().currentUser!.userID);
    }
    final roomID = widget.callData.callID;
    ZEGOSDKManager()
        .loginRoom(roomID,
            widget.callData.callType == VOICE_Call ? ZegoScenario.StandardVoiceCall : ZegoScenario.StandardVideoCall,
            token: token)
        .then((value) {
      if (value.errorCode == 0) {
        ZEGOSDKManager().expressService.turnMicrophoneOn(true);
        ZEGOSDKManager().expressService.setAudioRouteToSpeaker(true);
        if (widget.callData.callType == VOICE_Call) {
          ZEGOSDKManager().expressService.turnCameraOn(false);
        } else {
          ZEGOSDKManager().expressService.turnCameraOn(true);
          ZEGOSDKManager().expressService.startPreview();
        }
        ZEGOSDKManager().expressService.startPublishingStream(ZegoCallManager().getMainStreamID());
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
    ZegoCallManager().quitCall();
    streamIDList.forEach(ZEGOSDKManager().expressService.stopPlayingStream);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const CallContainer(),
            bottomBar(),
          ],
        ),
      ),
    );
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
    if (widget.callData.callType == VOICE_Call) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [toggleMicButton(), endCallButton(), speakerButton(), inviteUserButton()],
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
          inviteUserButton()
        ],
      );
    }
  }

  Widget backgroundImage() {
    return Image.asset(
      'assets/icons/bg.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
    );
  }

  Widget endCallButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: ZegoCancelButton(
        onPressed: () {
          ZegoCallManager().quitCall();
        },
      ),
    );
  }

  Widget toggleMicButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoToggleMicrophoneButton(),
    );
  }

  Widget toggleCameraButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoToggleCameraButton(),
    );
  }

  Widget switchCameraButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoSwitchCameraButton(),
    );
  }

  Widget speakerButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoSpeakerButton(),
    );
  }

  Widget inviteUserButton() {
    return const SizedBox(
      width: 50,
      height: 50,
      child: ZegoCallAddUserButton(),
    );
  }

  void onStreamListUpdate(ZegoRoomStreamListUpdateEvent event) {
    for (final stream in event.streamList) {
      if (event.updateType == ZegoUpdateType.Add) {
        streamIDList.add(stream.streamID);
        ZEGOSDKManager().expressService.startPlayingStream(stream.streamID);
      } else {
        streamIDList.remove(stream.streamID);
        ZEGOSDKManager().expressService.stopPlayingStream(stream.streamID);
      }
    }
  }
}
