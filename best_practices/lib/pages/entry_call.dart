part of 'home_page.dart';

class CallEntry extends StatefulWidget {
  const CallEntry({super.key});

  @override
  State<CallEntry> createState() => _CallEntryState();
}

class _CallEntryState extends State<CallEntry> {
  final inviteeIDController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text('Call Demo:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
        ]),
        Row(
          children: [
            const Text('inviteeID:'),
            const SizedBox(width: 10, height: 20),
            Expanded(
              child: TextField(
                controller: inviteeIDController,
                decoration: const InputDecoration(labelText: 'input invitee userID'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () => startCall(ZegoCallType.voice), child: const Text('voice call')),
            ElevatedButton(onPressed: () => startCall(ZegoCallType.video), child: const Text('video call'))
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Future<void> startCall(ZegoCallType callType) async {
    if (callType == ZegoCallType.video) {
      ZegoCallManager().sendVideoCall(inviteeIDController.text).then((value) {
        final errorInvitees = value.info.errorInvitees.map((e) => e.userID).toList();
        if (errorInvitees.contains(inviteeIDController.text)) {
          ZegoCallManager.instance.clearCallData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('user is not online: $value')),
          );
        } else {
          pushToCallWaitingPage();
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send call invitation failed: $error')),
        );
      });
    } else {
      ZegoCallManager().sendVoiceCall(inviteeIDController.text).then((value) {
        final errorInvitees = value.info.errorInvitees.map((e) => e.userID).toList();
        if (errorInvitees.contains(inviteeIDController.text)) {
          ZegoCallManager.instance.clearCallData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('user is not online: $value')),
          );
        } else {
          pushToCallWaitingPage();
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send call invitation failed: $error')),
        );
      });
    }
  }

  void pushToCallWaitingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CallWaitingPage(callData: ZegoCallManager().callData!),
      ),
    );
  }

  void pushToCallingPage() {
    if (ZegoCallManager().callData != null) {
      ZegoSDKUser otherUser;
      if (ZegoCallManager().callData!.inviter.userID != ZEGOSDKManager().currentUser!.userID) {
        otherUser = ZegoCallManager().callData!.inviter;
      } else {
        otherUser = ZegoCallManager().callData!.invitee;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CallingPage(callData: ZegoCallManager().callData!, otherUserInfo: otherUser),
        ),
      );
    }
  }
}
