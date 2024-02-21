import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../internal/internal_defines.dart';
import '../../zego_live_streaming_manager.dart';
import '../common/common_button.dart';

class PKButton extends StatefulWidget {
  const PKButton({super.key});

  @override
  State<PKButton> createState() => _PKButtonState();
}

class _PKButtonState extends State<PKButton> {
  ValueNotifier<bool> isSendPKingNoti = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RoomPKState>(
        valueListenable: ZegoLiveStreamingManager().pkStateNotifier,
        builder: (context, pkState, _) {
          return CommonButton(
            onTap: () {
              if (pkState == RoomPKState.isNoPK) {
                startPK();
              } else if (pkState == RoomPKState.isRequestPK) {
                ZegoLiveStreamingManager().endPKBattle();
              } else {
                ZegoLiveStreamingManager().quitPKBattle();
              }
            },
            child: Builder(
              builder: (context) {
                if (pkState == RoomPKState.isNoPK) {
                  return const Text('Start PK');
                } else if (pkState == RoomPKState.isRequestPK) {
                  return const Text('End PK');
                } else {
                  return const Text('Quit PK');
                }
              },
            ),
          );
        });
  }

  void startPK() {
    final editingController1 = TextEditingController();
    final editingController2 = TextEditingController();
    final editingController3 = TextEditingController();
    final editingController4 = TextEditingController();
    final editingController5 = TextEditingController();
    final editingController6 = TextEditingController();
    final inviteUsers = <String>[];
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Input a user id'),
          content: Column(
            children: [
              CupertinoTextField(controller: editingController1),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController2),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController3),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController4),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController5),
              const SizedBox(height: 5),
              CupertinoTextField(controller: editingController6),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                isSendPKingNoti.value = true;
                addInviteUser(inviteUsers, [
                  editingController1.text,
                  editingController2.text,
                  editingController3.text,
                  editingController4.text,
                  editingController5.text,
                  editingController6.text
                ]);
                invitePKBattle(inviteUsers);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void addInviteUser(List<String> userList, List<String> userIDs) {
    for (final userID in userIDs) {
      if (userID.isNotEmpty) {
        userList.add(userID);
      }
    }
  }

  Future<void> invitePKBattle(List<String> userList) async {
    ZegoLiveStreamingManager().invitePKBattleWith(userList).then((value) {
      // if (value.errorUserList.map((e) => e.userID).contains(editingController.text)) {
      //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('start pk failed')));
      // }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('start pk failed')));
    });
  }
}
