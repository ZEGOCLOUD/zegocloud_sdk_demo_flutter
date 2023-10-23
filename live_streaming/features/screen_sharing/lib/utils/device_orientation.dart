import 'package:native_device_orientation/native_device_orientation.dart';
export 'package:native_device_orientation/native_device_orientation.dart';
import 'package:flutter/services.dart';
export 'package:flutter/services.dart';

DeviceOrientation deviceOrientationMap(NativeDeviceOrientation nativeValue) {
  final deviceOrientationMap = <NativeDeviceOrientation, DeviceOrientation>{
    NativeDeviceOrientation.portraitUp: DeviceOrientation.portraitUp,
    NativeDeviceOrientation.portraitDown: DeviceOrientation.portraitDown,
    NativeDeviceOrientation.landscapeLeft: DeviceOrientation.landscapeLeft,
    NativeDeviceOrientation.landscapeRight: DeviceOrientation.landscapeRight,
    NativeDeviceOrientation.unknown: DeviceOrientation.portraitUp,
  };
  return deviceOrientationMap[nativeValue] ?? DeviceOrientation.portraitUp;
}

extension NativeDeviceOrientationExtension on NativeDeviceOrientation {
  bool get isLandscape =>
      this == NativeDeviceOrientation.landscapeLeft || this == NativeDeviceOrientation.landscapeRight;


  DeviceOrientation get toZegoType => deviceOrientationMap(this);
}
