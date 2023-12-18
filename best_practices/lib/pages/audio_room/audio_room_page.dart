import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components/audio_room/seat_item_view.dart';
import '../../components/common/zego_apply_cohost_list_page.dart';
import '../../internal/business/audioRoom/live_audio_room_seat.dart';
import '../../live_audio_room_manager.dart';
import '../../zego_sdk_manager.dart';

class AudioRoomPage extends StatefulWidget {
  const AudioRoomPage({super.key, required this.roomID, required this.role});

  final String roomID;
  final ZegoLiveRole role;

  @override
  State<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends State<AudioRoomPage> {
  List<StreamSubscription> subscriptions = [];
  String? currentRequestID;
  ValueNotifier<bool> isApplyStateNoti = ValueNotifier(false);

  final liveAudioRoomManager = ZegoLiveAudioRoomManager();

  @override
  void initState() {
    super.initState();
    hostTakeSeat();
    final zimService = ZEGOSDKManager.instance.zimService;
    subscriptions.addAll([
      zimService.onInComingRoomRequestStreamCtrl.stream.listen(onInComingRoomRequest),
      zimService.onOutgoingRoomRequestAcceptedStreamCtrl.stream.listen(onOutgoingRoomRequestAccepted),
      zimService.onOutgoingRoomRequestRejectedStreamCtrl.stream.listen(onOutgoingRoomRequestRejected),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    liveAudioRoomManager.leaveRoom();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  Future<void> hostTakeSeat() async {
    if (widget.role == ZegoLiveRole.host) {
      //take seat
      await liveAudioRoomManager.setSelfHost();
      final result = await liveAudioRoomManager.takeSeat(0);
      if (result != null && !result.errorKeys.contains(ZEGOSDKManager.instance.currentUser?.userID)) {
        openMicAndStartPublishStream();
      }
    }
  }

  void openMicAndStartPublishStream() {
    ZEGOSDKManager.instance.expressService.turnCameraOn(false);
    ZEGOSDKManager.instance.expressService.turnMicrophoneOn(true);
    ZEGOSDKManager.instance.expressService.startPublishingStream(generateStreamID());
  }

  String generateStreamID() {
    final userID = ZEGOSDKManager.instance.currentUser?.userID ?? '';
    final roomID = ZEGOSDKManager.instance.expressService.currentRoomID;
    final streamID =
        '${roomID}_${userID}_${liveAudioRoomManager.roleNoti.value == ZegoLiveRole.host ? 'host' : 'coHost'}';
    return streamID;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const Text('LiveAudioRoom'), actions: [leaveButton()]),
        body: Stack(
          children: [
            Positioned(top: 10, child: roomTitle()),
            Positioned(top: 100, child: seatListView()),
            Positioned(bottom: 40, child: bottomView()),
          ],
        ),
      ),
    );
  }

  Widget roomTitle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Room ID: ${widget.roomID}'),
          const SizedBox(height: 10),
          ValueListenableBuilder(
            valueListenable: liveAudioRoomManager.hostUserNoti,
            builder: (BuildContext context, ZegoSDKUser? host, Widget? child) {
              return host != null ? Text('Host: ${host.userName} (id: ${host.userID})') : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget bottomView() {
    return ValueListenableBuilder<ZegoLiveRole>(
        valueListenable: liveAudioRoomManager.roleNoti,
        builder: (context, currentRole, _) {
          if (currentRole == ZegoLiveRole.host) {
            return Container(
              color: Colors.transparent,
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 20),
                  lockSeatButton(),
                  const SizedBox(width: 10),
                  requestMemberButton(),
                  const SizedBox(width: 10),
                  micorphoneButton(),
                ],
              ),
            );
          } else if (currentRole == ZegoLiveRole.coHost) {
            return SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 20),
                  leaveSeatButton(),
                  const SizedBox(width: 10),
                  micorphoneButton(),
                ],
              ),
            );
          } else {
            return SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 20),
                  requestTakeSeatButton(),
                ],
              ),
            );
          }
        });
  }

  Widget lockSeatButton() {
    return GestureDetector(
      onTap: () {
        liveAudioRoomManager.lockSeat();
      },
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.asset('assets/icons/seat_lock_icon.png'),
      ),
    );
  }

  Widget requestMemberButton() {
    return GestureDetector(
      onTap: () {
        ApplyCoHostListView().showBasicModalBottomSheet(context);
      },
      child: ValueListenableBuilder(
        valueListenable: ZEGOSDKManager.instance.zimService.roomRequestMapNoti,
        builder: (context, Map<String, dynamic> requestMap, child) {
          final requestList = requestMap.values.toList();
          return Badge(isLabelVisible: requestList.isNotEmpty, child: child);
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.asset('assets/icons/bottom_member.png'),
        ),
      ),
    );
  }

  Widget micorphoneButton() {
    return ValueListenableBuilder<bool>(
        valueListenable: ZEGOSDKManager.instance.currentUser!.isMicOnNotifier,
        builder: (context, isOn, _) {
          return GestureDetector(
            onTap: () {
              ZEGOSDKManager.instance.expressService.turnMicrophoneOn(!isOn);
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child:
                  isOn ? Image.asset('assets/icons/bottom_mic_on.png') : Image.asset('assets/icons/bottom_mic_off.png'),
            ),
          );
        });
  }

  Widget requestTakeSeatButton() {
    return SizedBox(
      width: 120,
      height: 30,
      child: OutlinedButton(
        onPressed: () {
          if (!isApplyStateNoti.value) {
            final senderMap = {'room_request_type': RoomRequestType.audienceApplyToBecomeCoHost};
            ZEGOSDKManager.instance.zimService
                .sendRoomRequest(liveAudioRoomManager.hostUserNoti.value?.userID ?? '', jsonEncode(senderMap))
                .then((value) {
              isApplyStateNoti.value = true;
              currentRequestID = value.requestID;
            });
          } else {
            if (currentRequestID != null) {
              ZEGOSDKManager.instance.zimService.cancelRoomRequest(currentRequestID ?? '').then((value) {
                isApplyStateNoti.value = false;
                currentRequestID = null;
              });
            }
          }
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: isApplyStateNoti,
          builder: (context, isApply, _) {
            return Text(
              isApply ? 'cancel apply' : 'apply take seat',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget leaveSeatButton() {
    return OutlinedButton(
        onPressed: () {
          for (final element in liveAudioRoomManager.seatList) {
            if (element.currentUser.value?.userID == ZEGOSDKManager.instance.currentUser?.userID) {
              liveAudioRoomManager.leaveSeat(element.seatIndex).then((value) {
                liveAudioRoomManager.roleNoti.value = ZegoLiveRole.audience;
                isApplyStateNoti.value = false;
                ZEGOSDKManager().expressService.stopPublishingStream();
              });
            }
          }
        },
        child: const Text('leave seat'));
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

  Widget seatListView() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 300,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisCount: 4,
        children: [
          ...List.generate(ZegoLiveAudioRoomManager().seatList.length, (seatIndex) {
            return ZegoSeatItemView(
              seat: getRoomSeatWithIndex(seatIndex),
              lockSeatNoti: liveAudioRoomManager.isLockSeat,
              onPressed: (seat) {
                if (seat.currentUser.value == null) {
                  if (liveAudioRoomManager.roleNoti.value == ZegoLiveRole.audience) {
                    liveAudioRoomManager.takeSeat(seat.seatIndex).then((value) {
                      openMicAndStartPublishStream();
                    }).catchError((error) {});
                  } else if (liveAudioRoomManager.roleNoti.value == ZegoLiveRole.coHost) {
                    if (getLocalUserSeatIndex() != -1) {
                      ZegoLiveAudioRoomManager().switchSeat(getLocalUserSeatIndex(), seat.seatIndex);
                    }
                  }
                } else {
                  if (widget.role == ZegoLiveRole.host &&
                      (ZEGOSDKManager().currentUser?.userID != seat.currentUser.value?.userID)) {
                    showRemoveSpeakerAndKitOutSheet(context, seat.currentUser.value!);
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }

  void showRemoveSpeakerAndKitOutSheet(BuildContext context, ZegoSDKUser targetUser) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: const Text('remove speaker', textAlign: TextAlign.center),
              onTap: () {
                Navigator.pop(context);
                ZegoLiveAudioRoomManager().removeSpeakerFromSeat(targetUser.userID);
              },
            ),
            ListTile(
              title: Text(targetUser.isMicOnNotifier.value ? 'mute speaker' : 'unMute speaker',
                  textAlign: TextAlign.center),
              onTap: () {
                Navigator.pop(context);
                ZegoLiveAudioRoomManager().muteSpeaker(targetUser.userID, targetUser.isMicOnNotifier.value);
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
      if (element.currentUser.value?.userID == ZEGOSDKManager.instance.currentUser?.userID) {
        return element.seatIndex;
      }
    }
    return -1;
  }

  ZegoLiveAudioRoomSeat getRoomSeatWithIndex(int seatIndex) {
    assert(seatIndex >= 0 && seatIndex < ZegoLiveAudioRoomManager().seatList.length, 'seatIndex error');
    for (final element in ZegoLiveAudioRoomManager().seatList) {
      if (element.seatIndex == seatIndex) {
        return element;
      }
    }
    throw Exception('seatIndex error');
  }

  // zim listener
  void onInComingRoomRequest(OnInComingRoomRequestReceivedEvent event) {}

  void onInComingRoomRequestCancelled(OnInComingRoomRequestCancelledEvent event) {}

  void onInComingRoomRequestTimeOut() {}

  void onOutgoingRoomRequestAccepted(OnOutgoingRoomRequestAcceptedEvent event) {
    for (final seat in ZegoLiveAudioRoomManager().seatList) {
      if (seat.currentUser.value == null) {
        ZegoLiveAudioRoomManager().takeSeat(seat.seatIndex).then((value) {
          isApplyStateNoti.value = false;
          openMicAndStartPublishStream();
        });
        break;
      }
    }
  }

  void onOutgoingRoomRequestRejected(OnOutgoingRoomRequestRejectedEvent event) {
    isApplyStateNoti.value = false;
    currentRequestID = null;
  }
}
