part of 'live_page.dart';

class ZegoLiveBottomBar extends StatefulWidget {
  const ZegoLiveBottomBar({
    super.key,
    this.applying,
    required this.liveStreamingManager,
  });

  final ZegoLiveStreamingManager liveStreamingManager;

  final ValueNotifier<bool>? applying;

  @override
  State<ZegoLiveBottomBar> createState() => _ZegoLiveBottomBarState();
}

class _ZegoLiveBottomBarState extends State<ZegoLiveBottomBar> {
  RoomRequest? myRoomRequest;

  @override
  Widget build(BuildContext context) {
    if (ZEGOSDKManager().currentUser == null) {
      return const SizedBox.shrink();
    } else {
      return ValueListenableBuilder<ZegoLiveStreamingRole>(
        valueListenable: widget.liveStreamingManager.currentUserRoleNotifier,
        builder: (context, role, _) {
          return bottomBar(role);
        },
      );
    }
  }

  Widget bottomBar(ZegoLiveStreamingRole role) {
    if (role == ZegoLiveStreamingRole.host) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          switchCameraButton(),
        ],
      );
    } else if (role == ZegoLiveStreamingRole.audience) {
      return ValueListenableBuilder<bool>(
        valueListenable: widget.applying!,
        builder: (context, state, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 50, height: 50),
              const SizedBox(width: 50, height: 50),
              giftButton(),
              if (state) cancelApplyCohostButton() else applyCoHostButton(),
            ],
          );
        },
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          toggleMicButton(),
          toggleCameraButton(),
          switchCameraButton(),
          giftButton(),
          endCohostButton(),
        ],
      );
    }
  }

  Widget giftButton() {
    return SizedBox(
      width: 50,
      height: 50,
      child: IconButton(
          color: Colors.white,
          onPressed: () async {
            /// local play
            const giftName = 'music_box';
            final giftPath = await getPathFromAssetOrCache('assets/gift/$giftName.mp4');
            ZegoGiftController().addToPlayingList(ZegoGiftData(giftPath: giftPath));

            /// notify remote host
            ZegoGiftController().service.sendGift(giftName: giftName);
          },
          icon: const Icon(Icons.wallet_giftcard)),
    );
  }

  Widget toggleMicButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleMicrophoneButton(),
      );
    });
  }

  Widget toggleCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: ZegoToggleCameraButton(),
      );
    });
  }

  Widget switchCameraButton() {
    return LayoutBuilder(builder: (context, constrains) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: ZegoSwitchCameraButton(),
      );
    });
  }

  Widget applyCoHostButton() {
    return OutlinedButton(
        style: OutlinedButton.styleFrom(side: const BorderSide(width: 1, color: Colors.white)),
        onPressed: () {
          final signaling = jsonEncode({
            'room_request_type': RoomRequestType.audienceApplyToBecomeCoHost,
          });
          ZEGOSDKManager().zimService.sendRoomRequest(widget.liveStreamingManager.hostNotifier.value?.userID ?? '', signaling).then((value) {
            widget.applying?.value = true;
            myRoomRequest = ZEGOSDKManager().zimService.roomRequestMapNoti.value[value.requestID];
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('apply to co-host failed: $error')));
          });
        },
        child: const Text(
          'Apply to co-host',
          style: TextStyle(
            color: Colors.white,
          ),
        ));
  }

  Widget cancelApplyCohostButton() {
    return OutlinedButton(
        style: OutlinedButton.styleFrom(side: const BorderSide(width: 1, color: Colors.white)),
        onPressed: () {
          ZEGOSDKManager().zimService.cancelRoomRequest(myRoomRequest?.requestID ?? '').then((value) {
            widget.applying?.value = false;
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel the application failed: $error')));
          });
        },
        child: const Text('Cancel the application', style: TextStyle(color: Colors.white)));
  }

  Widget endCohostButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(side: const BorderSide(width: 1, color: Colors.white)),
      onPressed: () {
        widget.liveStreamingManager.endCoHost();
      },
      child: const Text('End co-host', style: TextStyle(color: Colors.white)),
    );
  }
}
