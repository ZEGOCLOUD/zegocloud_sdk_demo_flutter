import 'dart:async';

import 'package:flutter/material.dart';
import 'package:live_audio_room_demo/components/seat_item_view.dart';
import 'package:live_audio_room_demo/define.dart';
import 'package:live_audio_room_demo/internal/zego_express_service.dart';
import 'package:live_audio_room_demo/internal/zego_custom_protocol_implement.dart';
import 'package:live_audio_room_demo/live_audio_room_manager.dart';
import 'package:live_audio_room_demo/live_audio_room_seat.dart';
import 'package:live_audio_room_demo/page/layout_config.dart';
import 'package:live_audio_room_demo/zego_sdk_manager.dart';

import '../internal/zego_custom_protocol_record.dart';

class ZegoLivePage extends StatefulWidget {
  const ZegoLivePage({super.key, required this.roomID, required this.role});

  final String roomID;
  final ZegoLiveRole role;

  @override
  State<ZegoLivePage> createState() => _ZegoLivePageState();
}

class _ZegoLivePageState extends State<ZegoLivePage> {
  CustomProtocolImplement customProtocolImplement = CustomProtocolImplement();

  List<StreamSubscription<dynamic>?> subscriptions = [];

  @override
  void initState() {
    super.initState();
    customProtocolImplement.addZIMListener();
    hostTakeSeat();
    subscriptions
      ..add(customProtocolImplement.onIncomingRequestReceivedCtrl.stream.listen(onReceiveRequestReceived))
      ..add(customProtocolImplement.onIncomingRequestAcceptedCtrl.stream.listen(onSendRequestAccepted))
      ..add(customProtocolImplement.onIncomingRequestCancelledCtrl.stream.listen(onReceiveRequestCancelled))
      ..add(customProtocolImplement.onIncomingRequestRejectedCtrl.stream.listen(onSendRequestRejected));
  }

  @override
  void dispose() {
    super.dispose();
    ZegoLiveAudioRoomManager.shared.leaveRoom();
    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
  }

