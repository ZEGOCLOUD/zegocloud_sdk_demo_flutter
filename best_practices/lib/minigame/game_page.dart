import 'dart:async';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

import '../../zego_sdk_key_center.dart';
import '../../zego_sdk_manager.dart';
import '../main.dart';
import 'service/mini_game_api.dart';
import 'ui/show_game_list_view.dart';
import 'your_game_server.dart';

part 'game_page_controller.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({Key? key, required this.roomID}) : super(key: key);

  final String roomID;

  @override
  State<MiniGamePage> createState() => MiniGamePageState();
}

class MiniGamePageState extends State<MiniGamePage> {
  late final DemoGameController demoGameController = DemoGameController(
    userID: ZEGOSDKManager().currentUser!.userID,
    userName: ZEGOSDKManager().currentUser!.userName,
    roomID: widget.roomID,
  );

  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<String> streamIDList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      demoGameController.init(); // you need uninit demoGameController in the PopScope block
      ZegoMiniGame().loadedStateNotifier.addListener(onloadedStateUpdated);
    });

    subscriptions.add(ZEGOSDKManager().expressService.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate));

    loginRoom();
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
    ZEGOSDKManager().logoutRoom();
    super.dispose();
  }

  void onloadedStateUpdated() {
    if (!ZegoMiniGame().loadedStateNotifier.value && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          ZegoMiniGame().loadedStateNotifier.removeListener(onloadedStateUpdated);
          await demoGameController.uninit();
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('ZegoMiniGame')),
          body: Stack(
            fit: StackFit.expand,
            children: [
              demoGameController.gameView(),
              Positioned(
                bottom: 0,
                right: 0,
                child: demoGameController.gameButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void loginRoom() {
    ZEGOSDKManager().loginRoom(widget.roomID, ZegoScenario.HighQualityChatroom).then((value) {
      if (value.errorCode == 0) {
        ZEGOSDKManager().expressService.turnMicrophoneOn(true);
        ZEGOSDKManager().expressService.setAudioRouteToSpeaker(true);
        ZEGOSDKManager().expressService.turnCameraOn(false);
        final streamID = '${widget.roomID}_${ZEGOSDKManager().currentUser!.userID}_main';
        ZEGOSDKManager().expressService.startPublishingStream(streamID);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('join room fail: ${value.errorCode},${value.extendedData}')),
        );
        if (mounted) Navigator.of(context).pop();
      }
    });
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
