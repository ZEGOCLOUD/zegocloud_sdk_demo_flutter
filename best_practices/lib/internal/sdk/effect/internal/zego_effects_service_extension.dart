import '../zego_effects_service.dart';

import 'beauty_ability/zego_beauty_ability.dart';
import 'beauty_ability/zego_beauty_editor.dart';
import 'beauty_ability/zego_beauty_type.dart';
import 'zego_effects_helper.dart';

extension EffectsServiceExtension on EffectsService {
  void initBeautyAbilities() {
    // Basic
    beautyAbilities[ZegoBeautyType.beautyBasicReset] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyBasicReset,
      editor: ZegoBasicResetEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyBasicSmoothing] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyBasicSmoothing,
      editor: ZegoSmoothingEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyBasicSkinTone] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyBasicSkinTone,
      editor: ZegoSkinToneEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyBasicBlusher] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyBasicBlusher,
      editor: ZegoBlusherEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyBasicSharpening] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyBasicSharpening,
      editor: ZegoSharpeningEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyBasicWrinkles] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyBasicWrinkles,
      editor: ZegoWrinklesEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyBasicDarkCircles] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyBasicDarkCircles,
      editor: ZegoDarkCirclesEditor(),
    );

    // Advanced
    beautyAbilities[ZegoBeautyType.beautyAdvancedReset] = ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedReset,
      editor: ZegoAdvancedResetEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedFaceSlimming] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedFaceSlimming,
      editor: ZegoFaceSlimmingEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedEyesEnlarging] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedEyesEnlarging,
      editor: ZegoEyesEnlargingEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedEyesBrightening] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedEyesBrightening,
      editor: ZegoEyesBrighteningEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedChinLengthening] =
        ZegoBeautyAbility(
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      type: ZegoBeautyType.beautyAdvancedChinLengthening,
      editor: ZegoChinLengtheningEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedMouthReshape] =
        ZegoBeautyAbility(
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      type: ZegoBeautyType.beautyAdvancedMouthReshape,
      editor: ZegoMouthReshapeEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedTeethWhitening] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedTeethWhitening,
      editor: ZegoTeethWhiteningEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedNoseSlimming] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedNoseSlimming,
      editor: ZegoNoseSlimmingEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedNoseLengthening] =
        ZegoBeautyAbility(
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      type: ZegoBeautyType.beautyAdvancedNoseLengthening,
      editor: ZegoNoseLengtheningEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedFaceShortening] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedFaceShortening,
      editor: ZegoFaceShorteningEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedMandibleSlimming] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedMandibleSlimming,
      editor: ZegoMandibleSlimmingEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedCheekboneSlimming] =
        ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: ZegoBeautyType.beautyAdvancedCheekboneSlimming,
      editor: ZegoCheekboneSlimmingEditor(),
    );
    beautyAbilities[ZegoBeautyType.beautyAdvancedForeheadSlimming] =
        ZegoBeautyAbility(
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      type: ZegoBeautyType.beautyAdvancedForeheadSlimming,
      editor: ZegoForeheadSlimmingEditor(),
    );

    beautyAbilities.addAll({
      // Filters
      ZegoBeautyType.filterReset: _filterAbility(ZegoBeautyType.filterReset),
      ZegoBeautyType.filterNaturalCreamy:
          _filterAbility(ZegoBeautyType.filterNaturalCreamy),
      ZegoBeautyType.filterNaturalBrighten:
          _filterAbility(ZegoBeautyType.filterNaturalBrighten),
      ZegoBeautyType.filterNaturalFresh:
          _filterAbility(ZegoBeautyType.filterNaturalFresh),
      ZegoBeautyType.filterNaturalAutumn:
          _filterAbility(ZegoBeautyType.filterNaturalAutumn),
      ZegoBeautyType.filterGrayMonet:
          _filterAbility(ZegoBeautyType.filterGrayMonet),
      ZegoBeautyType.filterGrayNight:
          _filterAbility(ZegoBeautyType.filterGrayNight),
      ZegoBeautyType.filterGrayFilmlike:
          _filterAbility(ZegoBeautyType.filterGrayFilmlike),
      ZegoBeautyType.filterDreamySunset:
          _filterAbility(ZegoBeautyType.filterDreamySunset),
      ZegoBeautyType.filterDreamyCozily:
          _filterAbility(ZegoBeautyType.filterDreamyCozily),
      ZegoBeautyType.filterDreamySweet:
          _filterAbility(ZegoBeautyType.filterDreamySweet),

      // Makeup - Lipstick
      ZegoBeautyType.beautyMakeupLipstickReset:
          _lipsAbility(ZegoBeautyType.beautyMakeupLipstickReset),
      ZegoBeautyType.beautyMakeupLipstickCameoPink:
          _lipsAbility(ZegoBeautyType.beautyMakeupLipstickCameoPink),
      ZegoBeautyType.beautyMakeupLipstickSweetOrange:
          _lipsAbility(ZegoBeautyType.beautyMakeupLipstickSweetOrange),
      ZegoBeautyType.beautyMakeupLipstickRustRed:
          _lipsAbility(ZegoBeautyType.beautyMakeupLipstickRustRed),
      ZegoBeautyType.beautyMakeupLipstickCoral:
          _lipsAbility(ZegoBeautyType.beautyMakeupLipstickCoral),
      ZegoBeautyType.beautyMakeupLipstickRedVelvet:
          _lipsAbility(ZegoBeautyType.beautyMakeupLipstickRedVelvet),

      // Makeup - Blusher
      ZegoBeautyType.beautyMakeupBlusherReset:
          _blusherAbility(ZegoBeautyType.beautyMakeupBlusherReset),
      ZegoBeautyType.beautyMakeupBlusherSlightlyDrunk:
          _blusherAbility(ZegoBeautyType.beautyMakeupBlusherSlightlyDrunk),
      ZegoBeautyType.beautyMakeupBlusherPeach:
          _blusherAbility(ZegoBeautyType.beautyMakeupBlusherPeach),
      ZegoBeautyType.beautyMakeupBlusherMilkyOrange:
          _blusherAbility(ZegoBeautyType.beautyMakeupBlusherMilkyOrange),
      ZegoBeautyType.beautyMakeupBlusherAprocitPink:
          _blusherAbility(ZegoBeautyType.beautyMakeupBlusherAprocitPink),
      ZegoBeautyType.beautyMakeupBlusherSweetOrange:
          _blusherAbility(ZegoBeautyType.beautyMakeupBlusherSweetOrange),

      // Makeup - Eyelashes
      ZegoBeautyType.beautyMakeupEyelashesReset:
          _eyelashAbility(ZegoBeautyType.beautyMakeupEyelashesReset),
      ZegoBeautyType.beautyMakeupEyelashesNatural:
          _eyelashAbility(ZegoBeautyType.beautyMakeupEyelashesNatural),
      ZegoBeautyType.beautyMakeupEyelashesTender:
          _eyelashAbility(ZegoBeautyType.beautyMakeupEyelashesTender),
      ZegoBeautyType.beautyMakeupEyelashesCurl:
          _eyelashAbility(ZegoBeautyType.beautyMakeupEyelashesCurl),
      ZegoBeautyType.beautyMakeupEyelashesEverlong:
          _eyelashAbility(ZegoBeautyType.beautyMakeupEyelashesEverlong),
      ZegoBeautyType.beautyMakeupEyelashesThick:
          _eyelashAbility(ZegoBeautyType.beautyMakeupEyelashesThick),

      // Makeup - Eyeliner
      ZegoBeautyType.beautyMakeupEyelinerReset:
          _eyelinerAbility(ZegoBeautyType.beautyMakeupEyelinerReset),
      ZegoBeautyType.beautyMakeupEyelinerNatural:
          _eyelinerAbility(ZegoBeautyType.beautyMakeupEyelinerNatural),
      ZegoBeautyType.beautyMakeupEyelinerCatEye:
          _eyelinerAbility(ZegoBeautyType.beautyMakeupEyelinerCatEye),
      ZegoBeautyType.beautyMakeupEyelinerNaughty:
          _eyelinerAbility(ZegoBeautyType.beautyMakeupEyelinerNaughty),
      ZegoBeautyType.beautyMakeupEyelinerInnocent:
          _eyelinerAbility(ZegoBeautyType.beautyMakeupEyelinerInnocent),
      ZegoBeautyType.beautyMakeupEyelinerDignified:
          _eyelinerAbility(ZegoBeautyType.beautyMakeupEyelinerDignified),

      // Makeup - Eyeshadow
      ZegoBeautyType.beautyMakeupEyeshadowReset:
          _eyeshadowAbility(ZegoBeautyType.beautyMakeupEyeshadowReset),
      ZegoBeautyType.beautyMakeupEyeshadowPinkMist:
          _eyeshadowAbility(ZegoBeautyType.beautyMakeupEyeshadowPinkMist),
      ZegoBeautyType.beautyMakeupEyeshadowShimmerPink:
          _eyeshadowAbility(ZegoBeautyType.beautyMakeupEyeshadowShimmerPink),
      ZegoBeautyType.beautyMakeupEyeshadowTeaBrown:
          _eyeshadowAbility(ZegoBeautyType.beautyMakeupEyeshadowTeaBrown),
      ZegoBeautyType.beautyMakeupEyeshadowBrightOrange:
          _eyeshadowAbility(ZegoBeautyType.beautyMakeupEyeshadowBrightOrange),
      ZegoBeautyType.beautyMakeupEyeshadowMochaBrown:
          _eyeshadowAbility(ZegoBeautyType.beautyMakeupEyeshadowMochaBrown),

      // Makeup - Colored Contacts
      ZegoBeautyType.beautyMakeupColoredContactsReset:
          _contactsAbility(ZegoBeautyType.beautyMakeupColoredContactsReset),
      ZegoBeautyType.beautyMakeupColoredContactsDarknightBlack:
          _contactsAbility(
              ZegoBeautyType.beautyMakeupColoredContactsDarknightBlack),
      ZegoBeautyType.beautyMakeupColoredContactsStarryBlue: _contactsAbility(
          ZegoBeautyType.beautyMakeupColoredContactsStarryBlue),
      ZegoBeautyType.beautyMakeupColoredContactsBrownGreen: _contactsAbility(
          ZegoBeautyType.beautyMakeupColoredContactsBrownGreen),
      ZegoBeautyType.beautyMakeupColoredContactsLightsBrown: _contactsAbility(
          ZegoBeautyType.beautyMakeupColoredContactsLightsBrown),
      ZegoBeautyType.beautyMakeupColoredContactsChocolateBrown:
          _contactsAbility(
              ZegoBeautyType.beautyMakeupColoredContactsChocolateBrown),

      // Style Makeup
      ZegoBeautyType.beautyStyleMakeupReset:
          _styleAbility(ZegoBeautyType.beautyStyleMakeupReset),
      ZegoBeautyType.beautyStyleMakeupInnocentEyes:
          _styleAbility(ZegoBeautyType.beautyStyleMakeupInnocentEyes),
      ZegoBeautyType.beautyStyleMakeupMilkyEyes:
          _styleAbility(ZegoBeautyType.beautyStyleMakeupMilkyEyes),
      ZegoBeautyType.beautyStyleMakeupCutieCool:
          _styleAbility(ZegoBeautyType.beautyStyleMakeupCutieCool),
      ZegoBeautyType.beautyStyleMakeupPureSexy:
          _styleAbility(ZegoBeautyType.beautyStyleMakeupPureSexy),
      ZegoBeautyType.beautyStyleMakeupFlawless:
          _styleAbility(ZegoBeautyType.beautyStyleMakeupFlawless),

      // Stickers
      ZegoBeautyType.stickerReset: _stickerAbility(ZegoBeautyType.stickerReset),
      ZegoBeautyType.stickerAnimal:
          _stickerAbility(ZegoBeautyType.stickerAnimal),
      ZegoBeautyType.stickerDive: _stickerAbility(ZegoBeautyType.stickerDive),
      ZegoBeautyType.stickerCat: _stickerAbility(ZegoBeautyType.stickerCat),
      ZegoBeautyType.stickerWatermelon:
          _stickerAbility(ZegoBeautyType.stickerWatermelon),
      ZegoBeautyType.stickerDeer: _stickerAbility(ZegoBeautyType.stickerDeer),
      ZegoBeautyType.stickerCoolGirl:
          _stickerAbility(ZegoBeautyType.stickerCoolGirl),
      ZegoBeautyType.stickerClown: _stickerAbility(ZegoBeautyType.stickerClown),
      ZegoBeautyType.stickerClawMachine:
          _stickerAbility(ZegoBeautyType.stickerClawMachine),
      ZegoBeautyType.stickerSailorMoon:
          _stickerAbility(ZegoBeautyType.stickerSailorMoon),

      // Background
      ZegoBeautyType.backgroundReset: ZegoBeautyAbility(
        minValue: 0,
        maxValue: 100,
        defaultValue: 50,
        type: ZegoBeautyType.backgroundReset,
        editor: ZegoBackgroundResetEditor(),
      ),
      ZegoBeautyType.backgroundPortraitSegmentation: ZegoBeautyAbility(
        minValue: 0,
        maxValue: 100,
        defaultValue: 50,
        type: ZegoBeautyType.backgroundPortraitSegmentation,
        editor: ZegoPortraitSegmentationEditor(
            EffectsHelper.portraitSegmentationImagePath),
      ),
      ZegoBeautyType.backgroundMosaicing: ZegoBeautyAbility(
        minValue: 0,
        maxValue: 100,
        defaultValue: 50,
        type: ZegoBeautyType.backgroundMosaicing,
        editor: ZegoMosaicEditor(),
      ),
      ZegoBeautyType.backgroundGaussianBlur: ZegoBeautyAbility(
        minValue: 0,
        maxValue: 100,
        defaultValue: 50,
        type: ZegoBeautyType.backgroundGaussianBlur,
        editor: ZegoBlurEditor(),
      ),
    });
  }

  ZegoBeautyAbility _filterAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoFilterEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _lipsAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoLipstickEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _blusherAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoBlusherMakeupEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _eyelashAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoEyelashesEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _eyelinerAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoEyelinerEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _eyeshadowAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoEyeshadowEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _contactsAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoColoredContactsEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _styleAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoStyleMakeupEditor(type.path(resourcesFolder)),
    );
  }

  ZegoBeautyAbility _stickerAbility(ZegoBeautyType type) {
    return ZegoBeautyAbility(
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      type: type,
      editor: ZegoStickerEditor(type.path(resourcesFolder)),
    );
  }
}
