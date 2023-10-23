import 'package:flutter/material.dart';
import 'package:zego_effects_plugin/zego_effects_defines.dart';
import 'package:zego_effects_plugin/zego_effects_plugin.dart';

abstract class ZegoBeautyEditor {
  void enable(bool enable);
  void apply(int value);
}

/// Basic
class ZegoSmoothingEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableSmooth(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsSmoothParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setSmoothParam(param);
  }
}

class ZegoSkinToneEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableWhiten(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsWhitenParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setWhitenParam(param);
  }
}

class ZegoBlusherEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableRosy(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsRosyParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setRosyParam(param);
  }
}

class ZegoSharpeningEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableSharpen(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsSharpenParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setSharpenParam(param);
  }
}

class ZegoWrinklesEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableWrinklesRemoving(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsWrinklesRemovingParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setWrinklesRemovingParam(param);
  }
}

class ZegoDarkCirclesEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableDarkCirclesRemoving(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsDarkCirclesRemovingParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setDarkCirclesRemovingParam(param);
  }
}

/// Advanced
class ZegoFaceSlimmingEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableFaceLifting(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsFaceLiftingParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setFaceLiftingParam(param);
  }
}

class ZegoEyesEnlargingEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableBigEyes(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsBigEyesParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setBigEyesParam(param);
  }
}

class ZegoEyesBrighteningEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableEyesBrightening(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsEyesBrighteningParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setEyesBrighteningParam(param);
  }
}

class ZegoChinLengtheningEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableLongChin(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsLongChinParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setLongChinParam(param);
  }
}

class ZegoMouthReshapeEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableSmallMouth(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsSmallMouthParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setSmallMouthParam(param);
  }
}

class ZegoTeethWhiteningEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableTeethWhitening(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsTeethWhiteningParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setTeethWhiteningParam(param);
  }
}

class ZegoNoseSlimmingEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableNoseNarrowing(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsNoseNarrowingParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setNoseNarrowingParam(param);
  }
}

class ZegoNoseLengtheningEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableNoseLengthening(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsNoseLengtheningParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setNoseLengtheningParam(param);
  }
}

class ZegoFaceShorteningEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableFaceShortening(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsFaceShorteningParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setFaceShorteningParam(param);
  }
}

class ZegoMandibleSlimmingEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableMandibleSlimming(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsMandibleSlimmingParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setMandibleSlimmingParam(param);
  }
}

class ZegoCheekboneSlimmingEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableCheekboneSlimming(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsCheekboneSlimmingParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setCheekboneSlimmingParam(param);
  }
}

class ZegoForeheadSlimmingEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enableForeheadShortening(enable);
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsForeheadShorteningParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setForeheadShorteningParam(param);
  }
}

/// Filters
class ZegoFilterEditor implements ZegoBeautyEditor {
  final String path;

  ZegoFilterEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setFilterPath(enable ? path : '');
    debugPrint('setFilter() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsFilterParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setFilterParam(param);
  }
}

/// Makeup
class ZegoLipstickEditor implements ZegoBeautyEditor {
  final String path;
  ZegoLipstickEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setLipstickPath(enable ? path : '');
    debugPrint('setLipstick() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsLipstickParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setLipstickParam(param);
  }
}

class ZegoBlusherMakeupEditor implements ZegoBeautyEditor {
  final String path;
  ZegoBlusherMakeupEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setBlusherPath(enable ? path : '');
    debugPrint('setBlusherPath() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsBlusherParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setBlusherParam(param);
  }
}

class ZegoEyelashesEditor implements ZegoBeautyEditor {
  final String path;
  ZegoEyelashesEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setEyelashesPath(enable ? path : '');
    debugPrint(
        'setEyelashesPath() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsEyelashesParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setEyelashesParam(param);
  }
}

class ZegoEyelinerEditor implements ZegoBeautyEditor {
  final String path;
  ZegoEyelinerEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setEyelinerPath(enable ? path : '');
    debugPrint(
        'setEyelinerPath() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsEyelinerParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setEyelinerParam(param);
  }
}

class ZegoEyeshadowEditor implements ZegoBeautyEditor {
  final String path;
  ZegoEyeshadowEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setEyeshadowPath(enable ? path : '');
    debugPrint(
        'setEyeshadowPath() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsEyeshadowParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setEyeshadowParam(param);
  }
}

class ZegoColoredContactsEditor implements ZegoBeautyEditor {
  final String path;
  ZegoColoredContactsEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setColoredcontactsPath(enable ? path : '');
    debugPrint(
        'setColoredcontactsPath() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsColoredcontactsParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setColoredcontactsParam(param);
  }
}

/// Style Makeup
class ZegoStyleMakeupEditor implements ZegoBeautyEditor {
  final String path;
  ZegoStyleMakeupEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setMakeupPath(enable ? path : '');
    debugPrint('setMakeupPath() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsMakeupParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance.setMakeupParam(param);
  }
}

/// Stickers
class ZegoStickerEditor implements ZegoBeautyEditor {
  final String path;

  ZegoStickerEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setPendantPath(enable ? path : '');
    debugPrint('setPendantPath() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {}
}

/// Background
class ZegoPortraitSegmentationEditor implements ZegoBeautyEditor {
  final String path;

  ZegoPortraitSegmentationEditor(this.path);

  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.setPortraitSegmentationBackgroundPath(
        enable ? path : '', ZegoEffectsScaleMode.AspectFill);
    ZegoEffectsPlugin.instance.enablePortraitSegmentation(enable);
    ZegoEffectsPlugin.instance.enablePortraitSegmentationBackground(enable);
    debugPrint(
        'enablePortraitSegmentationBackground() called with: enable = [$enable], path: $path');
  }

  @override
  void apply(int value) {}
}

class ZegoMosaicEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enablePortraitSegmentation(enable);
    ZegoEffectsPlugin.instance
        .enablePortraitSegmentationBackgroundMosaic(enable);
    debugPrint(
        'enablePortraitSegmentationBackgroundMosaic() called with: enable = [$enable]');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsMosaicParam();
    param.intesity = value;
    param.type = ZegoEffectsMosaicType.Square;
    ZegoEffectsPlugin.instance
        .setPortraitSegmentationBackgroundMosaicParam(param);
  }
}

class ZegoBlurEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enablePortraitSegmentation(enable);
    ZegoEffectsPlugin.instance.enablePortraitSegmentationBackgroundBlur(enable);
    debugPrint(
        'enablePortraitSegmentationBackgroundBlur() called with: enable = [$enable]');
  }

  @override
  void apply(int value) {
    final param = ZegoEffectsBlurParam();
    param.intensity = value;
    ZegoEffectsPlugin.instance
        .setPortraitSegmentationBackgroundBlurParam(param);
  }
}

/// Reseet
class ZegoBasicResetEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {}

  @override
  void apply(int value) {}
}

class ZegoAdvancedResetEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {}

  @override
  void apply(int value) {}
}

class ZegoBackgroundResetEditor implements ZegoBeautyEditor {
  @override
  void enable(bool enable) {
    ZegoEffectsPlugin.instance.enablePortraitSegmentation(false);
    ZegoEffectsPlugin.instance.enablePortraitSegmentationBackground(false);
    ZegoEffectsPlugin.instance
        .enablePortraitSegmentationBackgroundMosaic(false);
    ZegoEffectsPlugin.instance.enablePortraitSegmentationBackgroundBlur(false);
  }

  @override
  void apply(int value) {}
}
