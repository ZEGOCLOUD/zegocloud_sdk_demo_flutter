import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../internal/business/call/call_data.dart';
import '../live_audio_room_manager.dart';
import '../utils/zegocloud_token.dart';
import '../zego_call_manager.dart';
import '../zego_sdk_key_center.dart';
import '../zego_sdk_manager.dart';
import 'audio_room/audio_room_page.dart';
import '../internal/business/audioRoom/layout_config.dart';
import 'call/calling_page.dart';
import 'call/waiting_page.dart';
import 'live_streaming/live_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Padding(
        padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
        child: Column(
          children: const [
            CallEntry(),
            LiveStreamingEntry(),
            AudioRoomEntry(),
          ],
        ),
      ),
    );
  }
}

class CallEntry extends StatefulWidget {
  const CallEntry({super.key});

  @override
  State<CallEntry> createState() => _CallEntryState();
}

class _CallEntryState extends State<CallEntry> {
  final inviteeIDController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          callInviteeTextField(),
          const SizedBox(height: 20),
          startCallButton(),
        ],
      ),
    );
  }

  Widget callInviteeTextField() {
    return SizedBox(
      width: 350,
      child: Row(
        children: [
          const Text('inviteeID:'),
          const SizedBox(width: 10, height: 20),
          Flexible(
            child: TextField(
              controller: inviteeIDController,
              decoration: const InputDecoration(
                labelText: 'input invitee userID',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget startCallButton() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: ElevatedButton(
                  onPressed: () {
                    startCall(ZegoCallType.voice);
                  },
                  child: const Text('voice call'))),
          const Expanded(
              flex: 1,
              child: SizedBox(
                width: 20,
              )),
          Expanded(
              flex: 3,
              child: ElevatedButton(
                  onPressed: () {
                    startCall(ZegoCallType.video);
                  },
                  child: const Text('video call')))
        ],
      ),
    );
  }

  Future<void> startCall(ZegoCallType callType) async {
    if (callType == ZegoCallType.video) {
      ZegoCallManager().sendVideoCall(inviteeIDController.text).then((value) {
        final errorInvitees = value.info.errorInvitees.map((e) => e.userID).toList();
        if (errorInvitees.contains(inviteeIDController.text)) {
          ZegoCallManager.instance.clearCallData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('user is not online: $value')),
          );
        } else {
          pushToCallWaitingPage();
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send call invitation failed: $error')),
        );
      });
    } else {
      ZegoCallManager().sendVoiceCall(inviteeIDController.text).then((value) {
        final errorInvitees = value.info.errorInvitees.map((e) => e.userID).toList();
        if (errorInvitees.contains(inviteeIDController.text)) {
          ZegoCallManager.instance.clearCallData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('user is not online: $value')),
          );
        } else {
          pushToCallWaitingPage();
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send call invitation failed: $error')),
        );
      });
    }
  }

  void pushToCallWaitingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CallWaitingPage(callData: ZegoCallManager().callData!),
      ),
    );
  }

  void pushToCallingPage() {
    if (ZegoCallManager().callData != null) {
      ZegoSDKUser otherUser;
      if (ZegoCallManager().callData!.inviter.userID != ZEGOSDKManager().currentUser?.userID) {
        otherUser = ZegoCallManager().callData!.inviter;
      } else {
        otherUser = ZegoCallManager().callData!.invitee;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CallingPage(callData: ZegoCallManager().callData!, otherUserInfo: otherUser),
        ),
      );
    }
  }
}

class LiveStreamingEntry extends StatefulWidget {
  const LiveStreamingEntry({super.key});

  @override
  State<LiveStreamingEntry> createState() => _LiveStreamingEntryState();
}

class _LiveStreamingEntryState extends State<LiveStreamingEntry> {
  final roomIDController = TextEditingController(text: Random().nextInt(9999999).toString());
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          roomIDTextField(),
          const SizedBox(height: 20),
          hostJoinLivePageButton(),
          const SizedBox(height: 20),
          audienceJoinLivePageButton(),
        ],
      ),
    );
  }

  Widget roomIDTextField() {
    return SizedBox(
      width: 350,
      child: Row(
        children: [
          const Text('RoomID:'),
          const SizedBox(width: 10, height: 20),
          Flexible(
            child: TextField(
              controller: roomIDController,
              decoration: const InputDecoration(
                labelText: 'please input roomID',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget hostJoinLivePageButton() {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ZegoLivePage(roomID: roomIDController.text, role: ZegoLiveRole.host),
            ),
          );
        },
        child: const Text('Start a Live Streaming'),
      ),
    );
  }

  Widget audienceJoinLivePageButton() {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ZegoLivePage(roomID: roomIDController.text, role: ZegoLiveRole.audience),
              ),
            );
          },
          child: const Text('Watch a Live Streaming')),
    );
  }
}

class AudioRoomEntry extends StatefulWidget {
  const AudioRoomEntry({super.key});

  @override
  State<AudioRoomEntry> createState() => _AudioRoomEntryState();
}

class _AudioRoomEntryState extends State<AudioRoomEntry> {
  final roomIDController = TextEditingController(text: Random().nextInt(9999999).toString());
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          roomIDTextField(),
          const SizedBox(height: 20),
          hostJoinLiveAudioRoomButton(),
          const SizedBox(height: 20),
          audienceJoinLiveAudioRoomButton(),
        ],
      ),
    );
  }

  Widget roomIDTextField() {
    return SizedBox(
      width: 350,
      child: Row(
        children: [
          const Text('RoomID:'),
          const SizedBox(width: 10, height: 20),
          Flexible(
            child: TextField(
              controller: roomIDController,
              decoration: const InputDecoration(
                labelText: 'please input roomID',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget hostJoinLiveAudioRoomButton() {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: hostPress,
        child: const Text('Start a Audio Room'),
      ),
    );
  }

  void hostPress() {
    // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
    // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
    final token = kIsWeb
        ? ZegoTokenUtils.generateToken(
            SDKKeyCenter.appID, SDKKeyCenter.serverSecret, ZEGOSDKManager.instance.currentUser!.userID)
        : null;
    ZegoLiveAudioRoomManager.instance.initWithConfig(ZegoLiveAudioRoomLayoutConfig(), ZegoLiveRole.host);
    ZEGOSDKManager.instance.loginRoom(roomIDController.text, ZegoScenario.HighQualityChatroom, token: token).then((value) {
      if (value.errorCode == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioRoomPage(
              roomID: roomIDController.text,
              role: ZegoLiveRole.host,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
      }
    });
  }

  Widget audienceJoinLiveAudioRoomButton() {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: audiencePress,
        child: const Text('Join a Audio Room'),
      ),
    );
  }

  void audiencePress() {
    // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
    // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
    final token = kIsWeb
        ? ZegoTokenUtils.generateToken(
            SDKKeyCenter.appID, SDKKeyCenter.serverSecret, ZEGOSDKManager.instance.currentUser!.userID)
        : null;
    ZegoLiveAudioRoomManager.instance.initWithConfig(ZegoLiveAudioRoomLayoutConfig(), ZegoLiveRole.audience);
    ZEGOSDKManager.instance.loginRoom(roomIDController.text, ZegoScenario.HighQualityChatroom,token: token).then((value) {
      if (value.errorCode == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioRoomPage(
              roomID: roomIDController.text,
              role: ZegoLiveRole.audience,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login room failed: ${value.errorCode}')));
      }
    });
  }
}
