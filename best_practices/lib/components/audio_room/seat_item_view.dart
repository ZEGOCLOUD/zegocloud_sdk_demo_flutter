import 'package:flutter/material.dart';

import '../../internal/business/audioRoom/live_audio_room_seat.dart';
import '../../internal/sdk/express/express_service.dart';

class ZegoSeatItemView extends StatelessWidget {
  const ZegoSeatItemView({super.key, required this.seat, required this.lockSeatNoti, this.onPressed});
  final ZegoLiveAudioRoomSeat seat;
  final ValueNotifier<bool> lockSeatNoti;
  final void Function(ZegoLiveAudioRoomSeat seat)? onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZegoSDKUser?>(
        valueListenable: seat.currentUser,
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
        if (onPressed != null) onPressed!(seat);
      },
      child: Column(
        children: [
          userAvatar(userInfo),
          const SizedBox(height: 5),
          Text(
            userInfo.userName,
            style: const TextStyle(color: Colors.black, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget userAvatar(ZegoSDKUser userInfo) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ValueListenableBuilder<String?>(
          valueListenable: userInfo.avatarUrlNotifier,
          builder: (context, avatarUrl, _) {
            if (avatarUrl != null && avatarUrl.isNotEmpty) {
              return ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                child: Image.network(avatarUrl, fit: BoxFit.cover),
              );
            } else {
              return ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.grey, border: Border(bottom: BorderSide.none)),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      child: Text(
                        userInfo.userID.substring(0, 1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          }),
    );
  }

  Widget emptySeatView() {
    return GestureDetector(
      onTap: () {
        if (onPressed != null && !lockSeatNoti.value) {
          onPressed!(seat);
        }
      },
      child: Column(children: [
        SizedBox(
          width: 60,
          height: 60,
          child: ValueListenableBuilder<bool>(
            valueListenable: lockSeatNoti,
            builder: (context, isLock, _) {
              return isLock
                  ? Image.asset('assets/icons/seat_lock_icon.png', fit: BoxFit.fill)
                  : Image.asset('assets/icons/seat_icon_normal.png', fit: BoxFit.fill);
            },
          ),
        ),
        const Text(''),
      ]),
    );
  }
}
