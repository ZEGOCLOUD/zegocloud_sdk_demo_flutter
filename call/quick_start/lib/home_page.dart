import 'package:flutter/material.dart';
import 'package:zego_sdk_quick_start/utils/permission.dart';

import 'call_page.dart';

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
            // click me to navigate to CallPage
            ElevatedButton(
              style: buttonStyle,
              child: const Text('Call Page'),
              onPressed: () => jumpToCallPage(
                context,
                localUserID: widget.localUserID,
                localUserName: widget.localUserName,
                roomID: roomTextCtrl.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void jumpToCallPage(BuildContext context,
      {required String roomID, required String localUserID, required String localUserName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          localUserID: localUserID,
          localUserName: localUserName,
          roomID: roomID,
        ),
      ),
    );
  }
}
