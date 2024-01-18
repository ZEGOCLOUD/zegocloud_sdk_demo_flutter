part of 'home_page.dart';

class AudioRoomEntry extends StatefulWidget {
  const AudioRoomEntry({super.key});

  @override
  State<AudioRoomEntry> createState() => _AudioRoomEntryState();
}

class _AudioRoomEntryState extends State<AudioRoomEntry> {
  final roomIDController = TextEditingController(text: Random().nextInt(9999999).toString());
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('LiveAudioRoom Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        roomIDTextField(roomIDController),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          liveAudioRoomButton(ZegoLiveAudioRoomRole.host),
          liveAudioRoomButton(ZegoLiveAudioRoomRole.audience),
        ]),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget liveAudioRoomButton(ZegoLiveAudioRoomRole role) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AudioRoomPage(roomID: roomIDController.text, role: role)),
      ),
      child: role == ZegoLiveAudioRoomRole.host ? const Text('Host enter') : const Text('Audience enter'),
    );
  }
}
