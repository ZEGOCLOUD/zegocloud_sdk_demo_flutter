import 'package:flutter/material.dart';
import 'utils/permission.dart';

import 'live_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.localUserID, required this.localUserName}) : super(key: key);

  final String localUserID;
  final String localUserName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  /// Users who use the same roomID can join the same live streaming.
  final roomTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      fixedSize: const Size(120, 60),
      backgroundColor: const Color(0xff2C2F3E).withOpacity(0.6),
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please test with two or more devices'),
            const Divider(),
            Text('Your userID:${widget.localUserID}'),
            const SizedBox(height: 20),
            Text('Your userName:${widget.localUserName}'),
            const SizedBox(height: 20),
            TextFormField(
              controller: roomTextCtrl,
              decoration: const InputDecoration(labelText: 'roomID'),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: buttonStyle,
                child: const Text('Start a Live'),
                onPressed: () => jumpToLivePage(
                  context,
                  isHost: true,
                  localUserID: widget.localUserID,
                  localUserName: widget.localUserName,
                  roomID: roomTextCtrl.text,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: buttonStyle,
                child: const Text('Watch a Live'),
                onPressed: () => jumpToLivePage(
                  context,
                  isHost: false,
                  localUserID: widget.localUserID,
                  localUserName: widget.localUserName,
                  roomID: roomTextCtrl.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void jumpToLivePage(
    BuildContext context, {
    required String roomID,
    required bool isHost,
    required String localUserID,
    required String localUserName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivePage(
          isHost: isHost,
          localUserID: localUserID,
          localUserName: localUserName,
          roomID: roomID,
        ),
      ),
    );
  }
}
