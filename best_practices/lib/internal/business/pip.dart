import 'dart:io' show Platform;
import 'package:floating/floating.dart';
import 'package:flutter/cupertino.dart';

enum ZegoPiPStatus {
  /// App is currently shrank to PiP.
  enabled,

  /// App is currently not floating over others.
  disabled,

  /// App will shrink once the user will try to minimize the app.
  automatic,

  /// PiP mode is not available on this device.
  unavailable,
}

extension ZegoPipStatusFunc on PiPStatus {
  ZegoPiPStatus toZego() {
    switch (this) {
      case PiPStatus.enabled:
        return ZegoPiPStatus.enabled;
      case PiPStatus.disabled:
        return ZegoPiPStatus.disabled;
      case PiPStatus.automatic:
        return ZegoPiPStatus.automatic;
      case PiPStatus.unavailable:
        return ZegoPiPStatus.unavailable;
    }
  }
}

class ZegoPIPController {
  ZegoPIPController._internal();
  factory ZegoPIPController() => instance;
  static final ZegoPIPController instance = ZegoPIPController._internal();

  final floating = Floating();

  Future<ZegoPiPStatus> get status async => (await floating.pipStatus).toZego();

  Future<bool> get available async => floating.isPipAvailable;

  /// sourceRectHint: Rectangle<int>(0, 0, width, height)
  Future<ZegoPiPStatus> enable({
    int aspectWidth = 9,
    int aspectHeight = 16,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('enable, only support android');

      return ZegoPiPStatus.unavailable;
    }

    final isPipAvailable = await floating.isPipAvailable;
    if (!isPipAvailable) {
      debugPrint('enable, but pip is not available, ');

      return ZegoPiPStatus.unavailable;
    }

    var status = ZegoPiPStatus.unavailable;
    try {
      status = (await floating.enable(
        ImmediatePiP(
          aspectRatio: Rational(aspectWidth, aspectHeight),
        ),
      ))
          .toZego();
    } catch (e) {
      debugPrint('enable exception:$e');
    }
    return status;
  }

  Future<ZegoPiPStatus> enableWhenBackground({
    int aspectWidth = 9,
    int aspectHeight = 16,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('enableWhenBackground, only support android');

      return ZegoPiPStatus.unavailable;
    }

    var status = ZegoPiPStatus.unavailable;
    try {
      status = await enableWhenBackground(
        aspectWidth: aspectWidth,
        aspectHeight: aspectHeight,
      );
    } catch (e) {
      debugPrint('enableWhenBackground exception:$e');
    }
    return status;
  }

  Future<void> cancelBackground() async {
    if (!Platform.isAndroid) {
      debugPrint('cancelBackground, only support android');

      return;
    }

    try {
      await floating.cancelOnLeavePiP();
    } catch (e) {
      debugPrint('cancelOnLeavePiP exception:$e');
    }
  }
}
