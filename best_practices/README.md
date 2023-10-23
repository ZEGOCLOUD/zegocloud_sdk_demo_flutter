
# How to integrate it into your own project

----

# 1 The code structure of the Demo is as follows.

Before we start, let me introduce the structure of the demo.

```bash
lib
├── components
├── internal
├── utils
├── zego_sdk_manager.dart
├── live_audio_room_manager.dart
├── zego_live_streaming_manager.dart
├── zego_call_manager.dart
├── zego_sdk_key_center.dart
├── main.dart
└── pages
    ├── login_page.dart
    ├── home_page.dart
    ├── audio_room
    ├── call
    └── live_streaming
```

- zego_sdk_key_center.dart - You need to fill in your appid and appsign to this file. (serverSecret can be filled in arbitrarily if you don't need Flutter web).
- `components` - UI components used in the demo.
- `utils` - App permission management, token generation, and other logic
- `internal` - Best practice encapsulation of ZEGOCLOUD SDK, try not to modify the code here (if there are bug fixes in the demo, we will update it here, and you should strive to keep the code here consistent with our demo to facilitate easier updates).
- `zego_sdk_manager.dart` - You need to initialize the SDK using the init method and call the connectUser method to connect the user when they login. ( Please refer to login_page.dart for specific usage instructions.)
- `zego_live_streaming_manager.dart` - ZEGOCLOUD implements live streaming scenes, including methods such as joining and leaving rooms, co-hosting, PK, etc. Please refer to `pages/live_streaming` for specific usage instructions.
- `live_audio_room_manager.dart`- ZEGOCLOUD implements the scene of a live audio room (voice chat room), including methods such as joining and leaving the room, taking and leaving the seat, locking the seats, and switching seats, etc. Please refer to pages/audio_room for specific usage methods.
- `zego_call_manager.dart`- ZEGOCLOUD implements the scene of a video/audio call, including methods such as joining and leaving the call, switch camera, enable speaker, etc. Please refer to pages/call for specific usage methods.
- `login_page.dart` and `home_page.dart` - You can refer to these two files to see how to initialize the SDK and how to navigate to the live page and chat room page.

# 2 Integration guide
## 2.1 Copy Dart files into your project

- You need to copy the red part files to your project
- And the blue part is optional:
  - If you need live streaming, you will need `pages/live_streaming` and  `zego_live_streaming_manager.dart`
  - If you need live audio room, you will need `pages/audio_room` and  `live_audio_room_manager.dart`
  - If you need call, you will need `pages/call` and  `zego_call_manager.dart`

![](./docs/1.jpeg)

## 2.2 Copy assets to your project

- Copy assets into your project and declare them in the `pubspec.yaml` file. (Due to the usage of some assets in the demo, such as button icons)

![](./docs/2.png)

## 2.3 Use them in your code

### 2.3.1 init sdk and connect user

You need to initialize the SDK using the `init` method and call the `connectUser` method to connect the user when they login. ( Please refer to `login_page.dart` for specific usage instructions.)

You can put this logic in your user's login button, or call these two methods when the user successfully logs in through cache. For example:

```dart
ElevatedButton(
  onPressed: () async {
    await ZEGOSDKManager.instance.init(SDKKeyCenter.appID, kIsWeb ? null : SDKKeyCenter.appSign);
    await ZEGOSDKManager.instance.connectUser(userIDController.text, userNameController.text);
  },
  child: const Text('Login'),
),
```

Tips: You can use the `ZEGOSDKManager` to listen to the underlying events of the Basic SDK and obtain the user connection state. Below is an example code for navigating to the home page when the user successfully connects. ( Please refer to `login_page.dart`. )

```dart
ZEGOSDKManager.instance.zimService.connectionStateStreamCtrl.stream.listen((ZIMServiceConnectionStateChangedEvent event) {
  debugPrint('connectionStateStreamCtrl: $event');
  if (event.state == ZIMConnectionState.connected) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }
});
```

### 2.3.2 Navigate to the live_page

After ensuring successful user login, you can freely use `ZegoLivePage` at any time.

```dart
  Widget hostJoinLivePageButton() {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ZegoLivePage(roomID: roomIDController.text, role: ZegoLiveRole.host),
            ),
          );
        },
        child: const Text('Start a Live Streaming'),
      ),
    );
  }
```


