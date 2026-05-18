// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get appName => 'GeoCam Pro';

  @override
  String get back => 'Bumalik';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get save => 'I-save';

  @override
  String get retry => 'Subukan Muli';

  @override
  String get delete => 'I-delete';

  @override
  String get confirm => 'Kumpirmahin';

  @override
  String get done => 'Tapos na';

  @override
  String get share => 'I-share';

  @override
  String get settings => 'Mga Setting';

  @override
  String get next => 'Susunod';

  @override
  String get skip => 'Laktawan';

  @override
  String get getStarted => 'Magsimula';

  @override
  String get yes => 'Oo';

  @override
  String get no => 'Hindi';

  @override
  String get noGpsSignal => 'Signal ng GPS...';

  @override
  String get acquiringLocation => 'Kinukuha ang lokasyon...';

  @override
  String get manualLocation => 'Manwal na Lokasyon';

  @override
  String get gpsManual => 'MANWAL';

  @override
  String get cameraTitle => 'GeoCam Pro';

  @override
  String get cameraImportPhoto => 'I-import ang Larawan';

  @override
  String get cameraFlashOff => 'Naka-off ang Flash';

  @override
  String get cameraSwitching => 'Lumalipat ng Camera...';

  @override
  String get cameraCaptureError =>
      'Hindi makuha ang larawan. Pakisubukan muli.';

  @override
  String get editLocationTitle => 'I-edit ang Lokasyon';

  @override
  String get editLocationSearch => 'Maghanap ng lugar o address...';

  @override
  String get editLocationConfirm => 'KUMPIRMAHIN ANG LOKASYON';

  @override
  String get editLocationUseGps => 'GAMITIN ANG GPS';

  @override
  String get editLocationManualActive => 'AKTIBO ANG MANWAL';

  @override
  String get editLocationSearchingAddress => 'Naghahanap ng address…';

  @override
  String get editLocationGpsNotAvailable => 'Wala pa ang posisyon ng GPS.';

  @override
  String get editLocationAdNotReady =>
      'Hindi pa handa ang ad. Pakisubukan muli.';

  @override
  String get editLocationWatchAd => 'MANOOD NG AD UPANG ITAMBA ANG LOKASYON';

  @override
  String get editLocationFindingAddress => 'Hinahanap ang address…';

  @override
  String get importTitle => 'I-import at Geo-Tag';

  @override
  String get importChoosePhoto => 'I-tap para pumili ng larawan';

  @override
  String get importChoosePhotoHint => 'Kahit anong larawan mula sa gallery mo';

  @override
  String get importChangePhoto => 'I-tap para palitan ang larawan';

  @override
  String get importNoLocation => 'Walang Lokasyon';

  @override
  String get importLocationSet => 'Naitakda na ang Lokasyon';

  @override
  String get importSetLocationBtn => 'Itakda ang Lokasyon sa Mapa';

  @override
  String get importChangeLocationBtn => 'Palitan ang Lokasyon sa Mapa';

  @override
  String get importWatermarkOptions => 'MGA OPSYON SA WATERMARK';

  @override
  String get importShowMiniMap => 'Ipakita ang Mini Map';

  @override
  String get importShowAddress => 'Ipakita ang Address';

  @override
  String get importShowCoordinates => 'Ipakita ang Coordinates';

  @override
  String get importShowDate => 'Ipakita ang Petsa at Oras';

  @override
  String get importSaveBtn => 'GEO-TAG AT I-SAVE SA GALLERY';

  @override
  String get importSaving => 'SINI-SAVE…';

  @override
  String get importSuccess =>
      'Na-geo-tag na ang larawan at nai-save sa Gallery!';

  @override
  String importSaveFailed(String error) {
    return 'Bigo ang pag-save: $error';
  }

  @override
  String get importGpsFromPhoto => 'GPS mula sa larawan (i-tap para palitan)';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get galleryEmpty => 'Wala pang larawan';

  @override
  String get galleryEmptyHint =>
      'Kumuha ng larawan gamit ang GeoCam Pro upang makita ito rito';

  @override
  String get galleryDeleteTitle => 'I-delete ang Larawan';

  @override
  String get galleryDeleteMessage =>
      'Sigurado ka bang gusto mong i-delete ang larawang ito?';

  @override
  String galleryPhotosCount(int count) {
    return '$count (na) larawan';
  }

  @override
  String get sharePhoto => 'I-share ang Larawan';

  @override
  String get sharePhotoSubtitle => 'I-share ang file ng larawan';

  @override
  String get shareWithGps => 'I-share kasama ang Data ng GPS';

  @override
  String get shareWithGpsSubtitle =>
      'Isama ang impormasyon ng lokasyon sa caption';

  @override
  String get settingsTitle => 'Mga Setting';

  @override
  String get settingsLanguage => 'Wika';

  @override
  String get settingsLanguageAuto => 'Auto (Wika ng Device)';

  @override
  String get settingsUnits => 'Mga Yunit';

  @override
  String get settingsMetric => 'Metric';

  @override
  String get settingsImperial => 'Imperial';

  @override
  String get settingsCelsius => 'Celsius';

  @override
  String get settingsFahrenheit => 'Fahrenheit';

  @override
  String get settingsTemperature => 'Temperatura';

  @override
  String get onboardingTitle1 => 'Propesyonal na GPS Camera';

  @override
  String get onboardingDesc1 =>
      'Kumuha ng mga larawan na may awtomatikong nakapaloob na GPS coordinates';

  @override
  String get onboardingTitle2 => 'Matalinong Pag-edit ng Lokasyon';

  @override
  String get onboardingDesc2 =>
      'Maghanap ng anumang lokasyon sa buong mundo at itakda ito bilang GPS tag ng larawan mo';

  @override
  String get onboardingTitle3 => 'Mga Propesyonal na Watermark';

  @override
  String get onboardingDesc3 =>
      'Magdagdag ng mga propesyonal na GPS watermark na may mga satellite mini-map sa mga larawan mo';

  @override
  String get permissionsTitle => 'Kailangan ng mga Pahintulot';

  @override
  String get permissionsCamera => 'Camera';

  @override
  String get permissionsLocation => 'Lokasyon';

  @override
  String get permissionsStorage => 'Storage';

  @override
  String get permissionsGrantAll => 'Ibigay ang Lahat ng Pahintulot';

  @override
  String get premiumTitle => 'GeoCam Pro';

  @override
  String get premiumUnlockBtn => 'I-unlock ang Premium';

  @override
  String get premiumWatchAd => 'Manood ng Ad para sa Libreng Access';

  @override
  String get templateTitle => 'Template ng Watermark';

  @override
  String get templateMapType => 'Uri ng Mapa';

  @override
  String get templateSatellite => 'Satellite';

  @override
  String get templateTerrain => 'Terrain';

  @override
  String get templateNormal => 'Normal';

  @override
  String get templateHybrid => 'Hybrid';

  @override
  String get editLocationClearBtn => 'ALISIN';

  @override
  String get galleryCancelBtn => 'Kanselahin';

  @override
  String get galleryDeleteBtn => 'Burahin';

  @override
  String get galleryShareBtn => 'Ibahagi';

  @override
  String get galleryCapturedWith => 'Kinuha gamit ang GPS';

  @override
  String get photoDeleteTitle => 'I-delete ang Larawan';

  @override
  String get photoDeleteMessage =>
      'Sigurado ka bang gusto mong i-delete ang larawang ito?';

  @override
  String get photoImageNotFound => 'Hindi nahanap ang larawan';

  @override
  String get photoShareTitle => 'I-share ang Larawan';

  @override
  String get photoShareSubtitle => 'I-share ang file ng larawan';

  @override
  String get photoShareWithGps => 'I-share kasama ang Data ng GPS';

  @override
  String get photoShareWithGpsSubtitle =>
      'Isama ang impormasyon ng lokasyon sa caption';

  @override
  String get photoCoordscopied => 'Nakopya ang mga coordinates';

  @override
  String get settingsCameraSection => 'CAMERA AT OVERLAY';

  @override
  String get settingsGridLines => 'Mga Grid Line ng Camera';

  @override
  String get settingsGridLinesSubtitle => 'Tulong sa komposisyon ng larawan';

  @override
  String get settingsWatermarkOverlay => 'GPS Watermark Overlay';

  @override
  String get settingsWatermarkOverlaySubtitle =>
      'I-burn ang data direkta sa larawan';

  @override
  String get settingsDataFields => 'VISIBILITY NG MGA DATA FIELD';

  @override
  String get settingsFullAddress => 'Buong Address';

  @override
  String get settingsGpsCoordinates => 'Mga Koordinasyon ng GPS';

  @override
  String get settingsCompassHeading => 'Compass at Direksyon';

  @override
  String get settingsDateTimeStamp => 'Petsa at Oras na Stamp';

  @override
  String get settingsDisplayFormats => 'MGA FORMAT NG DISPLAY';

  @override
  String get settingsDateDisplay => 'Display ng Petsa';

  @override
  String get settingsCoordPrecision => 'Katumpakan ng Koordinasyon';

  @override
  String get settingsAltitudeDistance => 'Taas at Distansya';

  @override
  String get settingsStorageSection => 'STORAGE AT DATA';

  @override
  String get settingsExportGpsData => 'I-export ang Data ng GPS';

  @override
  String get settingsExportGpsSubtitle => 'Format na GPX, KML, o CSV';

  @override
  String get settingsClearPhotos => 'Burahin ang Lahat ng Larawan';

  @override
  String get settingsClearPhotosSubtitle => 'Ligtas na permanenteng pagbubura';

  @override
  String get settingsLegalSection => 'LEGAL AT PRIVACY';

  @override
  String get settingsTerms => 'Mga Tuntunin at Kundisyon';

  @override
  String get settingsPrivacy => 'Patakaran sa Privacy';

  @override
  String get settingsPermissionsSection => 'MGA PAHINTULOT NG SISTEMA';

  @override
  String get settingsManagePermissions => 'Pamahalaan ang mga Pahintulot';

  @override
  String get settingsManagePermissionsSubtitle =>
      'Buksan ang mga setting ng sistema';

  @override
  String get settingsAboutSection => 'TUNGKOL SA GEOCAM PRO';

  @override
  String get settingsUpgradePremium => 'Mag-upgrade sa Premium';

  @override
  String get settingsUpgradePremiumSubtitle =>
      'I-unlock ang mga tactical na istilo ng mapa';

  @override
  String get settingsAppVersion => 'Bersyon ng App';

  @override
  String get settingsExporting => 'Ine-export...';

  @override
  String get settingsExportGpsTitle => 'I-export ang Data ng GPS';

  @override
  String settingsExportLocations(int count) {
    return 'I-export ang $count lokasyon ng larawan';
  }

  @override
  String get settingsGpxFile => 'File na GPX';

  @override
  String get settingsGpxSubtitle => 'Para sa mga GPS device at mapping app';

  @override
  String get settingsKmlFile => 'File na KML';

  @override
  String get settingsKmlSubtitle => 'Para sa Google Earth';

  @override
  String get settingsCsvFile => 'Spreadsheet na CSV';

  @override
  String get settingsCsvSubtitle => 'Para sa Excel at pagsusuri ng data';

  @override
  String get settingsClearAllTitle => 'Burahin ang Lahat ng Larawan';

  @override
  String settingsClearAllMessage(int count) {
    return 'Burahin ang lahat ng $count larawan? Hindi ito mababago.';
  }

  @override
  String get settingsClearAllConfirm => 'Burahin Lahat';

  @override
  String get settingsAllPhotosDeleted => 'Lahat ng larawan ay nabura';

  @override
  String settingsExportedTo(String format) {
    return 'Na-export sa $format';
  }

  @override
  String get settingsNoPhotosExport => 'Walang larawang ie-export';

  @override
  String get settingsExportFailed => 'Nabigo ang pag-export';

  @override
  String get settingsShareAction => 'Ibahagi';

  @override
  String get templateDataFields => 'VISIBILITY NG MGA DATA FIELD';

  @override
  String get templateFullAddress => 'Buong Address';

  @override
  String get templateGpsCoordinates => 'Mga Koordinasyon ng GPS';

  @override
  String get templateCompassHeading => 'Compass at Direksyon';

  @override
  String get templateDateTimeStamp => 'Petsa at Oras na Stamp';

  @override
  String get templateDisplayFormats => 'MGA FORMAT NG DISPLAY';

  @override
  String get templateDateDisplay => 'Display ng Petsa';

  @override
  String get templateCoordPrecision => 'Katumpakan ng Koordinasyon';

  @override
  String get templateApplyBtn => 'ILAPAT ANG TEMPLATE';

  @override
  String get templateSettingsApplied =>
      'Inilapat ang mga propesyonal na setting';

  @override
  String get templateUnlockPremium => 'I-unlock ang mga Premium na Istilo';

  @override
  String get templateUnlockMessage =>
      'Manood ng maikling ad para i-unlock ang lahat ng premium na istilo ng template sa loob ng 24 na oras!';

  @override
  String get templateWatchAd => 'MANOOD NG AD';

  @override
  String get templatePremiumUnlocked =>
      '🎉 Mga Premium na Istilo ay na-unlock sa loob ng 24 na oras!';

  @override
  String get templateAdNotReady => 'Hindi pa handa ang ad, subukan muli.';
}
