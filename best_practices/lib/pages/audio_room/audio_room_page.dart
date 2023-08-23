import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../components/audio_room/seat_item_view.dart';
import '../../components/common/zego_apply_cohost_list_page.dart';
import '../../internal/business/audioRoom/live_audio_room_seat.dart';
import '../../internal/sdk/zim/Define/zim_define.dart';
import '../../internal/sdk/zim/Define/zim_room_request.dart';
import '../../live_audio_room_manager.dart';
import '../../zego_sdk_manager.dart';
import '../../internal/business/audioRoom/layout_config.dart';

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

  final liveAudioRoomManager = ZegoLiveAudioRoomManager.instance;

  @override
  void initState() {
    super.initState();
    hostTakeSeat();
    final zimService = ZEGOSDKManager.instance.zimService;
    subscriptions.addAll([
      zimService.onInComingRoomRequestStreamCtrl.stream
          .listen(onInComingRoomRequest),
      zimService.onOutgoingRoomRequestAcceptedStreamCtrl.stream
          .listen(onOutgoingRoomRequestAccepted),
      zimService.onOutgoingRoomRequestRejectedStreamCtrl.stream
          .listen(onOutgoingRoomRequestRejected),
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
      if (result != null &&
          !result.errorKeys
              .contains(ZEGOSDKManager.instance.currentUser?.userID)) {
        openMicAndStartPublishStream();
      }
    }
  }

  void openMicAndStartPublishStream() {
    ZEGOSDKManager.instance.expressService.turnCameraOn(false);
    ZEGOSDKManager.instance.expressService.turnMicrophoneOn(true);
    ZEGOSDKManager.instance.expressService
        .startPublishingStream(generateStreamID());
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
    return Container(
      color: Colors.white,
      child: SizedBox(
        child: Stack(
          children: [
            Positioned(top: 80, right: 40, child: leaveButton()),
            Positioned(top: 200, child: creatSeatView()),
            Positioned(bottom: 40, child: bottomView()),
          ],
        ),
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
                  const SizedBox(
                    width: 20,
                  ),
                  lockSeatButton(),
                  const SizedBox(
                    width: 10,
                  ),
                  requestMemberButton(),
                  const SizedBox(
                    width: 10,
                  ),
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
                  const SizedBox(
                    width: 20,
                  ),
                  leaveSeatButton(),
                  const SizedBox(
                    width: 10,
                  ),
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
                  const SizedBox(
                    width: 20,
                  ),
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
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.asset('assets/icons/bottom_member.png'),
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
              child: isOn
                  ? Image.asset('assets/icons/bottom_mic_on.png')
                  : Image.asset('assets/icons/bottom_mic_off.png'),
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
            final senderMap = {
              'room_request_type': RoomRequestType.audienceApplyToBecomeCoHost
            };
            ZEGOSDKManager.instance.zimService
                .sendRoomRequest(
                    liveAudioRoomManager.hostUserNoti.value?.userID ?? '',
                    jsonEncode(senderMap))
                .then((value) {
              isApplyStateNoti.value = true;
              currentRequestID = value.requestID;
            });
          } else {
            if (currentRequestID != null) {
              ZEGOSDKManager.instance.zimService
                  .cancelRoomRequest(currentRequestID ?? '')
                  .then((value) {
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
            if (element.currentUser.value?.userID ==
                ZEGOSDKManager.instance.currentUser?.userID) {
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

  Widget creatSeatView() {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.only(
          left: (size.width - 270) / 2,
          right: (size.width - 270) / 2,
          bottom: 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: seatListView(),
      ),
    );
  }

  List<Widget> seatListView() {
    final column = <Widget>[];
    var currentIndex = 0;
    for (var columIndex = 0;
        columIndex < liveAudioRoomManager.layoutConfig!.rowConfigs.length;
        columIndex++) {
      final rowConfig =
          liveAudioRoomManager.layoutConfig!.rowConfigs[columIndex];
      column
        ..add(Row(
          children: seatRow(columIndex, currentIndex, rowConfig),
        ))
        ..add(const SizedBox(height: 10));
      currentIndex = currentIndex + rowConfig.count;
    }
    return column;
  }

  List<Widget> seatRow(
      int columIndex, int seatIndex, ZegoLiveAudioRoomLayoutRowConfig config) {
    final seatViews = <Widget>[];
    // todo user list.gen
    for (var rowIndex = 0; rowIndex < config.count; rowIndex++) {
      final view = ZegoSeatItemView(
        seat: getRoomSeatWithIndex(seatIndex + rowIndex),
        lockSeatNoti: liveAudioRoomManager.isLockSeat,
        onPressed: (seat) {
          if (seat.currentUser.value == null) {
            if (liveAudioRoomManager.roleNoti.value == ZegoLiveRole.audience) {
              liveAudioRoomManager.takeSeat(seat.seatIndex).then((value) {
                openMicAndStartPublishStream();
              }).catchError((error) {});
            } else if (liveAudioRoomManager.roleNoti.value ==
                ZegoLiveRole.coHost) {
              if (getLocalUserSeatIndex() != -1) {
                ZegoLiveAudioRoomManager.instance
                    .switchSeat(getLocalUserSeatIndex(), seat.seatIndex);
              }
            }
          } else {
            if (widget.role == ZegoLiveRole.host &&
                (ZEGOSDKManager().currentUser?.userID !=
                    seat.currentUser.value?.userID)) {
              showRemoveSpeakerAndKitOutSheet(context, seat.currentUser.value!);
            }
          }
        },
      );
      seatViews
        ..add(view)
        ..add(const SizedBox(width: 10));
    }
    return seatViews;
  }

  void showRemoveSpeakerAndKitOutSheet(
      BuildContext context, ZegoSDKUser targetUser) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: const Text('remove speaker', textAlign: TextAlign.center),
              onTap: () {
                Navigator.pop(context);
                ZegoLiveAudioRoomManager.instance
                    .removeSpeakerFromSeat(targetUser.userID);
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
                ZegoLiveAudioRoomManager.instance.muteSpeaker(
                    targetUser.userID, targetUser.isMicOnNotifier.value);
              },
            ),
            ListTile(
              title: const Text('kick out user', textAlign: TextAlign.center),
              onTap: () {
                Navigator.pop(context);
                ZegoLiveAudioRoomManager.instance
                    .kickOutRoom(targetUser.userID);
              },
            ),
          ],
        );
      },
    );
  }

  int getLocalUserSeatIndex() {
    for (final element in ZegoLiveAudioRoomManager.instance.seatList) {
      if (element.currentUser.value?.userID ==
          ZEGOSDKManager.instance.currentUser?.userID) {
        return element.seatIndex;
      }
    }
    return -1;
  }

  ZegoLiveAudioRoomSeat getRoomSeatWithIndex(int seatIndex) {
    for (final element in ZegoLiveAudioRoomManager.instance.seatList) {
      if (element.seatIndex == seatIndex) {
        return element;
      }
    }
    return ZegoLiveAudioRoomSeat(0, 0, 0);
  }

  // zim listener
  void onInComingRoomRequest(OnInComingRoomRequestReceivedEvent event) {}

  void onInComingRoomRequestCancelled(
      OnInComingRoomRequestCancelledEvent event) {}
  
  void onInComingRoomRequestTimeOut() {

  }

  void onOutgoingRoomRequestAccepted(OnOutgoingRoomRequestAcceptedEvent event) {
    for (final seat in ZegoLiveAudioRoomManager.instance.seatList) {
      if (seat.currentUser.value == null) {
        ZegoLiveAudioRoomManager.instance
            .takeSeat(seat.seatIndex)
            .then((value) {
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
