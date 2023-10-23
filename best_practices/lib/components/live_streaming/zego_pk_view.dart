import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../zego_live_streaming_manager.dart';
import '../../zego_sdk_manager.dart';
import '../common/zego_audio_video_view.dart';

class ZegoPKBattleView extends StatefulWidget {
  const ZegoPKBattleView({super.key});

  @override
  State<ZegoPKBattleView> createState() => _ZegoPKBattleViewState();
}

class _ZegoPKBattleViewState extends State<ZegoPKBattleView> {
  List<StreamSubscription<dynamic>> subscriptions = [];

  Timer? heartBeatTimer;
  Map<String, DateTime> heartBeatMap = {};
  Map<String, bool> cameraStateMap = {};

  List<ZegoSDKUser?> get hosts => [leftUser, rightUser];

  ValueNotifier<bool> leftUserHeartBeatBrokenNotifier =
      ValueNotifier<bool>(false);
  ValueNotifier<bool> rightUserHeartBeatBrokenNotifier =
      ValueNotifier<bool>(false);

  ValueNotifier<bool> leftUserCameraStateNotifier = ValueNotifier(false);
  ValueNotifier<bool> rightUserCameraStateNotifier = ValueNotifier(false);

  ZegoSDKUser? get leftUser => ZegoLiveStreamingManager().isLocalUserHost()
      ? ZEGOSDKManager().currentUser
      : ZegoLiveStreamingManager().hostNoti.value;
  ZegoSDKUser? get rightUser => ZegoLiveStreamingManager().pkUser;
  bool isHeartBeatBrokenMuteAudio = false;

  final pkManager = ZegoLiveStreamingManager();

