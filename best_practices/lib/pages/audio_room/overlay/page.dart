import 'package:flutter/cupertino.dart';
import 'package:pkbattles/pages/audio_room/overlay/widget.dart';
import 'package:x_overlay/x_overlay.dart';

import '../audio_room_page.dart';
import 'defines.dart';

class AudioRoomOverlayPage extends StatefulWidget {
  const AudioRoomOverlayPage({
    super.key,
    required this.navigatorKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AudioRoomOverlayPage> createState() => AudioRoomOverlayPageState();
}

class AudioRoomOverlayPageState extends State<AudioRoomOverlayPage> {
  @override
  Widget build(BuildContext context) {
    return XOverlayPage(
      size: const Size(160, 150),
      controller: audioRoomOverlayController,
      contextQuery: () {
        return widget.navigatorKey.currentState!.context;
      },
      restoreWidgetQuery: (
        XOverlayData data,
      ) {
        late AudioRoomOverlayData audioRoomOverlayData;
        if (data is AudioRoomOverlayData) {
          audioRoomOverlayData = data;
        }

        /// By default, clicking overlay page will return to the content page.
        /// so, read your overlay data, and return your content page
        return AudioRoomPage(
          roomID: audioRoomOverlayData.roomID,
          role: audioRoomOverlayData.role,
          fromOverlay: true,
        );
      },
      builder: (XOverlayData data) {
        late AudioRoomOverlayData audioRoomOverlayData;
        if (data is AudioRoomOverlayData) {
          audioRoomOverlayData = data;
        }

        /// read your overlay data and return your overlay page
        return AudioRoomOverlayPageWidget(
          navigatorKey: widget.navigatorKey,
          overlayData: audioRoomOverlayData,
        );
      },
    );
  }
}
