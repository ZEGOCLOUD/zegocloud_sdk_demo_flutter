import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../internal/business/call/call_data.dart';
import '../zego_call_manager.dart';
import '../zego_sdk_manager.dart';
import 'audio_room/audio_room_page.dart';
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
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
          actions: [
            ValueListenableBuilder(
              valueListenable: ZEGOSDKManager().currentUser!.avatarUrlNotifier,
              builder: (BuildContext context, String? avatarUrl, Widget? child) {
                return avatarUrl?.isNotEmpty ?? false
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, _) => const CupertinoActivityIndicator(),
                        errorWidget: (context, url, error) => const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink();
              },
            ),
            Text('ID:${ZEGOSDKManager().currentUser!.userID}'),
            const SizedBox(width: 10),
          ],
        ),
        body: const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: CustomScrollView(slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Divider(),
                  CallEntry(),
                  Divider(),
                  LiveStreamingEntry(),
                  Divider(),
                  AudioRoomEntry(),
                  Divider(),
                ],
              ),
            ),
          ]),
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
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('Call Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        callInviteeTextField(),
        const SizedBox(height: 20),
        startCallButton(),
        const SizedBox(height: 30),
      ],
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
            child: ElevatedButton(onPressed: () => startCall(ZegoCallType.voice), child: const Text('voice call')),
          ),
          const Expanded(flex: 1, child: SizedBox(width: 20)),
          Expanded(
            flex: 3,
            child: ElevatedButton(onPressed: () => startCall(ZegoCallType.video), child: const Text('video call')),
          )
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
      if (ZegoCallManager().callData!.inviter.userID != ZEGOSDKManager().currentUser!.userID) {
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
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('LiveStreaming Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        const SizedBox(height: 10),
        roomIDTextField(roomIDController),
        const SizedBox(height: 20),
        hostJoinLivePageButton(ZegoLiveStreamingRole.host),
        const SizedBox(height: 20),
        hostJoinLivePageButton(ZegoLiveStreamingRole.audience),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget hostJoinLivePageButton(ZegoLiveStreamingRole role) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ZegoLivePage(roomID: roomIDController.text, role: ZegoLiveStreamingRole.host),
            ),
          );
        },
        child: role == ZegoLiveStreamingRole.host
            ? const Text('Start a Live Streaming')
            : const Text('Watch a Live Streaming'),
      ),
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
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('LiveAudioRoom Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        roomIDTextField(roomIDController),
        const SizedBox(height: 20),
        liveAudioRoomButton(ZegoLiveAudioRoomRole.host),
        const SizedBox(height: 20),
        liveAudioRoomButton(ZegoLiveAudioRoomRole.audience),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget liveAudioRoomButton(ZegoLiveAudioRoomRole role) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AudioRoomPage(roomID: roomIDController.text, role: role)),
        ),
        child: role == ZegoLiveAudioRoomRole.host ? const Text('Start a Audio Room') : const Text('Watch a Audio Room'),
      ),
    );
  }
}

Widget roomIDTextField(TextEditingController controller) {
  return SizedBox(
    width: 350,
    child: Row(
      children: [
        const Text('RoomID:'),
        const SizedBox(width: 10, height: 20),
        Flexible(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Please Input RoomID'),
          ),
        ),
      ],
    ),
  );
}
