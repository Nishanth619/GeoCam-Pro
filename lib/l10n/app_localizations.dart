import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('id'),
    Locale('ru'),
    Locale('tl'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'GeoCam Pro'**
  String get appName;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noGpsSignal.
  ///
  /// In en, this message translates to:
  /// **'GPS Signal...'**
  String get noGpsSignal;

  /// No description provided for @acquiringLocation.
  ///
  /// In en, this message translates to:
  /// **'Acquiring location...'**
  String get acquiringLocation;

  /// No description provided for @manualLocation.
  ///
  /// In en, this message translates to:
  /// **'Manual Location'**
  String get manualLocation;

  /// No description provided for @gpsManual.
  ///
  /// In en, this message translates to:
  /// **'MANUAL'**
  String get gpsManual;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'GeoCam Pro'**
  String get cameraTitle;

  /// No description provided for @cameraImportPhoto.
  ///
  /// In en, this message translates to:
  /// **'Import Photo'**
  String get cameraImportPhoto;

  /// No description provided for @cameraFlashOff.
  ///
  /// In en, this message translates to:
  /// **'Flash Off'**
  String get cameraFlashOff;

  /// No description provided for @cameraSwitching.
  ///
  /// In en, this message translates to:
  /// **'Switching Camera...'**
  String get cameraSwitching;

  /// No description provided for @cameraCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Could not capture photo. Please try again.'**
  String get cameraCaptureError;

  /// No description provided for @editLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Location'**
  String get editLocationTitle;

  /// No description provided for @editLocationSearch.
  ///
  /// In en, this message translates to:
  /// **'Search for a place or address...'**
  String get editLocationSearch;

  /// No description provided for @editLocationConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM LOCATION'**
  String get editLocationConfirm;

  /// No description provided for @editLocationUseGps.
  ///
  /// In en, this message translates to:
  /// **'USE GPS'**
  String get editLocationUseGps;

  /// No description provided for @editLocationManualActive.
  ///
  /// In en, this message translates to:
  /// **'MANUAL ACTIVE'**
  String get editLocationManualActive;

  /// No description provided for @editLocationSearchingAddress.
  ///
  /// In en, this message translates to:
  /// **'Searching address…'**
  String get editLocationSearchingAddress;

  /// No description provided for @editLocationGpsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'GPS position not available yet.'**
  String get editLocationGpsNotAvailable;

  /// No description provided for @editLocationAdNotReady.
  ///
  /// In en, this message translates to:
  /// **'Ad not ready. Please try again.'**
  String get editLocationAdNotReady;

  /// No description provided for @editLocationWatchAd.
  ///
  /// In en, this message translates to:
  /// **'WATCH AD TO SET LOCATION'**
  String get editLocationWatchAd;

  /// No description provided for @editLocationFindingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding address…'**
  String get editLocationFindingAddress;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import & Geo-Tag'**
  String get importTitle;

  /// No description provided for @importChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a photo'**
  String get importChoosePhoto;

  /// No description provided for @importChoosePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Any photo from your gallery'**
  String get importChoosePhotoHint;

  /// No description provided for @importChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get importChangePhoto;

  /// No description provided for @importNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No Location'**
  String get importNoLocation;

  /// No description provided for @importLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Location Set'**
  String get importLocationSet;

  /// No description provided for @importSetLocationBtn.
  ///
  /// In en, this message translates to:
  /// **'Set Location on Map'**
  String get importSetLocationBtn;

  /// No description provided for @importChangeLocationBtn.
  ///
  /// In en, this message translates to:
  /// **'Change Location on Map'**
  String get importChangeLocationBtn;

  /// No description provided for @importWatermarkOptions.
  ///
  /// In en, this message translates to:
  /// **'WATERMARK OPTIONS'**
  String get importWatermarkOptions;

  /// No description provided for @importShowMiniMap.
  ///
  /// In en, this message translates to:
  /// **'Show Mini Map'**
  String get importShowMiniMap;

  /// No description provided for @importShowAddress.
  ///
  /// In en, this message translates to:
  /// **'Show Address'**
  String get importShowAddress;

  /// No description provided for @importShowCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Show Coordinates'**
  String get importShowCoordinates;

  /// No description provided for @importShowDate.
  ///
  /// In en, this message translates to:
  /// **'Show Date & Time'**
  String get importShowDate;

  /// No description provided for @importSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'GEO-TAG & SAVE TO GALLERY'**
  String get importSaveBtn;

  /// No description provided for @importSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING…'**
  String get importSaving;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo geo-tagged & saved to Gallery!'**
  String get importSuccess;

  /// No description provided for @importSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String importSaveFailed(String error);

  /// No description provided for @importGpsFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'GPS from photo (tap to change)'**
  String get importGpsFromPhoto;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @galleryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get galleryEmpty;

  /// No description provided for @galleryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo with GeoCam Pro to see it here'**
  String get galleryEmptyHint;

  /// No description provided for @galleryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get galleryDeleteTitle;

  /// No description provided for @galleryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get galleryDeleteMessage;

  /// No description provided for @galleryPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String galleryPhotosCount(int count);

  /// No description provided for @sharePhoto.
  ///
  /// In en, this message translates to:
  /// **'Share Photo'**
  String get sharePhoto;

  /// No description provided for @sharePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share the image file'**
  String get sharePhotoSubtitle;

  /// No description provided for @shareWithGps.
  ///
  /// In en, this message translates to:
  /// **'Share with GPS Data'**
  String get shareWithGps;

  /// No description provided for @shareWithGpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include location info in caption'**
  String get shareWithGpsSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (Device Language)'**
  String get settingsLanguageAuto;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get settingsMetric;

  /// No description provided for @settingsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get settingsImperial;

  /// No description provided for @settingsCelsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get settingsCelsius;

  /// No description provided for @settingsFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get settingsFahrenheit;

  /// No description provided for @settingsTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get settingsTemperature;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Professional GPS Camera'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Capture photos with precision GPS coordinates automatically embedded'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Smart Location Editing'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Search any location worldwide and set it as your photo\'s GPS tag'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Professional Watermarks'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Add professional GPS watermarks with satellite mini-maps to your photos'**
  String get onboardingDesc3;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsTitle;

  /// No description provided for @permissionsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionsCamera;

  /// No description provided for @permissionsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permissionsLocation;

  /// No description provided for @permissionsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get permissionsStorage;

  /// No description provided for @permissionsGrantAll.
  ///
  /// In en, this message translates to:
  /// **'Grant All Permissions'**
  String get permissionsGrantAll;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'GeoCam Pro'**
  String get premiumTitle;

  /// No description provided for @premiumUnlockBtn.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get premiumUnlockBtn;

  /// No description provided for @premiumWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad for Free Access'**
  String get premiumWatchAd;

  /// No description provided for @templateTitle.
  ///
  /// In en, this message translates to:
  /// **'Watermark Template'**
  String get templateTitle;

  /// No description provided for @templateMapType.
  ///
  /// In en, this message translates to:
  /// **'Map Type'**
  String get templateMapType;

  /// No description provided for @templateSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get templateSatellite;

  /// No description provided for @templateTerrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get templateTerrain;

  /// No description provided for @templateNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get templateNormal;

  /// No description provided for @templateHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get templateHybrid;

  /// No description provided for @editLocationClearBtn.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get editLocationClearBtn;

  /// No description provided for @galleryCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get galleryCancelBtn;

  /// No description provided for @galleryDeleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get galleryDeleteBtn;

  /// No description provided for @galleryShareBtn.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get galleryShareBtn;

  /// No description provided for @galleryCapturedWith.
  ///
  /// In en, this message translates to:
  /// **'Captured with GPS'**
  String get galleryCapturedWith;

  /// No description provided for @photoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get photoDeleteTitle;

  /// No description provided for @photoDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get photoDeleteMessage;

  /// No description provided for @photoImageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get photoImageNotFound;

  /// No description provided for @photoShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Photo'**
  String get photoShareTitle;

  /// No description provided for @photoShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share the image file'**
  String get photoShareSubtitle;

  /// No description provided for @photoShareWithGps.
  ///
  /// In en, this message translates to:
  /// **'Share with GPS Data'**
  String get photoShareWithGps;

  /// No description provided for @photoShareWithGpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include location info in caption'**
  String get photoShareWithGpsSubtitle;

  /// No description provided for @photoCoordscopied.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get photoCoordscopied;

  /// No description provided for @settingsCameraSection.
  ///
  /// In en, this message translates to:
  /// **'CAMERA & OVERLAY'**
  String get settingsCameraSection;

  /// No description provided for @settingsGridLines.
  ///
  /// In en, this message translates to:
  /// **'Camera Grid Lines'**
  String get settingsGridLines;

  /// No description provided for @settingsGridLinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assist with photo composition'**
  String get settingsGridLinesSubtitle;

  /// No description provided for @settingsWatermarkOverlay.
  ///
  /// In en, this message translates to:
  /// **'GPS Watermark Overlay'**
  String get settingsWatermarkOverlay;

  /// No description provided for @settingsWatermarkOverlaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Burn data directly into photo'**
  String get settingsWatermarkOverlaySubtitle;

  /// No description provided for @settingsDataFields.
  ///
  /// In en, this message translates to:
  /// **'DATA FIELDS VISIBILITY'**
  String get settingsDataFields;

  /// No description provided for @settingsFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get settingsFullAddress;

  /// No description provided for @settingsGpsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates'**
  String get settingsGpsCoordinates;

  /// No description provided for @settingsCompassHeading.
  ///
  /// In en, this message translates to:
  /// **'Compass & Heading'**
  String get settingsCompassHeading;

  /// No description provided for @settingsDateTimeStamp.
  ///
  /// In en, this message translates to:
  /// **'Date & Time Stamp'**
  String get settingsDateTimeStamp;

  /// No description provided for @settingsDisplayFormats.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY FORMATS'**
  String get settingsDisplayFormats;

  /// No description provided for @settingsDateDisplay.
  ///
  /// In en, this message translates to:
  /// **'Date Display'**
  String get settingsDateDisplay;

  /// No description provided for @settingsCoordPrecision.
  ///
  /// In en, this message translates to:
  /// **'Coordinate Precision'**
  String get settingsCoordPrecision;

  /// No description provided for @settingsAltitudeDistance.
  ///
  /// In en, this message translates to:
  /// **'Altitude & Distance'**
  String get settingsAltitudeDistance;

  /// No description provided for @settingsStorageSection.
  ///
  /// In en, this message translates to:
  /// **'STORAGE & DATA'**
  String get settingsStorageSection;

  /// No description provided for @settingsExportGpsData.
  ///
  /// In en, this message translates to:
  /// **'Export GPS Data'**
  String get settingsExportGpsData;

  /// No description provided for @settingsExportGpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GPX, KML, or CSV format'**
  String get settingsExportGpsSubtitle;

  /// No description provided for @settingsClearPhotos.
  ///
  /// In en, this message translates to:
  /// **'Clear All Photos'**
  String get settingsClearPhotos;

  /// No description provided for @settingsClearPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Safe permanent deletion'**
  String get settingsClearPhotosSubtitle;

  /// No description provided for @settingsLegalSection.
  ///
  /// In en, this message translates to:
  /// **'LEGAL & PRIVACY'**
  String get settingsLegalSection;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPermissionsSection.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM PERMISSIONS'**
  String get settingsPermissionsSection;

  /// No description provided for @settingsManagePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage Permissions'**
  String get settingsManagePermissions;

  /// No description provided for @settingsManagePermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get settingsManagePermissionsSubtitle;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'ABOUT GEOCAM PRO'**
  String get settingsAboutSection;

  /// No description provided for @settingsUpgradePremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get settingsUpgradePremium;

  /// No description provided for @settingsUpgradePremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock tactical map styles'**
  String get settingsUpgradePremiumSubtitle;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// No description provided for @settingsExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get settingsExporting;

  /// No description provided for @settingsExportGpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Export GPS Data'**
  String get settingsExportGpsTitle;

  /// No description provided for @settingsExportLocations.
  ///
  /// In en, this message translates to:
  /// **'Export {count} photo locations'**
  String settingsExportLocations(int count);

  /// No description provided for @settingsGpxFile.
  ///
  /// In en, this message translates to:
  /// **'GPX File'**
  String get settingsGpxFile;

  /// No description provided for @settingsGpxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For GPS devices & mapping apps'**
  String get settingsGpxSubtitle;

  /// No description provided for @settingsKmlFile.
  ///
  /// In en, this message translates to:
  /// **'KML File'**
  String get settingsKmlFile;

  /// No description provided for @settingsKmlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For Google Earth'**
  String get settingsKmlSubtitle;

  /// No description provided for @settingsCsvFile.
  ///
  /// In en, this message translates to:
  /// **'CSV Spreadsheet'**
  String get settingsCsvFile;

  /// No description provided for @settingsCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For Excel & data analysis'**
  String get settingsCsvSubtitle;

  /// No description provided for @settingsClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Photos'**
  String get settingsClearAllTitle;

  /// No description provided for @settingsClearAllMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete all {count} photos? This cannot be undone.'**
  String settingsClearAllMessage(int count);

  /// No description provided for @settingsClearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get settingsClearAllConfirm;

  /// No description provided for @settingsAllPhotosDeleted.
  ///
  /// In en, this message translates to:
  /// **'All photos deleted'**
  String get settingsAllPhotosDeleted;

  /// No description provided for @settingsExportedTo.
  ///
  /// In en, this message translates to:
  /// **'Exported to {format}'**
  String settingsExportedTo(String format);

  /// No description provided for @settingsNoPhotosExport.
  ///
  /// In en, this message translates to:
  /// **'No photos to export'**
  String get settingsNoPhotosExport;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get settingsExportFailed;

  /// No description provided for @settingsShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get settingsShareAction;

  /// No description provided for @templateDataFields.
  ///
  /// In en, this message translates to:
  /// **'DATA FIELDS VISIBILITY'**
  String get templateDataFields;

  /// No description provided for @templateFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get templateFullAddress;

  /// No description provided for @templateGpsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates'**
  String get templateGpsCoordinates;

  /// No description provided for @templateCompassHeading.
  ///
  /// In en, this message translates to:
  /// **'Compass & Heading'**
  String get templateCompassHeading;

  /// No description provided for @templateDateTimeStamp.
  ///
  /// In en, this message translates to:
  /// **'Date & Time Stamp'**
  String get templateDateTimeStamp;

  /// No description provided for @templateDisplayFormats.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY FORMATS'**
  String get templateDisplayFormats;

  /// No description provided for @templateDateDisplay.
  ///
  /// In en, this message translates to:
  /// **'Date Display'**
  String get templateDateDisplay;

  /// No description provided for @templateCoordPrecision.
  ///
  /// In en, this message translates to:
  /// **'Coordinate Precision'**
  String get templateCoordPrecision;

  /// No description provided for @templateApplyBtn.
  ///
  /// In en, this message translates to:
  /// **'APPLY TEMPLATE'**
  String get templateApplyBtn;

  /// No description provided for @templateSettingsApplied.
  ///
  /// In en, this message translates to:
  /// **'Professional settings applied'**
  String get templateSettingsApplied;

  /// No description provided for @templateUnlockPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium Styles'**
  String get templateUnlockPremium;

  /// No description provided for @templateUnlockMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch a quick ad to unlock all premium template styles for 24 hours!'**
  String get templateUnlockMessage;

  /// No description provided for @templateWatchAd.
  ///
  /// In en, this message translates to:
  /// **'WATCH AD'**
  String get templateWatchAd;

  /// No description provided for @templatePremiumUnlocked.
  ///
  /// In en, this message translates to:
  /// **'🎉 Premium Styles unlocked for 24 hours!'**
  String get templatePremiumUnlocked;

  /// No description provided for @templateAdNotReady.
  ///
  /// In en, this message translates to:
  /// **'Ad not ready, please try again.'**
  String get templateAdNotReady;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'id', 'ru', 'tl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ru':
      return AppLocalizationsRu();
    case 'tl':
      return AppLocalizationsTl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
