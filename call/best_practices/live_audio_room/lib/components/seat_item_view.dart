import 'package:flutter/material.dart';
import 'package:live_audio_room_demo/internal/zego_express_service.dart';
import 'package:live_audio_room_demo/live_audio_room_seat.dart';

class ZegoSeatItemView extends StatefulWidget {
  const ZegoSeatItemView({super.key, required this.seat, required this.lockSeatNoti, this.onPressed});

  final ZegoLiveAudioRoomSeat seat;
  final ValueNotifier<bool> lockSeatNoti;

  final void Function(ZegoLiveAudioRoomSeat seat)? onPressed;

  @override
  State<ZegoSeatItemView> createState() => _ZegoSeatItemViewState();
}

class _ZegoSeatItemViewState extends State<ZegoSeatItemView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZegoUserInfo?>(
        valueListenable: widget.seat.currentUser,
        builder: (context, user, _) {
          if (user != null) {
            return userSeatView(user);
          } else {
            return emptySeatView();
          }
        });
  }

  Widget userSeatView(ZegoUserInfo userInfo) {
    return GestureDetector(
      onTap: () {
        if (widget.onPressed != null) widget.onPressed!(widget.seat);
      },
      child: SizedBox(
        width: 60,
        height: 75,
        child: Column(
          children: [
            userAvatar(userInfo),
            userNameText(userInfo),
          ],
        ),
      ),
    );
  }

  Widget userAvatar(ZegoUserInfo userInfo) {
    return ValueListenableBuilder<String?>(
        valueListenable: userInfo.avatarUrlNotifier,
        builder: (context, avatarUrl, _) {
          if (avatarUrl != null) {
            return SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                ),
              ),
            );
          } else {
            return SizedBox(
              width: 60,
              height: 60,
              child: Text(
                userInfo.userID.substring(0, 1),
                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            );
          }
        });
  }

  Widget userNameText(ZegoUserInfo userInfo) {
    return SizedBox(
      height: 10,
      child: Text(
        userInfo.userName,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget emptySeatView() {
    return GestureDetector(
      onTap: () {
        if (widget.onPressed != null && !widget.lockSeatNoti.value) {
          widget.onPressed!(widget.seat);
        }
      },
      child: setEmptySeatView(),
    );
  }

  Widget setEmptySeatView() {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.lockSeatNoti,
        builder: (context, isLock, _) {
          return SizedBox(
            width: 60,
            height: 75,
            child: isLock
                ? Image.asset('assets/icons/seat_lock_icon.png')
                : Image.asset('assets/icons/seat_icon_normal.png'),
          );
        });
  }
}
