// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GeoCam Pro';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get done => 'Done';

  @override
  String get share => 'Share';

  @override
  String get settings => 'Settings';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get noGpsSignal => 'GPS Signal...';

  @override
  String get acquiringLocation => 'Acquiring location...';

  @override
  String get manualLocation => 'Manual Location';

  @override
  String get gpsManual => 'MANUAL';

  @override
  String get cameraTitle => 'GeoCam Pro';

  @override
  String get cameraImportPhoto => 'Import Photo';

  @override
  String get cameraFlashOff => 'Flash Off';

  @override
  String get cameraSwitching => 'Switching Camera...';

  @override
  String get cameraCaptureError => 'Could not capture photo. Please try again.';

  @override
  String get editLocationTitle => 'Edit Location';

  @override
  String get editLocationSearch => 'Search for a place or address...';

  @override
  String get editLocationConfirm => 'CONFIRM LOCATION';

  @override
  String get editLocationUseGps => 'USE GPS';

  @override
  String get editLocationManualActive => 'MANUAL ACTIVE';

  @override
  String get editLocationSearchingAddress => 'Searching address…';

  @override
  String get editLocationGpsNotAvailable => 'GPS position not available yet.';

  @override
  String get editLocationAdNotReady => 'Ad not ready. Please try again.';

  @override
  String get editLocationWatchAd => 'WATCH AD TO SET LOCATION';

  @override
  String get editLocationFindingAddress => 'Finding address…';

  @override
  String get importTitle => 'Import & Geo-Tag';

  @override
  String get importChoosePhoto => 'Tap to choose a photo';

  @override
  String get importChoosePhotoHint => 'Any photo from your gallery';

  @override
  String get importChangePhoto => 'Tap to change photo';

  @override
  String get importNoLocation => 'No Location';

  @override
  String get importLocationSet => 'Location Set';

  @override
  String get importSetLocationBtn => 'Set Location on Map';

  @override
  String get importChangeLocationBtn => 'Change Location on Map';

  @override
  String get importWatermarkOptions => 'WATERMARK OPTIONS';

  @override
  String get importShowMiniMap => 'Show Mini Map';

  @override
  String get importShowAddress => 'Show Address';

  @override
  String get importShowCoordinates => 'Show Coordinates';

  @override
  String get importShowDate => 'Show Date & Time';

  @override
  String get importSaveBtn => 'GEO-TAG & SAVE TO GALLERY';

  @override
  String get importSaving => 'SAVING…';

  @override
  String get importSuccess => 'Photo geo-tagged & saved to Gallery!';

  @override
  String importSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get importGpsFromPhoto => 'GPS from photo (tap to change)';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get galleryEmpty => 'No photos yet';

  @override
  String get galleryEmptyHint => 'Take a photo with GeoCam Pro to see it here';

  @override
  String get galleryDeleteTitle => 'Delete Photo';

  @override
  String get galleryDeleteMessage =>
      'Are you sure you want to delete this photo?';

  @override
  String galleryPhotosCount(int count) {
    return '$count photos';
  }

  @override
  String get sharePhoto => 'Share Photo';

  @override
  String get sharePhotoSubtitle => 'Share the image file';

  @override
  String get shareWithGps => 'Share with GPS Data';

  @override
  String get shareWithGpsSubtitle => 'Include location info in caption';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageAuto => 'Auto (Device Language)';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsMetric => 'Metric';

  @override
  String get settingsImperial => 'Imperial';

  @override
  String get settingsCelsius => 'Celsius';

  @override
  String get settingsFahrenheit => 'Fahrenheit';

  @override
  String get settingsTemperature => 'Temperature';

  @override
  String get onboardingTitle1 => 'Professional GPS Camera';

  @override
  String get onboardingDesc1 =>
      'Capture photos with precision GPS coordinates automatically embedded';

  @override
  String get onboardingTitle2 => 'Smart Location Editing';

  @override
  String get onboardingDesc2 =>
      'Search any location worldwide and set it as your photo\'s GPS tag';

  @override
  String get onboardingTitle3 => 'Professional Watermarks';

  @override
  String get onboardingDesc3 =>
      'Add professional GPS watermarks with satellite mini-maps to your photos';

  @override
  String get permissionsTitle => 'Permissions Required';

  @override
  String get permissionsCamera => 'Camera';

  @override
  String get permissionsLocation => 'Location';

  @override
  String get permissionsStorage => 'Storage';

  @override
  String get permissionsGrantAll => 'Grant All Permissions';

  @override
  String get premiumTitle => 'GeoCam Pro';

  @override
  String get premiumUnlockBtn => 'Unlock Premium';

  @override
  String get premiumWatchAd => 'Watch Ad for Free Access';

  @override
  String get templateTitle => 'Watermark Template';

  @override
  String get templateMapType => 'Map Type';

  @override
  String get templateSatellite => 'Satellite';

  @override
  String get templateTerrain => 'Terrain';

  @override
  String get templateNormal => 'Normal';

  @override
  String get templateHybrid => 'Hybrid';

  @override
  String get editLocationClearBtn => 'CLEAR';

  @override
  String get galleryCancelBtn => 'Cancel';

  @override
  String get galleryDeleteBtn => 'Delete';

  @override
  String get galleryShareBtn => 'Share';

  @override
  String get galleryCapturedWith => 'Captured with GPS';

  @override
  String get photoDeleteTitle => 'Delete Photo';

  @override
  String get photoDeleteMessage =>
      'Are you sure you want to delete this photo?';

  @override
  String get photoImageNotFound => 'Image not found';

  @override
  String get photoShareTitle => 'Share Photo';

  @override
  String get photoShareSubtitle => 'Share the image file';

  @override
  String get photoShareWithGps => 'Share with GPS Data';

  @override
  String get photoShareWithGpsSubtitle => 'Include location info in caption';

  @override
  String get photoCoordscopied => 'Coordinates copied';

  @override
  String get settingsCameraSection => 'CAMERA & OVERLAY';

  @override
  String get settingsGridLines => 'Camera Grid Lines';

  @override
  String get settingsGridLinesSubtitle => 'Assist with photo composition';

  @override
  String get settingsWatermarkOverlay => 'GPS Watermark Overlay';

  @override
  String get settingsWatermarkOverlaySubtitle =>
      'Burn data directly into photo';

  @override
  String get settingsDataFields => 'DATA FIELDS VISIBILITY';

  @override
  String get settingsFullAddress => 'Full Address';

  @override
  String get settingsGpsCoordinates => 'GPS Coordinates';

  @override
  String get settingsCompassHeading => 'Compass & Heading';

  @override
  String get settingsDateTimeStamp => 'Date & Time Stamp';

  @override
  String get settingsDisplayFormats => 'DISPLAY FORMATS';

  @override
  String get settingsDateDisplay => 'Date Display';

  @override
  String get settingsCoordPrecision => 'Coordinate Precision';

  @override
  String get settingsAltitudeDistance => 'Altitude & Distance';

  @override
  String get settingsStorageSection => 'STORAGE & DATA';

  @override
  String get settingsExportGpsData => 'Export GPS Data';

  @override
  String get settingsExportGpsSubtitle => 'GPX, KML, or CSV format';

  @override
  String get settingsClearPhotos => 'Clear All Photos';

  @override
  String get settingsClearPhotosSubtitle => 'Safe permanent deletion';

  @override
  String get settingsLegalSection => 'LEGAL & PRIVACY';

  @override
  String get settingsTerms => 'Terms & Conditions';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsPermissionsSection => 'SYSTEM PERMISSIONS';

  @override
  String get settingsManagePermissions => 'Manage Permissions';

  @override
  String get settingsManagePermissionsSubtitle => 'Open system settings';

  @override
  String get settingsAboutSection => 'ABOUT GEOCAM PRO';

  @override
  String get settingsUpgradePremium => 'Upgrade to Premium';

  @override
  String get settingsUpgradePremiumSubtitle => 'Unlock tactical map styles';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsExporting => 'Exporting...';

  @override
  String get settingsExportGpsTitle => 'Export GPS Data';

  @override
  String settingsExportLocations(int count) {
    return 'Export $count photo locations';
  }

  @override
  String get settingsGpxFile => 'GPX File';

  @override
  String get settingsGpxSubtitle => 'For GPS devices & mapping apps';

  @override
  String get settingsKmlFile => 'KML File';

  @override
  String get settingsKmlSubtitle => 'For Google Earth';

  @override
  String get settingsCsvFile => 'CSV Spreadsheet';

  @override
  String get settingsCsvSubtitle => 'For Excel & data analysis';

  @override
  String get settingsClearAllTitle => 'Clear All Photos';

  @override
  String settingsClearAllMessage(int count) {
    return 'Delete all $count photos? This cannot be undone.';
  }

  @override
  String get settingsClearAllConfirm => 'Delete All';

  @override
  String get settingsAllPhotosDeleted => 'All photos deleted';

  @override
  String settingsExportedTo(String format) {
    return 'Exported to $format';
  }

  @override
  String get settingsNoPhotosExport => 'No photos to export';

  @override
  String get settingsExportFailed => 'Export failed';

  @override
  String get settingsShareAction => 'Share';

  @override
  String get templateDataFields => 'DATA FIELDS VISIBILITY';

  @override
  String get templateFullAddress => 'Full Address';

  @override
  String get templateGpsCoordinates => 'GPS Coordinates';

  @override
  String get templateCompassHeading => 'Compass & Heading';

  @override
  String get templateDateTimeStamp => 'Date & Time Stamp';

  @override
  String get templateDisplayFormats => 'DISPLAY FORMATS';

  @override
  String get templateDateDisplay => 'Date Display';

  @override
  String get templateCoordPrecision => 'Coordinate Precision';

  @override
  String get templateApplyBtn => 'APPLY TEMPLATE';

  @override
  String get templateSettingsApplied => 'Professional settings applied';

  @override
  String get templateUnlockPremium => 'Unlock Premium Styles';

  @override
  String get templateUnlockMessage =>
      'Watch a quick ad to unlock all premium template styles for 24 hours!';

  @override
  String get templateWatchAd => 'WATCH AD';

  @override
  String get templatePremiumUnlocked =>
      '🎉 Premium Styles unlocked for 24 hours!';

  @override
  String get templateAdNotReady => 'Ad not ready, please try again.';
}