  @override
  void dispose() {
    heartBeatTimer?.cancel();
    for (final sub in subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    subscriptions.addAll([
      ZEGOSDKManager()
          .expressService
          .recvSEICtrl
          .stream
          .listen(onReceiveSEIEvent),
    ]);

    if (!ZegoLiveStreamingManager().isLocalUserHost() && leftUser != null) {
      heartBeatMap[leftUser!.userID] = DateTime.now();
    }
    if (rightUser != null) {
      heartBeatMap[rightUser!.userID] = DateTime.now();
    }

    heartBeatTimer =
        Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) return;
      cameraStateMap.forEach((key, value) {
        if (key == pkManager.pkUser?.userID) {
          rightUserCameraStateNotifier.value = value;
        } else {
          leftUserCameraStateNotifier.value = value;
        }
      });
      final now = DateTime.now();
      final needDeleteIDs = <String>[];
      heartBeatMap.forEach((id, timestamp) {
        if (now.difference(timestamp).inSeconds > 5) {
          if (id == (leftUser?.userID ?? '')) {
            leftUserHeartBeatBrokenNotifier.value = true;
          } else if (id == (rightUser?.userID ?? '')) {
            rightUserHeartBeatBrokenNotifier.value = true;
            if (pkManager.isLocalUserHost() &&
                !pkManager.isMuteAnotherAudioNoti.value) {
              isHeartBeatBrokenMuteAudio = true;
              pkManager.muteAnotherHostAudio(isHeartBeatBrokenMuteAudio);
            }
          }
          needDeleteIDs.add(id);
        } else {
          if (id == (rightUser?.userID ?? '')) {
            if (pkManager.isLocalUserHost() && isHeartBeatBrokenMuteAudio) {
              isHeartBeatBrokenMuteAudio = false;
              pkManager.muteAnotherHostAudio(isHeartBeatBrokenMuteAudio);
            }
          }
        }
      });
      needDeleteIDs.forEach(heartBeatMap.remove);
    });
  }

  void onReceiveSEIEvent(ZegoRecvSEIEvent event) {
    final jsonString = String.fromCharCodes(event.data);
    final Map<String, dynamic> seiMap = json.decode(jsonString);
    final String senderID = seiMap['sender_id'];
    cameraStateMap[senderID] = seiMap['cam'];
    heartBeatMap[senderID] = DateTime.now();
    debugPrint('****sei sendID:$senderID');
    if (senderID == (leftUser?.userID ?? '')) {
      leftUserHeartBeatBrokenNotifier.value = false;
      leftUser?.isCamerOnNotifier.value = seiMap['cam'];
    } else if (senderID == (rightUser?.userID ?? '')) {
      rightUserHeartBeatBrokenNotifier.value = false;
      rightUser?.isCamerOnNotifier.value = seiMap['cam'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return hostsView();
  }

  Widget hostsView() {
    final audioVideoViews = Builder(builder: (context) {
      if (ZegoLiveStreamingManager().isLocalUserHost()) {
        return Row(
          children: [
            Expanded(
                child: ZegoAudioVideoView(
                    userInfo: ZEGOSDKManager().currentUser!)),
            Expanded(child: Builder(builder: (context) {
              return ValueListenableBuilder(
                  valueListenable: rightUserHeartBeatBrokenNotifier,
                  builder: (context, bool heartBeatBroken, _) {
                    if (heartBeatBroken) {
                      return hostReconnecting(left: false);
                    } else {
                      return Stack(
                        children: [
                          ZegoAudioVideoView(
                              userInfo: ZegoLiveStreamingManager().pkUser!),
                          muteAnotherHostAudioButton(),
                        ],
                      );
                    }
                  });
            })),
          ],
        );
      } else {
        return audienceView();
      }
    });

    return audioVideoViews;
  }

  Widget hostReconnecting({required bool left}) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Host is reconnecting…',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget videoView() {
    return ValueListenableBuilder(
        valueListenable: ZegoLiveStreamingManager().hostNoti,
        builder: (context, ZegoSDKUser? leftuser, _) {
          return ValueListenableBuilder(
              valueListenable: leftUserCameraStateNotifier,
              builder: (context, bool leftCameraState, _) {
                return ValueListenableBuilder(
                    valueListenable: rightUserCameraStateNotifier,
                    builder: (context, bool rightCameraState, _) {
                      return ValueListenableBuilder(
                          valueListenable: ZEGOSDKManager()
                              .expressService
                              .mixerStreamNotifier,
                          builder: (context, Widget? mixerView, _) {
                            if (mixerView == null) {
                              return const SizedBox.shrink();
                            }
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black
                                        .withOpacity(leftCameraState ? 1 : 0),
                                    Colors.black
                                        .withOpacity(leftCameraState ? 1 : 0),
                                    Colors.black
                                        .withOpacity(rightCameraState ? 1 : 0),
                                    Colors.black
                                        .withOpacity(rightCameraState ? 1 : 0),
                                  ],
                                  stops: const [0, 0.5, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: mixerView,
                            );
                          });
                    });
              });
        });
  }

  Widget audienceView() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(child: background(left: true)),
            Expanded(child: background(left: false)),
          ],
        ),
        Row(
          children: [
            Expanded(child: videoView()),
          ],
        ),
        Row(
          children: [
            Expanded(child: foreground(left: true)),
            Expanded(child: foreground(left: false)),
          ],
        ),
      ],
    );
  }

  Widget background({required bool left}) {
    final user = left ? leftUser : rightUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(color: Colors.transparent),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                  border: Border.all(width: 0),
                ),
                child: Center(
                  child: SizedBox(
                      height: 20,
                      child: Text(
                        user!.userName[0],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      )),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget foreground({required bool left}) {
    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: left
              ? leftUserHeartBeatBrokenNotifier
              : rightUserHeartBeatBrokenNotifier,
          builder: (context, bool heartBeatBroken, _) {
            if (heartBeatBroken) {
              return hostReconnecting(left: left);
            } else {
              return Container(color: Colors.transparent);
            }
          },
        ),
      ],
    );
  }

  Widget muteAnotherHostAudioButton() {
    return Positioned(
        top: 20,
        right: 10,
        child: SizedBox(
          width: 60,
          height: 60,
          child: muteAudioImage(),
        ));
  }

  Widget muteAudioImage() {
    return ValueListenableBuilder(
        valueListenable: pkManager.isMuteAnotherAudioNoti,
        builder: (context, bool isMute, _) {
          final imagePath = isMute
              ? 'assets/icons/icon_speaker_off.png'
              : 'assets/icons/icon_speaker_normal.png';
          return IconButton(
              onPressed: () {
                pkManager.muteAnotherHostAudio(!isMute);
              },
              icon: Image(image: AssetImage(imagePath)));
        });
  }
}
