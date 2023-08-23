import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermission() async {
  debugPrint('requestPermission...');
  try {
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      debugPrint('Error: Microphone permission not granted!!!');
      return false;
    }
  } on Exception catch (error) {
    debugPrint('[ERROR], request microphone permission exception, $error');
  }

  try {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      debugPrint('Error: Camera permission not granted!!!');
      return false;
    }
  } on Exception catch (error) {
    debugPrint('[ERROR], request camera permission exception, $error');
  }

  return true;
}
