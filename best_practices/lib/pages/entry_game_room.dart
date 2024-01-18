part of 'home_page.dart';

class MiniGameEntry extends StatefulWidget {
  const MiniGameEntry({super.key});

  @override
  State<MiniGameEntry> createState() => _MiniGameEntryState();
}

class _MiniGameEntryState extends State<MiniGameEntry> {
  final roomIDController = TextEditingController(text: Random().nextInt(9999999).toString());
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('MiniGame Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        roomIDTextField(roomIDController),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MiniGamePage(roomID: roomIDController.text)),
          ),
          child: const Text('Enter Room'),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
