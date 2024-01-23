part of 'home_page.dart';

class MiniGameEntry extends StatelessWidget {
  const MiniGameEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('MiniGame Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MiniGamePage()),
          ),
          child: const Text('Game Page'),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
