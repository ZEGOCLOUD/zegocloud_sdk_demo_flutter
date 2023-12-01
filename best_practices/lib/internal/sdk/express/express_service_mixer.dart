part of 'express_service.dart';

extension ExpressServiceMixer on ExpressService {
  Future<ZegoMixerStartResult> startMixerTask(ZegoMixerTask task) async {
    final result = await ZegoExpressEngine.instance.startMixerTask(task);
    if (result.errorCode != 0) {
      currentMixerTask = null;
    } else {
      currentMixerTask = task;
    }
    return result;
  }

  Future<ZegoMixerStopResult> stopMixerTask() async {
    if (currentMixerTask == null) {
      return ZegoMixerStopResult(-9999);
    }
    final result = await ZegoExpressEngine.instance.stopMixerTask(currentMixerTask!);
    return result;
  }

  Future<void> onMixerSoundLevelUpdate(Map<int, double> soundLevels) async {
    mixerSoundLevelUpdateCtrl.add(ZegoMixerSoundLevelUpdateEvent(soundLevels));
  }
}