  Future<void> hostTakeSeat() async {
    if (widget.role == ZegoLiveRole.host) {
      //take seat
      await ZegoLiveAudioRoomManager.shared.setSelfHost();
      ZIMRoomAttributesOperatedCallResult? result = await ZegoLiveAudioRoomManager.shared.takeSeat(0);
      if (result != null && !result.errorKeys.contains(ZEGOSDKManager.instance.localUser?.userID)) {
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
    String userID = ZEGOSDKManager.instance.localUser?.userID ?? '';
    String roomID = ZEGOSDKManager.instance.expressService.currentRoomID;
    String streamID =
        '${roomID}_${userID}_${ZegoLiveAudioRoomManager.shared.roleNoti.value == ZegoLiveRole.host ? 'host' : 'coHost'}';
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
        valueListenable: ZegoLiveAudioRoomManager.shared.roleNoti,
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
        ZegoLiveAudioRoomManager.shared.lockSeat();
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
        showBasicModalBottomSheet(context);
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
        valueListenable: ZEGOSDKManager.instance.localUser!.isMicOnNotifier,
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
          if (!customProtocolImplement.isApplyStateNoti.value) {
            customProtocolImplement.sendTakeSeatRequest();
          } else {
            customProtocolImplement.cancelTakeSeatRequest();
          }
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: customProtocolImplement.isApplyStateNoti,
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
          for (var element in ZegoLiveAudioRoomManager.shared.seatList) {
            if (element.currentUser.value?.userID == ZEGOSDKManager.instance.localUser?.userID) {
              ZegoLiveAudioRoomManager.shared.leaveSeat(element.seatIndex).then((value) {
                ZegoLiveAudioRoomManager.shared.roleNoti.value = ZegoLiveRole.audience;
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
      padding: EdgeInsets.only(left: (size.width - 270) / 2, right: (size.width - 270) / 2, bottom: 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: seatListView(),
      ),
    );
  }

  List<Widget> seatListView() {
    List<Widget> column = [];
    var currentIndex = 0;
    for (var columIndex = 0;
        columIndex < ZegoLiveAudioRoomManager.shared.layoutConfig!.rowConfigs.length;
        columIndex++) {
      var rowConfig = ZegoLiveAudioRoomManager.shared.layoutConfig!.rowConfigs[columIndex];
      column.add(Row(
        children: seatRow(columIndex, currentIndex, rowConfig),
      ));
      column.add(const SizedBox(
        height: 10,
      ));
      currentIndex = currentIndex + rowConfig.count;
    }
    return column;
  }

  List<Widget> seatRow(int columIndex, int seatIndex, ZegoLiveAudioRoomLayoutRowConfig config) {
    List<Widget> seatViews = [];
    for (var rowIndex = 0; rowIndex < config.count; rowIndex++) {
      ZegoSeatItemView view = ZegoSeatItemView(
        seat: getRoomSeatWithIndex(seatIndex + rowIndex),
        lockSeatNoti: ZegoLiveAudioRoomManager.shared.isLockSeat,
        onPressed: (seat) {
          if (seat.currentUser.value == null) {
            if (ZegoLiveAudioRoomManager.shared.roleNoti.value == ZegoLiveRole.audience) {
              ZegoLiveAudioRoomManager.shared.takeSeat(seat.seatIndex);
            } else if (ZegoLiveAudioRoomManager.shared.roleNoti.value == ZegoLiveRole.coHost) {
              if (getLocalUserSeatIndex() != -1) {
                ZegoLiveAudioRoomManager.shared.switchSeat(getLocalUserSeatIndex(), seat.seatIndex);
              }
            }
          }
        },
      );
      seatViews.add(view);
      seatViews.add(const SizedBox(
        width: 10,
      ));
    }
    return seatViews;
  }

  Future<void> showBasicModalBottomSheet(context) async {
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.black.withOpacity(0.5),
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return Container(
            color: Colors.white,
            height: 500,
            child: memberItemListView(),
          );
        });
  }

  Widget memberItemListView() {
    return ValueListenableBuilder<List<CustomProtocolRecord>>(
      valueListenable: customProtocolImplement.recordsListNoti,
      builder: (context, requestRecordsList, _) {
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return requestMemberItemView(requestRecordsList[index]);
          },
          itemCount: requestRecordsList.length,
        );
      },
    );
  }

  Widget requestMemberItemView(CustomProtocolRecord record) {
    return Container(
      height: 40,
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: 5,
            left: 10,
            child: Text(
              ZEGOSDKManager.instance.getUser(record.sender ?? '')?.userName ?? '',
              style: const TextStyle(color: Colors.black, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            top: 5,
            right: 10,
            child: SizedBox(
              width: 100,
              height: 30,
              child: OutlinedButton(
                onPressed: () => customProtocolImplement.rejectIncoming(record),
                child: const Text('reject'),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 120,
            height: 30,
            child: SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: () => customProtocolImplement.acceptIncoming(record),
                child: const Text('accept'),
              ),
            ),
          ),
          Container(
            height: 0.5,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  int getLocalUserSeatIndex() {
    for (var element in ZegoLiveAudioRoomManager.shared.seatList) {
      if (element.currentUser.value?.userID == ZEGOSDKManager.instance.localUser?.userID) {
        return element.seatIndex;
      }
    }
    return -1;
  }

  ZegoLiveAudioRoomSeat getRoomSeatWithIndex(int seatIndex) {
    for (var element in ZegoLiveAudioRoomManager.shared.seatList) {
      if (element.seatIndex == seatIndex) {
        return element;
      }
    }
    return ZegoLiveAudioRoomSeat(0, 0, 0);
  }

  void onReceiveRequestReceived(CustomProtocolIncomingRequestReceivedEvent event) {
    //TODO: refresh list
  }

  void onReceiveRequestCancelled(CustomProtocolInComingRequestCancelledEvent event) {
    //TODO: refresh list
  }

  void onSendRequestAccepted(CustomProtocolOutgoingRequestAcceptedEvent event) {
    for (var seat in ZegoLiveAudioRoomManager.shared.seatList) {
      if (seat.currentUser.value == null) {
        ZegoLiveAudioRoomManager.shared.takeSeat(seat.seatIndex).then((value) {
          openMicAndStartPublishStream();
        });
        break;
      }
    }
  }

  void onSendRequestRejected(CustomProtocolOutgoingRequestRejectedEvent event) {}
}
