part of 'home_page.dart';

class LiveStreamingEntry extends StatefulWidget {
  const LiveStreamingEntry({super.key});

  @override
  State<LiveStreamingEntry> createState() => _LiveStreamingEntryState();
}

class _LiveStreamingEntryState extends State<LiveStreamingEntry> {
  final roomIDController = TextEditingController(text: Random().nextInt(9999999).toString());

  int swipingRoomInfoListIndex = 0;
  final swipingRoomInfoList = <ZegoSwipingPageRoomInfo>[];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < 6; i++) {
      swipingRoomInfoList.add(ZegoSwipingPageRoomInfo(
        roomID: (200 + i).toString(),
        hostID: (200 + i).toString(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('LiveStreaming Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        const SizedBox(height: 10),
        roomIDTextField(roomIDController),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          hostJoinLivePageButton(),
          audienceJoinLivePageButton(),
        ]),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget hostJoinLivePageButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ZegoLivePage(
              roomID: roomIDController.text,
              role: ZegoLiveStreamingRole.host,
            ),
          ),
        );
      },
      child: const Text('Host enter'),
    );
  }

  Widget audienceJoinLivePageButton() {
    return ElevatedButton(
      onPressed: () {
        // final normalAudiencePage = ZegoLivePage(
        //   roomID: roomIDController.text,
        //   role: ZegoLiveStreamingRole.audience,
        // );

        final swipingAudiencePage = ZegoLivePage(
          swipingConfig: ZegoLiveSwipingConfig(
            onPageChanged: (int pageIndex) {
              swipingRoomInfoListIndex = pageIndex % swipingRoomInfoList.length;
            },
            requiredCurrentLive: () async {
              return swipingRoomInfoList[swipingRoomInfoListIndex];
            },
            requiredPreviousLive: () async {
              if (swipingRoomInfoListIndex == 0) {
                return swipingRoomInfoList[swipingRoomInfoList.length - 1];
              }
              return swipingRoomInfoList[swipingRoomInfoListIndex - 1];
            },
            requiredNextLive: () async {
              if (swipingRoomInfoListIndex == swipingRoomInfoList.length - 1) {
                return swipingRoomInfoList[0];
              }
              return swipingRoomInfoList[swipingRoomInfoListIndex + 1];
            },
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => swipingAudiencePage,
          ),
        );
      },
      child: const Text('Audience enter'),
    );
  }
}
