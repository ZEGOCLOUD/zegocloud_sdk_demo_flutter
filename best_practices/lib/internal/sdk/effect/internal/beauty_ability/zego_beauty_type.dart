/// @nodoc
enum ZegoBeautyType {
  // nothing.
  beautyNone,

  // Beauty
  // Beauty - Basic
  beautyBasicSmoothing,
  beautyBasicSkinTone,
  beautyBasicBlusher,
  beautyBasicSharpening,
  beautyBasicWrinkles,
  beautyBasicDarkCircles,

  // Beauty - Advanced
  beautyAdvancedFaceSlimming,
  beautyAdvancedEyesEnlarging,
  beautyAdvancedEyesBrightening,
  beautyAdvancedChinLengthening,
  beautyAdvancedMouthReshape,
  beautyAdvancedTeethWhitening,
  beautyAdvancedNoseSlimming,
  beautyAdvancedNoseLengthening,
  beautyAdvancedFaceShortening,
  beautyAdvancedMandibleSlimming,
  beautyAdvancedCheekboneSlimming,
  beautyAdvancedForeheadSlimming,

  // Beauty - Makeup
  // Beauty - Makeup - Lipstick
  beautyMakeupLipstickCameoPink,
  beautyMakeupLipstickSweetOrange,
  beautyMakeupLipstickRustRed,
  beautyMakeupLipstickCoral,
  beautyMakeupLipstickRedVelvet,

  // Beauty - Makeup - Blusher
  beautyMakeupBlusherSlightlyDrunk,
  beautyMakeupBlusherPeach,
  beautyMakeupBlusherMilkyOrange,
  beautyMakeupBlusherAprocitPink,
  beautyMakeupBlusherSweetOrange,

  // Beauty - Makeup - Eyelashes
  beautyMakeupEyelashesNatural,
  beautyMakeupEyelashesTender,
  beautyMakeupEyelashesCurl,
  beautyMakeupEyelashesEverlong,
  beautyMakeupEyelashesThick,

  // Beauty - Makeup - Eyeliner
  beautyMakeupEyelinerNatural,
  beautyMakeupEyelinerCatEye,
  beautyMakeupEyelinerNaughty,
  beautyMakeupEyelinerInnocent,
  beautyMakeupEyelinerDignified,

  // Beauty - Makeup - Eyeshadow
  beautyMakeupEyeshadowPinkMist,
  beautyMakeupEyeshadowShimmerPink,
  beautyMakeupEyeshadowTeaBrown,
  beautyMakeupEyeshadowBrightOrange,
  beautyMakeupEyeshadowMochaBrown,

  // Beauty - Makeup - Colored Contacts
  beautyMakeupColoredContactsDarknightBlack,
  beautyMakeupColoredContactsStarryBlue,
  beautyMakeupColoredContactsBrownGreen,
  beautyMakeupColoredContactsLightsBrown,
  beautyMakeupColoredContactsChocolateBrown,

  // Beauty - Style Makeup
  beautyStyleMakeupInnocentEyes,
  beautyStyleMakeupMilkyEyes,
  beautyStyleMakeupCutieCool,
  beautyStyleMakeupPureSexy,
  beautyStyleMakeupFlawless,

  // Filters
  // Filters - Natural
  filterNaturalCreamy,
  filterNaturalBrighten,
  filterNaturalFresh,
  filterNaturalAutumn,

  // Filters - Gray
  filterGrayMonet,
  filterGrayNight,
  filterGrayFilmlike,

  // Filters - Dreamy
  filterDreamySunset,
  filterDreamyCozily,
  filterDreamySweet,

  // Stickers
  stickerAnimal,
  stickerDive,
  stickerCat,
  stickerWatermelon,
  stickerDeer,
  stickerCoolGirl,
  stickerClown,
  stickerClawMachine,
  stickerSailorMoon,

  // Background
  // backgroundGreenScreenSegmentation,
  backgroundPortraitSegmentation,
  backgroundMosaicing,
  backgroundGaussianBlur,

  // Reset
  beautyBasicReset,
  beautyAdvancedReset,
  beautyMakeupLipstickReset,
  beautyMakeupBlusherReset,
  beautyMakeupEyelashesReset,
  beautyMakeupEyelinerReset,
  beautyMakeupEyeshadowReset,
  beautyMakeupColoredContactsReset,
  beautyStyleMakeupReset,
  filterReset,
  stickerReset,
  backgroundReset,
}

extension ZegoBeautyTypePath on ZegoBeautyType {
  String path(String folder) {
    if (index >= ZegoBeautyType.beautyBasicReset.index ||
        this == ZegoBeautyType.beautyNone) {
      return '';
    }
    return '$folder/AdvancedResources/$name.bundle';
  }
}
