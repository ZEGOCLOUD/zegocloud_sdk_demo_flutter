import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/components.dart';
import '../../live_audio_room_manager.dart';
import '../../utils/zegocloud_token.dart';
import '../../zego_sdk_key_center.dart';

part 'audio_room_gift.dart';

class AudioRoomPage extends StatefulWidget {
  const AudioRoomPage({super.key, required this.roomID, required this.role});

  final String roomID;
  final ZegoLiveAudioRoomRole role;

  @override
  State<AudioRoomPage> createState() => AudioRoomPageState();
}

class AudioRoomPageState extends State<AudioRoomPage> {
  List<StreamSubscription> subscriptions = [];
  String? currentRequestID;
  ValueNotifier<bool> isApplyStateNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    final zimService = ZEGOSDKManager().zimService;
    final expressService = ZEGOSDKManager().expressService;
    subscriptions.addAll([
      expressService.roomStateChangedStreamCtrl.stream.listen(
        onExpressRoomStateChanged,
      ),
      zimService.roomStateChangedStreamCtrl.stream.listen(
        onZIMRoomStateChanged,
      ),
      zimService.connectionStateStreamCtrl.stream.listen(
        onZIMConnectionStateChanged,
      ),
      zimService.onInComingRoomRequestStreamCtrl.stream.listen(
        onInComingRoomRequest,
      ),
      zimService.onOutgoingRoomRequestAcceptedStreamCtrl.stream.listen(
        onOutgoingRoomRequestAccepted,
      ),
      zimService.onOutgoingRoomRequestRejectedStreamCtrl.stream.listen(
        onOutgoingRoomRequestRejected,
      ),
    ]);

    loginRoom();

