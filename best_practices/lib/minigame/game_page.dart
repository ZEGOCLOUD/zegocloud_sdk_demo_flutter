import 'dart:async';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

import '../../zego_sdk_key_center.dart';
import '../../zego_sdk_manager.dart';
import '../main.dart';
import 'service/mini_game_api.dart';
import 'ui/show_game_list_view.dart';
import 'your_game_server.dart';

part 'game_page_controller.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({Key? key, required this.roomID}) : super(key: key);

  final String roomID;

  @override
  State<MiniGamePage> createState() => MiniGamePageState();
}

class MiniGamePageState extends State<MiniGamePage> {
  late final DemoGameController demoGameController = DemoGameController(
    userID: ZEGOSDKManager().currentUser!.userID,
    userName: ZEGOSDKManager().currentUser!.userName,
    roomID: widget.roomID,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      demoGameController.init(); // you need uninit demoGameController in the onWillPop block
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await demoGameController.uninit();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('ZegoMiniGame')),
          body: Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                demoGameController.gameView(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: demoGameController.gameButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
