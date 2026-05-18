// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'GeoCam Pro';

  @override
  String get back => 'Zurück';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get retry => 'Wiederholen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get done => 'Fertig';

  @override
  String get share => 'Teilen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get next => 'Weiter';

  @override
  String get skip => 'Überspringen';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get noGpsSignal => 'GPS-Signal...';

  @override
  String get acquiringLocation => 'Standort wird ermittelt...';

  @override
  String get manualLocation => 'Manueller Standort';

  @override
  String get gpsManual => 'MANUELL';

  @override
  String get cameraTitle => 'GeoCam Pro';

  @override
  String get cameraImportPhoto => 'Foto importieren';

  @override
  String get cameraFlashOff => 'Blitz aus';

  @override
  String get cameraSwitching => 'Kamera wird gewechselt...';

  @override
  String get cameraCaptureError =>
      'Foto konnte nicht aufgenommen werden. Bitte erneut versuchen.';

  @override
  String get editLocationTitle => 'Standort bearbeiten';

  @override
  String get editLocationSearch => 'Ort oder Adresse suchen...';

  @override
  String get editLocationConfirm => 'STANDORT BESTÄTIGEN';

  @override
  String get editLocationUseGps => 'GPS VERWENDEN';

  @override
  String get editLocationManualActive => 'MANUELL AKTIV';

  @override
  String get editLocationSearchingAddress => 'Adresse wird gesucht…';

  @override
  String get editLocationGpsNotAvailable =>
      'GPS-Position noch nicht verfügbar.';

  @override
  String get editLocationAdNotReady =>
      'Anzeige nicht bereit. Bitte erneut versuchen.';

  @override
  String get editLocationWatchAd => 'WERBUNG ANSEHEN UM STANDORT ZU SETZEN';

  @override
  String get editLocationFindingAddress => 'Adresse wird ermittelt…';

  @override
  String get importTitle => 'Importieren & Geo-Tag';

  @override
  String get importChoosePhoto => 'Tippen um Foto auszuwählen';

  @override
  String get importChoosePhotoHint => 'Beliebiges Foto aus Ihrer Galerie';

  @override
  String get importChangePhoto => 'Tippen um Foto zu ändern';

  @override
  String get importNoLocation => 'Kein Standort';

  @override
  String get importLocationSet => 'Standort festgelegt';

  @override
  String get importSetLocationBtn => 'Standort auf Karte setzen';

  @override
  String get importChangeLocationBtn => 'Standort auf Karte ändern';

  @override
  String get importWatermarkOptions => 'WASSERZEICHEN-OPTIONEN';

  @override
  String get importShowMiniMap => 'Minikarte anzeigen';

  @override
  String get importShowAddress => 'Adresse anzeigen';

  @override
  String get importShowCoordinates => 'Koordinaten anzeigen';

  @override
  String get importShowDate => 'Datum & Uhrzeit anzeigen';

  @override
  String get importSaveBtn => 'GEO-TAG & IN GALERIE SPEICHERN';

  @override
  String get importSaving => 'WIRD GESPEICHERT…';

  @override
  String get importSuccess => 'Foto mit Geo-Tag in Galerie gespeichert!';

  @override
  String importSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get importGpsFromPhoto => 'GPS aus Foto (tippen zum Ändern)';

  @override
  String get galleryTitle => 'Galerie';

  @override
  String get galleryEmpty => 'Noch keine Fotos';

  @override
  String get galleryEmptyHint =>
      'Machen Sie ein Foto mit GeoCam Pro, um es hier zu sehen';

  @override
  String get galleryDeleteTitle => 'Foto löschen';

  @override
  String get galleryDeleteMessage =>
      'Möchten Sie dieses Foto wirklich löschen?';

  @override
  String galleryPhotosCount(int count) {
    return '$count Fotos';
  }

  @override
  String get sharePhoto => 'Foto teilen';

  @override
  String get sharePhotoSubtitle => 'Bilddatei teilen';

  @override
  String get shareWithGps => 'Mit GPS-Daten teilen';

  @override
  String get shareWithGpsSubtitle =>
      'Standortinformationen in Bildunterschrift einschließen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageAuto => 'Auto (Gerätesprache)';

  @override
  String get settingsUnits => 'Einheiten';

  @override
  String get settingsMetric => 'Metrisch';

  @override
  String get settingsImperial => 'Imperial';

  @override
  String get settingsCelsius => 'Celsius';

  @override
  String get settingsFahrenheit => 'Fahrenheit';

  @override
  String get settingsTemperature => 'Temperatur';

  @override
  String get onboardingTitle1 => 'Professionelle GPS-Kamera';

  @override
  String get onboardingDesc1 =>
      'Machen Sie Fotos mit automatisch eingebetteten GPS-Koordinaten';

  @override
  String get onboardingTitle2 => 'Intelligente Standortbearbeitung';

  @override
  String get onboardingDesc2 =>
      'Suchen Sie weltweit jeden Ort und setzen ihn als GPS-Tag Ihres Fotos';

  @override
  String get onboardingTitle3 => 'Professionelle Wasserzeichen';

  @override
  String get onboardingDesc3 =>
      'Fügen Sie professionelle GPS-Wasserzeichen mit Satelliten-Minikarten hinzu';

  @override
  String get permissionsTitle => 'Berechtigungen erforderlich';

  @override
  String get permissionsCamera => 'Kamera';

  @override
  String get permissionsLocation => 'Standort';

  @override
  String get permissionsStorage => 'Speicher';

  @override
  String get permissionsGrantAll => 'Alle Berechtigungen erteilen';

  @override
  String get premiumTitle => 'GeoCam Pro';

  @override
  String get premiumUnlockBtn => 'Premium freischalten';

  @override
  String get premiumWatchAd => 'Werbung ansehen für kostenlosen Zugang';

  @override
  String get templateTitle => 'Wasserzeichen-Vorlage';

  @override
  String get templateMapType => 'Kartentyp';

  @override
  String get templateSatellite => 'Satellit';

  @override
  String get templateTerrain => 'Gelände';

  @override
  String get templateNormal => 'Normal';

  @override
  String get templateHybrid => 'Hybrid';

  @override
  String get editLocationClearBtn => 'LÖSCHEN';

  @override
  String get galleryCancelBtn => 'Abbrechen';

  @override
  String get galleryDeleteBtn => 'Löschen';

  @override
  String get galleryShareBtn => 'Teilen';

  @override
  String get galleryCapturedWith => 'Mit GPS aufgenommen';

  @override
  String get photoDeleteTitle => 'Foto löschen';

  @override
  String get photoDeleteMessage => 'Möchten Sie dieses Foto wirklich löschen?';

  @override
  String get photoImageNotFound => 'Bild nicht gefunden';

  @override
  String get photoShareTitle => 'Foto teilen';

  @override
  String get photoShareSubtitle => 'Bilddatei teilen';

  @override
  String get photoShareWithGps => 'Mit GPS-Daten teilen';

  @override
  String get photoShareWithGpsSubtitle =>
      'Standortinfo in Bildunterschrift einfügen';

  @override
  String get photoCoordscopied => 'Koordinaten kopiert';

  @override
  String get settingsCameraSection => 'KAMERA & ÜBERLAGERUNG';

  @override
  String get settingsGridLines => 'Kameragitternetz';

  @override
  String get settingsGridLinesSubtitle => 'Hilft bei der Bildkomposition';

  @override
  String get settingsWatermarkOverlay => 'GPS-Wasserzeichen';

  @override
  String get settingsWatermarkOverlaySubtitle =>
      'Daten direkt ins Foto einbrennen';

  @override
  String get settingsDataFields => 'DATENFELDANZEIGE';

  @override
  String get settingsFullAddress => 'Vollständige Adresse';

  @override
  String get settingsGpsCoordinates => 'GPS-Koordinaten';

  @override
  String get settingsCompassHeading => 'Kompass & Richtung';

  @override
  String get settingsDateTimeStamp => 'Datum & Uhrzeit';

  @override
  String get settingsDisplayFormats => 'ANZEIGEFORMATE';

  @override
  String get settingsDateDisplay => 'Datumsanzeige';

  @override
  String get settingsCoordPrecision => 'Koordinatengenauigkeit';

  @override
  String get settingsAltitudeDistance => 'Höhe & Entfernung';

  @override
  String get settingsStorageSection => 'SPEICHER & DATEN';

  @override
  String get settingsExportGpsData => 'GPS-Daten exportieren';

  @override
  String get settingsExportGpsSubtitle => 'GPX, KML oder CSV Format';

  @override
  String get settingsClearPhotos => 'Alle Fotos löschen';

  @override
  String get settingsClearPhotosSubtitle => 'Sichere dauerhafte Löschung';

  @override
  String get settingsLegalSection => 'RECHT & DATENSCHUTZ';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String get settingsPrivacy => 'Datenschutzrichtlinie';

  @override
  String get settingsPermissionsSection => 'SYSTEMBERECHTIGUNGEN';

  @override
  String get settingsManagePermissions => 'Berechtigungen verwalten';

  @override
  String get settingsManagePermissionsSubtitle => 'Systemeinstellungen öffnen';

  @override
  String get settingsAboutSection => 'ÜBER GEOCAM PRO';

  @override
  String get settingsUpgradePremium => 'Auf Premium upgraden';

  @override
  String get settingsUpgradePremiumSubtitle =>
      'Taktische Kartenstile freischalten';

  @override
  String get settingsAppVersion => 'App-Version';

  @override
  String get settingsExporting => 'Wird exportiert...';

  @override
  String get settingsExportGpsTitle => 'GPS-Daten exportieren';

  @override
  String settingsExportLocations(int count) {
    return '$count Fotostandorte exportieren';
  }

  @override
  String get settingsGpxFile => 'GPX-Datei';

  @override
  String get settingsGpxSubtitle => 'Für GPS-Geräte & Karten-Apps';

  @override
  String get settingsKmlFile => 'KML-Datei';

  @override
  String get settingsKmlSubtitle => 'Für Google Earth';

  @override
  String get settingsCsvFile => 'CSV-Tabelle';

  @override
  String get settingsCsvSubtitle => 'Für Excel & Datenanalyse';

  @override
  String get settingsClearAllTitle => 'Alle Fotos löschen';

  @override
  String settingsClearAllMessage(int count) {
    return 'Alle $count Fotos löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get settingsClearAllConfirm => 'Alle löschen';

  @override
  String get settingsAllPhotosDeleted => 'Alle Fotos gelöscht';

  @override
  String settingsExportedTo(String format) {
    return 'Exportiert nach $format';
  }

  @override
  String get settingsNoPhotosExport => 'Keine Fotos zum Exportieren';

  @override
  String get settingsExportFailed => 'Export fehlgeschlagen';

  @override
  String get settingsShareAction => 'Teilen';

  @override
  String get templateDataFields => 'DATENFELDANZEIGE';

  @override
  String get templateFullAddress => 'Vollständige Adresse';

  @override
  String get templateGpsCoordinates => 'GPS-Koordinaten';

  @override
  String get templateCompassHeading => 'Kompass & Richtung';

  @override
  String get templateDateTimeStamp => 'Datum & Uhrzeit';

  @override
  String get templateDisplayFormats => 'ANZEIGEFORMATE';

  @override
  String get templateDateDisplay => 'Datumsanzeige';

  @override
  String get templateCoordPrecision => 'Koordinatengenauigkeit';

  @override
  String get templateApplyBtn => 'VORLAGE ANWENDEN';

  @override
  String get templateSettingsApplied =>
      'Professionelle Einstellungen angewendet';

  @override
  String get templateUnlockPremium => 'Premium-Stile freischalten';

  @override
  String get templateUnlockMessage =>
      'Sehen Sie eine kurze Werbung, um alle Premium-Vorlagenstile für 24 Stunden freizuschalten!';

  @override
  String get templateWatchAd => 'WERBUNG ANSEHEN';

  @override
  String get templatePremiumUnlocked =>
      '🎉 Premium-Stile für 24 Stunden freigeschaltet!';

  @override
  String get templateAdNotReady =>
      'Werbung nicht bereit, bitte erneut versuchen.';
}
