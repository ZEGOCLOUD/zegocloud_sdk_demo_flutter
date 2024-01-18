// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_sdk_quick_start/utils/permission.dart';
import 'home_page.dart';
import 'key_center.dart';

Future<void> createEngine() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Get your AppID and AppSign from ZEGOCLOUD Console
  //[My Projects -> AppID] : https://console.zegocloud.com/project
  await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
    appID,
    ZegoScenario.Default,
    appSign: kIsWeb ? null : appSign,
  ));
}

void jumpToHomePage(
  BuildContext context, {
  required String localUserID,
  required String localUserName,
}) async {
  await createEngine();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => HomePage(
        localUserID: localUserID,
        localUserName: localUserName,
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  /// Users who use the same roomID can join the same live streaming.
  final userIDTextCtrl = TextEditingController(text: Random().nextInt(100000).toString());
  final userNameTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();
    userNameTextCtrl.text = 'user_${userIDTextCtrl.text}';
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
          children: [
            const Text('Please test with two or more devices'),
            const Divider(),
            TextFormField(
              controller: userIDTextCtrl,
              decoration: const InputDecoration(labelText: 'your userID'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: userNameTextCtrl,
              decoration: const InputDecoration(labelText: 'your userName'),
            ),
            const SizedBox(height: 20),
            // click me to navigate to CallPage
            ElevatedButton(
              style: buttonStyle,
              child: const Text('Login'),
              onPressed: () => jumpToHomePage(
                context,
                localUserID: userIDTextCtrl.text,
                localUserName: userNameTextCtrl.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
