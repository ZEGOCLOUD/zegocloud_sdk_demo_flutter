import 'dart:async';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../zego_sdk_key_center.dart';
import '../../zego_sdk_manager.dart';
import '../components/common/zego_speaker_button.dart';
import '../components/common/zego_toggle_microphone_button.dart';
import '../main.dart';
import 'service/mini_game_api.dart';
import 'ui/show_game_list_view.dart';
import 'your_game_server.dart';

part 'game_page_controller.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({Key? key}) : super(key: key);

  @override
  State<MiniGamePage> createState() => MiniGamePageState();
}

class MiniGamePageState extends State<MiniGamePage> {
  late final DemoGameController demoGameController = DemoGameController(
    userID: ZEGOSDKManager().currentUser!.userID,
    userName: ZEGOSDKManager().currentUser!.userName,
  );

  List<StreamSubscription<dynamic>?> subscriptions = [];
  List<String> streamIDList = [];
  ValueNotifier<bool> rtcRoomConnected = ValueNotifier(false);
  ValueNotifier<bool> matching = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Due to the limitations of inappWebView, you must init demoGameController in this PostFrameCallback
      demoGameController.init();
      ZegoMiniGame().loadedStateNotifier.addListener(onloadedStateUpdated);
    });
    final expressService = ZEGOSDKManager().expressService;
    subscriptions.addAll([
      expressService.streamListUpdateStreamCtrl.stream.listen(onStreamListUpdate),
      expressService.roomStateChangedStreamCtrl.stream.listen(onExpressRoomStateChanged),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
    logoutRTCRoom();
    super.dispose();
  }

  void onloadedStateUpdated() {
    if (!ZegoMiniGame().loadedStateNotifier.value && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there is a compilation error about PopScope here, please try upgrading the Flutter version."
    return PopScope(
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          ZegoMiniGame().loadedStateNotifier.removeListener(onloadedStateUpdated);
          // Due to the limitations of inappWebView, you must uninit demoGameController in this onPopInvoked callback.
          await demoGameController.uninit();
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('ZegoMiniGame')),
          body: ValueListenableBuilder(
              valueListenable: ZegoMiniGame().loadedStateNotifier,
              builder: (context, gameLoaded, _) {
                return ValueListenableBuilder(
                    valueListenable: rtcRoomConnected,
                    builder: (context, rtcRoomConnected, _) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          demoGameController.gameView(),
                          if (gameLoaded)
                            Positioned(bottom: 0, right: 0, child: quitGameButton())
                          else
                            Positioned(bottom: 200, right: 0, left: 0, child: Center(child: startMatchButton())),
                          if (rtcRoomConnected) Positioned(bottom: 50, right: 10, child: microphoneButton()),
                          if (rtcRoomConnected) Positioned(bottom: 50, right: 70, child: speakerButton()),
                        ],
                      );
                    });
              }),
        ),
      ),
    );
  }

  Widget microphoneButton() => const SizedBox(width: 50, height: 50, child: ZegoToggleMicrophoneButton());
  Widget speakerButton() => const SizedBox(width: 50, height: 50, child: ZegoSpeakerButton());
  Widget quitGameButton() {
    return ValueListenableBuilder(
      valueListenable: ZegoMiniGame().loadedStateNotifier,
      builder: (context, bool loaded, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (loaded) ElevatedButton(onPressed: demoGameController.unloadGame, child: const Text('Quit')),
          ],
        );
      },
    );
  }

  Widget startMatchButton() {
    return ValueListenableBuilder(
      valueListenable: matching,
      builder: (BuildContext context, bool matching, Widget? child) {
        return ElevatedButton(
          onPressed: matching ? null : startMatch,
          child: matching ? const CupertinoActivityIndicator() : const Text('Start Match'),
        );
      },
    );
  }

  Future<void> startMatch() async {
    // 1. load game
    final selectedGame = await showGameListView(context);
    if (selectedGame == null) return;
    final gameID = selectedGame.miniGameId!;
    debugPrint('loadGame: $gameID');

    // 2.  match
    matching.value = true;
    final matchResult = await fakeMatchData(gameID);
    matching.value = false;

    // 3. loadGame
    await demoGameController.loadGame(gameID: gameID, roomID: matchResult.roomID);

    // 4. startGame
    // Need to specify a user to call start game, here we choose the first user from the matching results."
    if (matchResult.userIDs.first == ZEGOSDKManager().currentUser!.userID) {
      demoGameController.startGame(matchResult.userIDs);
    }

    // 5. login rtc room
    loginRTCRoom(matchResult.roomID);
  }

  void loginRTCRoom(String roomID) {
    ZEGOSDKManager().loginRoom(roomID, ZegoScenario.HighQualityChatroom).then((value) {
      if (value.errorCode == 0) {
        ZEGOSDKManager().expressService
          ..setAudioDeviceMode(ZegoAudioDeviceMode.Communication3)
          ..turnCameraOn(false)
          ..turnMicrophoneOn(true)
          ..setAudioRouteToSpeaker(true)
          ..startPublishingStream('${roomID}_${ZEGOSDKManager().currentUser!.userID}_main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('join room fail: ${value.errorCode},${value.extendedData}')),
        );
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  void logoutRTCRoom() {
    ZEGOSDKManager().logoutRoom();
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

  void onExpressRoomStateChanged(ZegoRoomStateEvent event) {
    if (event.reason == ZegoRoomStateChangedReason.Logined || event.reason == ZegoRoomStateChangedReason.Reconnected) {
      rtcRoomConnected.value = true;
    } else {
      rtcRoomConnected.value = false;
    }
    debugPrint('GamePage:onExpressRoomStateChanged: $event');
    if (event.errorCode != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text('onExpressRoomStateChanged: reason:${event.reason.name}, errorCode:${event.errorCode}'),
        ),
      );
    }

    if ((event.reason == ZegoRoomStateChangedReason.KickOut) ||
        (event.reason == ZegoRoomStateChangedReason.ReconnectFailed) ||
        (event.reason == ZegoRoomStateChangedReason.LoginFailed)) {
      Navigator.pop(context);
    }
  }
}

Future<MatchResult> fakeMatchData(String gameID) async {
  await Future.delayed(const Duration(seconds: 2));
  return MatchResult(
    roomID: Random().nextInt(9999999).toString(),
    // In the demo, it is always playing games with the robot.
    // When you integrate, you need to specify the ID of all players here.
    userIDs: [ZEGOSDKManager().currentUser!.userID],
  );
}

class MatchResult {
  String roomID;
  List<String> userIDs;

  MatchResult({required this.roomID, required this.userIDs});
}
