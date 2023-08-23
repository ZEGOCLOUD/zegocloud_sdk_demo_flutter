import 'permission_io.dart' if (dart.library.html) 'permission_web.dart'
    as impl;

Future<bool> requestPermission() async {
  return impl.requestPermission();
}
