import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_effects_plugin/zego_effects_defines.dart';
import 'package:zego_effects_plugin/zego_effects_plugin.dart';

import '../../../../zego_sdk_manager.dart';

class EffectsHelper {
  static const String licenseKey = 'license_key';

  static const String licenseTimeKey = 'license_time_key';

  static String resourcesFolder = '';

  static String portraitSegmentationImagePath = '$resourcesFolder//BackgroundImages/image1.jpg';

  static Future<void> setResources() async {
    final folderPath = await ZEGOSDKManager().effectsService.getResourcesFolder() ?? '';
    resourcesFolder = folderPath;

    debugPrint('Current Folder Path: $folderPath');

    final commonPath = '$folderPath/CommonResources.bundle';
    final rosyPath = '$commonPath/RosyResources';
    final faceWhiteningPath = '$commonPath/FaceWhiteningResources';
    final teethPath = '$commonPath/TeethWhiteningResources';
    final faceDetectionPath = '$folderPath/FaceDetection.model';
    final stickerPath = '$folderPath/StickerBaseResources.bundle';
    final segmentationPath = '$folderPath/BackgroundSegmentation.model';

    await ZegoEffectsPlugin.instance.setResourcesPath(ZegoEffectsResourcesPathParam()
      ..common = commonPath
      ..rosy = rosyPath
      ..faceWhitening = faceWhiteningPath
      ..teeth = teethPath
      ..faceDetection = faceDetectionPath
      ..pendant = stickerPath
      ..segmentation = segmentationPath);
  }

  static Future<String> getLicence(String baseUrl, int appID, String authInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLicenseTime = prefs.getInt(licenseTimeKey) ?? 0;
    final lastLicense = prefs.getString(licenseKey) ?? '';
    if (lastLicense.isNotEmpty && lastLicenseTime > 0 && (currentTime() - lastLicenseTime < 24 * 3600 * 1000)) {
      return lastLicense;
    }

    var data = <String, dynamic>{};
    final url = '$baseUrl&AppId=$appID&AuthInfo=$authInfo';
    data = await httpGet(url);

    if (data['Code'] == 0) {
      // ignore: avoid_dynamic_calls
      final String license = data['Data']['License'];
      prefs
        ..setString(licenseKey, license)
        ..setInt(licenseTimeKey, currentTime());

      debugPrint('Request license succuss, license: $license');
      return license;
    } else {
      final license = lastLicense;
      debugPrint(
          'Request license failed, errorCode: ${data['code']}, message: ${data['Message']}, use old license: $lastLicense');
      return license;
    }
  }

  static Future<Map<String, dynamic>> httpGet(String url) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('content-type', 'application/json');
    final response = await request.close();
    final reply = await response.transform(utf8.decoder).join();
    client.close();
    return json.decode(reply);
  }

  static int currentTime() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  static Future<void> inValidLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(licenseTimeKey, 0);
    await prefs.setString(licenseKey, '');
  }
}
