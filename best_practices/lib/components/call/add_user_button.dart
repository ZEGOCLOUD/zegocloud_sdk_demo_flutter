import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../zego_call_manager.dart';

class ZegoCallAddUserButton extends StatefulWidget {
  const ZegoCallAddUserButton({Key? key}) : super(key: key);

  @override
  State<ZegoCallAddUserButton> createState() => _ZegoCallAddUserButtonState();
}

class _ZegoCallAddUserButtonState extends State<ZegoCallAddUserButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sendCallInvite,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: SizedBox.fromSize(
          size: const Size(56, 56),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void sendCallInvite() {
    final editingController1 = TextEditingController();
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Input a user id'),
          content: CupertinoTextField(controller: editingController1),
          actions: [
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                ZegoCallManager()
                    .inviteUserToJoinCall([if (editingController1.text.isNotEmpty) editingController1.text]);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
