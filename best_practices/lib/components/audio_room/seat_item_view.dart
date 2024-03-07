import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../live_audio_room_manager.dart';

class ZegoSeatItemView extends StatelessWidget {
  const ZegoSeatItemView({super.key, required this.onPressed, required this.seatIndex});
  final int seatIndex;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZegoSDKUser?>(
      valueListenable: ZegoLiveAudioRoomManager().seatList[seatIndex].currentUser,
      builder: (context, user, _) {
        if (user != null) {
          return userSeatView(user);
        } else {
          return emptySeatView();
        }
      },
    );
  }

  Widget userSeatView(ZegoSDKUser userInfo) {
    return GestureDetector(
      onTap: onPressed,
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
        builder: (context, avatarUrl, child) {
          return ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    progressIndicatorBuilder: (context, url, _) => const CupertinoActivityIndicator(),
                    errorWidget: (context, url, error) => child!,
                  )
                : child,
          );
        },
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
      ),
    );
  }

  Widget emptySeatView() {
    return ValueListenableBuilder<bool>(
        valueListenable: ZegoLiveAudioRoomManager().isLockSeat,
        builder: (context, isLock, _) {
          return GestureDetector(
            onTap: isLock ? null : onPressed,
            child: Column(children: [
              SizedBox(
                width: 60,
                height: 60,
                child: isLock
                    ? Image.asset('assets/icons/seat_lock_icon.png', fit: BoxFit.fill)
                    : Image.asset('assets/icons/seat_icon_normal.png', fit: BoxFit.fill),
              ),
              const Text(''),
            ]),
          );
        });
  }
}