    initGift();
  }

  void loginRoom() {
    // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
    // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
    final token = kIsWeb
        ? ZegoTokenUtils.generateToken(
            SDKKeyCenter.appID,
            SDKKeyCenter.serverSecret,
            ZEGOSDKManager().currentUser!.userID,
          )
        : null;
    ZegoLiveAudioRoomManager()
        .loginRoom(widget.roomID, widget.role, token: token)
        .then((result) {
      if (result.errorCode == 0) {
        hostTakeSeat();
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login room failed: ${result.errorCode}')),
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    uninitGift();
    ZegoLiveAudioRoomManager().logoutRoom();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  Future<void> hostTakeSeat() async {
    if (widget.role == ZegoLiveAudioRoomRole.host) {
      //take seat
      await ZegoLiveAudioRoomManager().setSelfHost();
      await ZegoLiveAudioRoomManager()
          .takeSeat(0, isForce: true)
          .then((result) {
        if (mounted &&
            ((result == null) ||
                result.errorKeys
                    .contains(ZEGOSDKManager().currentUser!.userID))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('take seat failed: $result')),
          );
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('take seat failed: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: Stack(
          children: [
            backgroundImage(),
            Positioned(top: 60, left: 10, child: roomTitle()),
            Positioned(top: 30, right: 20, child: leaveButton()),
            Positioned(top: 150, child: seatListView()),
            Positioned(bottom: 20, left: 0, right: 0, child: bottomView()),
            giftForeground()
          ],
        ),
      ),
    );
  }

  Widget backgroundImage() {
    return Image.asset(
      'assets/images/audio_bg.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fill,
    );
  }

  Widget roomTitle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LiveAudioRoom',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Room ID: ${widget.roomID}'),
            ValueListenableBuilder(
              valueListenable: ZegoLiveAudioRoomManager().hostUserNotifier,
              builder: (
                BuildContext context,
                ZegoSDKUser? host,
                Widget? child,
              ) {
                return host != null
                    ? Text('Host: ${host.userName} (id: ${host.userID})')
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomView() {
    return ValueListenableBuilder<ZegoLiveAudioRoomRole>(
        valueListenable: ZegoLiveAudioRoomManager().roleNotifier,
        builder: (context, currentRole, _) {
          if (currentRole == ZegoLiveAudioRoomRole.host) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                lockSeatButton(),
                const SizedBox(width: 10),
                requestMemberButton(),
                const SizedBox(width: 10),
                microphoneButton(),
                const SizedBox(width: 20),
              ],
            );
          } else if (currentRole == ZegoLiveAudioRoomRole.speaker) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  giftButton(),
                  const SizedBox(width: 10),
                  leaveSeatButton(),
                  const SizedBox(width: 10),
                  microphoneButton(),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  giftButton(),
                  const SizedBox(width: 10),
                  requestTakeSeatButton(),
                ],
              ),
            );
          }
        });
  }

  Widget lockSeatButton() {
    return ElevatedButton(
      onPressed: () => ZegoLiveAudioRoomManager().lockSeat(),
      child: const Icon(Icons.lock),
    );
  }

  Widget requestMemberButton() {
    return ValueListenableBuilder(
      valueListenable: ZEGOSDKManager().zimService.roomRequestMapNoti,
      builder: (context, Map<String, dynamic> requestMap, child) {
        final requestList = requestMap.values.toList();
        return Badge(
          smallSize: 12,
          isLabelVisible: requestList.isNotEmpty,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: () => RoomRequestListView.showBasicModalBottomSheet(context),
        child: const Icon(Icons.link),
      ),
    );
  }

  Widget microphoneButton() {
    return ValueListenableBuilder(
      valueListenable: ZEGOSDKManager().currentUser!.isMicOnNotifier,
      builder: (context, bool micIsOn, child) {
        return ElevatedButton(
          onPressed: () =>
              ZEGOSDKManager().expressService.turnMicrophoneOn(!micIsOn),
          child: micIsOn ? const Icon(Icons.mic) : const Icon(Icons.mic_off),
        );
      },
    );
  }

  Widget requestTakeSeatButton() {
    return ElevatedButton(
      onPressed: () {
        if (!isApplyStateNotifier.value) {
          final senderMap = {
            'room_request_type': RoomRequestType.audienceApplyToBecomeCoHost
          };
          ZEGOSDKManager()
              .zimService
              .sendRoomRequest(
                ZegoLiveAudioRoomManager().hostUserNotifier.value?.userID ?? '',
                jsonEncode(senderMap),
              )
              .then((value) {
            isApplyStateNotifier.value = true;
            currentRequestID = value.requestID;
          });
        } else {
          if (currentRequestID != null) {
            ZEGOSDKManager()
                .zimService
                .cancelRoomRequest(currentRequestID ?? '')
                .then((value) {
              isApplyStateNotifier.value = false;
              currentRequestID = null;
            });
          }
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: isApplyStateNotifier,
        builder: (context, isApply, _) {
          return Text(isApply ? 'Cancel Application' : 'Apply Take Seat');
        },
      ),
    );
  }

  Widget leaveSeatButton() {
    return ElevatedButton(
        onPressed: () {
          for (final element in ZegoLiveAudioRoomManager().seatList) {
            if (element.currentUser.value?.userID ==
                ZEGOSDKManager().currentUser!.userID) {
              ZegoLiveAudioRoomManager()
                  .leaveSeat(element.seatIndex)
                  .then((value) {
                ZegoLiveAudioRoomManager().roleNotifier.value =
                    ZegoLiveAudioRoomRole.audience;
                isApplyStateNotifier.value = false;
                ZEGOSDKManager().expressService.stopPublishingStream();
              });
            }
          }
        },
        child: const Text('Leave Seat'));
  }

  Widget leaveButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.asset('assets/icons/top_close.png'),
      ),
    );
  }

  void takeSeatResult() {}

  Widget seatListView() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 300,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisCount: 4,
        children: [
          ...List.generate(
            ZegoLiveAudioRoomManager().seatList.length,
            (seatIndex) {
              return ZegoSeatItemView(
                seatIndex: seatIndex,
                onPressed: () {
                  onSeatItemViewClicked(seatIndex);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void onSeatItemViewClicked(int seatIndex) {
    final seat = ZegoLiveAudioRoomManager().seatList[seatIndex];
    if (seatIndex == 0) {
      // audience can't take host seat.
      return;
    }

    if (seat.currentUser.value == null) {
      if (ZegoLiveAudioRoomManager().roleNotifier.value ==
          ZegoLiveAudioRoomRole.audience) {
        ZegoLiveAudioRoomManager().takeSeat(seat.seatIndex).then(
          (result) {
            if (mounted &&
                ((result == null) ||
                    result.errorKeys
                        .contains(ZEGOSDKManager().currentUser!.userID))) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('take seat failed: $result')),
              );
            }
          },
        ).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('take seat failed: $error')),
          );
        });
      } else if (ZegoLiveAudioRoomManager().roleNotifier.value ==
          ZegoLiveAudioRoomRole.speaker) {
        if (getLocalUserSeatIndex() != -1) {
          ZegoLiveAudioRoomManager().switchSeat(
            getLocalUserSeatIndex(),
            seat.seatIndex,
          );
        }
      }
    } else {
      if (widget.role == ZegoLiveAudioRoomRole.host &&
          (ZEGOSDKManager().currentUser!.userID !=
              seat.currentUser.value?.userID)) {
        showRemoveSpeakerAndKitOutSheet(context, seat.currentUser.value!);
      }
    }
  }

  void showRemoveSpeakerAndKitOutSheet(
    BuildContext context,
    ZegoSDKUser targetUser,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: const Text('remove speaker', textAlign: TextAlign.center),
              onTap: () {
                Navigator.pop(context);
                ZegoLiveAudioRoomManager().removeSpeakerFromSeat(
                  targetUser.userID,
                );
              },
            ),
            ListTile(
              title: Text(
                  targetUser.isMicOnNotifier.value
                      ? 'mute speaker'
                      : 'unMute speaker',
                  textAlign: TextAlign.center),
              onTap: () {
                Navigator.pop(context);
                ZegoLiveAudioRoomManager().muteSpeaker(
                  targetUser.userID,
                  targetUser.isMicOnNotifier.value,
                );
              },
            ),
            ListTile(
              title: const Text('kick out user', textAlign: TextAlign.center),
              onTap: () {
                Navigator.pop(context);
                ZegoLiveAudioRoomManager().kickOutRoom(targetUser.userID);
              },
            ),
          ],
        );
      },
    );
  }

  int getLocalUserSeatIndex() {
    for (final element in ZegoLiveAudioRoomManager().seatList) {
      if (element.currentUser.value?.userID ==
          ZEGOSDKManager().currentUser!.userID) {
        return element.seatIndex;
      }
    }
    return -1;
  }

  // zim listener
  void onInComingRoomRequest(OnInComingRoomRequestReceivedEvent event) {}

  void onInComingRoomRequestCancelled(
    OnInComingRoomRequestCancelledEvent event,
  ) {}

  void onInComingRoomRequestTimeOut() {}

  void onOutgoingRoomRequestAccepted(OnOutgoingRoomRequestAcceptedEvent event) {
    isApplyStateNotifier.value = false;
    for (final seat in ZegoLiveAudioRoomManager().seatList) {
      if (seat.currentUser.value == null) {
        ZegoLiveAudioRoomManager().takeSeat(seat.seatIndex).then((result) {
          if (mounted &&
              ((result == null) ||
                  result.errorKeys
                      .contains(ZEGOSDKManager().currentUser!.userID))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('take seat failed: $result')),
            );
          }
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('take seat failed: $error')),
          );
        });

        break;
      }
    }
  }

  void onOutgoingRoomRequestRejected(OnOutgoingRoomRequestRejectedEvent event) {
    isApplyStateNotifier.value = false;
    currentRequestID = null;
  }

  void onExpressRoomStateChanged(ZegoRoomStateEvent event) {
    debugPrint('AudioRoomPage:onExpressRoomStateChanged: $event');
    if (event.errorCode != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text(
              'onExpressRoomStateChanged: reason:${event.reason.name}, errorCode:${event.errorCode}'),
        ),
      );
    }

    if ((event.reason == ZegoRoomStateChangedReason.KickOut) ||
        (event.reason == ZegoRoomStateChangedReason.ReconnectFailed) ||
        (event.reason == ZegoRoomStateChangedReason.LoginFailed)) {
      Navigator.pop(context);
    }
  }

  void onZIMRoomStateChanged(ZIMServiceRoomStateChangedEvent event) {
    debugPrint('AudioRoomPage:onZIMRoomStateChanged: $event');
    if ((event.event != ZIMRoomEvent.success) &&
        (event.state != ZIMRoomState.connected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: Text('onZIMRoomStateChanged: $event'),
        ),
      );
    }
    if (event.state == ZIMRoomState.disconnected) {
      Navigator.pop(context);
    }
  }

  void onZIMConnectionStateChanged(
    ZIMServiceConnectionStateChangedEvent event,
  ) {
    debugPrint('AudioRoomPage:onZIMConnectionStateChanged: $event');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1000),
        content: Text('onZIMConnectionStateChanged: $event'),
      ),
    );
    if (event.state == ZIMConnectionState.disconnected) {
      Navigator.pop(context);
    }
  }
}
