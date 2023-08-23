part of 'express_service.dart';

extension ExpressServiceMixer on ExpressService {
  Future<ZegoMixerStartResult> startMixerTask(ZegoMixerTask task) async {
    final result = await ZegoExpressEngine.instance.startMixerTask(task);
    if (result.errorCode != 0) {
      currentMixerTask = null;
    }
    return result;
  }

  void stopMixerTask() {
    if (currentMixerTask == null) {
      return;
    }
    ZegoExpressEngine.instance.stopMixerTask(currentMixerTask!);
  }
  
  Future<void> onMixerSoundLevelUpdate(Map<int, double> soundLevels) async {
    mixerSoundLevelUpdateCtrl.add(ZegoMixerSoundLevelUpdateEvent(soundLevels));
  }
}
