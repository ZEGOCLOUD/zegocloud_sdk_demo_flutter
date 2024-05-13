part of 'audio_room_page.dart';

extension ZegoLivePageStateGiftExtension on AudioRoomPageState {
  void initGift() {
    ZegoGiftController().service.recvNotifier.addListener(onGiftReceived);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ZegoGiftController().service.init(
            appID: SDKKeyCenter.appID,
            localUserID: ZEGOSDKManager().currentUser!.userID,
            localUserName: 'user_${ZEGOSDKManager().currentUser!.userID}',
          );
    });
  }

  void uninitGift() {
    ZegoGiftController().clearPlayingList();
    ZegoGiftController().service.recvNotifier.removeListener(onGiftReceived);
    ZegoGiftController().service.uninit();
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
          icon: const Icon(Icons.blender)),
    );
  }

  Widget giftForeground() {
    return ZegoGiftController().giftWidget;
  }

  Future<void> onGiftReceived() async {
    final receivedGiftCommand = ZegoGiftController().service.recvNotifier.value;
    if (receivedGiftCommand == null) {
      return;
    }

    final giftPath = await getPathFromAssetOrCache('assets/gift/${receivedGiftCommand.giftName}.mp4');
    ZegoGiftController().addToPlayingList(ZegoGiftData(giftPath: giftPath));
  }
}
