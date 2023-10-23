part of 'express_service.dart';

extension ExpressServiceSEI on ExpressService {
  Future<void> sendSEI(String sei, [ZegoPublishChannel? channel = ZegoPublishChannel.Main]) async {
    final seiBytes = Uint8List.fromList(utf8.encode(sei));
    ZegoExpressEngine.instance.sendSEI(seiBytes, seiBytes.length, channel: channel);
  }
}
