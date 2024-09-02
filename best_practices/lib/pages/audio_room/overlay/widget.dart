import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../components/audio_room/seat_item_view.dart';
import '../../../live_audio_room_manager.dart';
import 'defines.dart';

class AudioRoomOverlayPageWidget extends StatefulWidget {
  final AudioRoomOverlayData overlayData;
  final GlobalKey<NavigatorState> navigatorKey;

  const AudioRoomOverlayPageWidget({
    super.key,
    required this.navigatorKey,

    /// data read from the content page, and may also change during overlaying
    required this.overlayData,
  });

  @override
  State<AudioRoomOverlayPageWidget> createState() =>
      _AudioRoomOverlayPageWidgetState();
}

class _AudioRoomOverlayPageWidgetState
    extends State<AudioRoomOverlayPageWidget> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(192, 192, 192, 255)),
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: ZegoSeatItemView(
                onPressed: () {
                  audioRoomOverlayController.restore(
                    widget.navigatorKey.currentState!.context,
                  );
                },

                /// default show host only
                seatIndex: 0,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  audioRoomOverlayController.hide();

                  /// overlay: remember logout if quit directly in overlaying
                  ZegoLiveAudioRoomManager().logoutRoom();
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset('assets/icons/top_close.png'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
