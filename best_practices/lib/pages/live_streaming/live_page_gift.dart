part of 'live_page.dart';

extension ZegoLivePageStateGiftExtension on ZegoLivePageState {
  void initGift() {
    ZegoGiftController().service.recvNotifier.addListener(onGiftReceived);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ZegoGiftController().service.init(
            appID: SDKKeyCenter.appID,
            liveID: widget.roomID,
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

  Widget giftForeground() {
    return ValueListenableBuilder<ZegoGiftData?>(
      valueListenable: ZegoGiftController().playingGiftDataNotifier,
      builder: (context, giftData, _) {
        if (null == giftData) {
          return const SizedBox.shrink();
        }
        return ZegoGiftWidget(key: ValueKey(giftData.giftPath), giftData: giftData);
      },
    );
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
