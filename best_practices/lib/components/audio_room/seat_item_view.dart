import 'package:flutter/material.dart';
import '../../internal/business/audioRoom/live_audio_room_seat.dart';
import '../../internal/sdk/express/express_service.dart';

class ZegoSeatItemView extends StatefulWidget {
  const ZegoSeatItemView(
      {super.key,
      required this.seat,
      required this.lockSeatNoti,
      this.onPressed});

  final ZegoLiveAudioRoomSeat seat;
  final ValueNotifier<bool> lockSeatNoti;

  final void Function(ZegoLiveAudioRoomSeat seat)? onPressed;

  @override
  State<ZegoSeatItemView> createState() => _ZegoSeatItemViewState();
}

class _ZegoSeatItemViewState extends State<ZegoSeatItemView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZegoSDKUser?>(
        valueListenable: widget.seat.currentUser,
        builder: (context, user, _) {
          if (user != null) {
            return userSeatView(user);
          } else {
            return emptySeatView();
          }
        });
  }

  Widget userSeatView(ZegoSDKUser userInfo) {
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
            const SizedBox(
              height: 5,
            ),
            userNameText(userInfo),
          ],
        ),
      ),
    );
  }

  Widget userAvatar(ZegoSDKUser userInfo) {
    return ValueListenableBuilder<String?>(
        valueListenable: userInfo.avatarUrlNotifier,
        builder: (context, avatarUrl, _) {
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
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
              child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        border: Border(
                          bottom: BorderSide.none,
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                            height: 20,
                            child: Text(
                              userInfo.userID.substring(0, 1),
                              style: const TextStyle(
                                  decoration: TextDecoration.none,
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            )),
                      ))),
            );
          }
        });
  }

  Widget userNameText(ZegoSDKUser userInfo) {
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
              child: Column(
                children: [
                  emptySeatImage(isLock),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ));
        });
  }

  Widget emptySeatImage(bool isLock) {
    return isLock
        ? Image.asset(
            'assets/icons/seat_lock_icon.png',
            fit: BoxFit.fill,
          )
        : Image.asset(
            'assets/icons/seat_icon_normal.png',
            fit: BoxFit.fill,
          );
  }
}
