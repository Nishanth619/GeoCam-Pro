// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'GeoCam Pro';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get retry => 'Повторить';

  @override
  String get delete => 'Удалить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get done => 'Готово';

  @override
  String get share => 'Поделиться';

  @override
  String get settings => 'Настройки';

  @override
  String get next => 'Далее';

  @override
  String get skip => 'Пропустить';

  @override
  String get getStarted => 'Начать';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get noGpsSignal => 'GPS сигнал...';

  @override
  String get acquiringLocation => 'Получение местоположения...';

  @override
  String get manualLocation => 'Ручное местоположение';

  @override
  String get gpsManual => 'РУЧНОЕ';

  @override
  String get cameraTitle => 'GeoCam Pro';

  @override
  String get cameraImportPhoto => 'Импорт фото';

  @override
  String get cameraFlashOff => 'Вспышка выкл.';

  @override
  String get cameraSwitching => 'Переключение камеры...';

  @override
  String get cameraCaptureError =>
      'Не удалось сделать снимок. Повторите попытку.';

  @override
  String get editLocationTitle => 'Изменить местоположение';

  @override
  String get editLocationSearch => 'Поиск места или адреса...';

  @override
  String get editLocationConfirm => 'ПОДТВЕРДИТЬ МЕСТОПОЛОЖЕНИЕ';

  @override
  String get editLocationUseGps => 'ИСПОЛЬЗОВАТЬ GPS';

  @override
  String get editLocationManualActive => 'РУЧНОЙ РЕЖИМ';

  @override
  String get editLocationSearchingAddress => 'Поиск адреса…';

  @override
  String get editLocationGpsNotAvailable => 'GPS позиция ещё недоступна.';

  @override
  String get editLocationAdNotReady => 'Реклама не готова. Попробуйте позже.';

  @override
  String get editLocationWatchAd =>
      'СМОТРЕТЬ РЕКЛАМУ ДЛЯ УСТАНОВКИ МЕСТОПОЛОЖЕНИЯ';

  @override
  String get editLocationFindingAddress => 'Поиск адреса…';

  @override
  String get importTitle => 'Импорт и геотег';

  @override
  String get importChoosePhoto => 'Нажмите, чтобы выбрать фото';

  @override
  String get importChoosePhotoHint => 'Любое фото из вашей галереи';

  @override
  String get importChangePhoto => 'Нажмите, чтобы изменить фото';

  @override
  String get importNoLocation => 'Нет местоположения';

  @override
  String get importLocationSet => 'Местоположение задано';

  @override
  String get importSetLocationBtn => 'Указать место на карте';

  @override
  String get importChangeLocationBtn => 'Изменить место на карте';

  @override
  String get importWatermarkOptions => 'ПАРАМЕТРЫ ВОДЯНОГО ЗНАКА';

  @override
  String get importShowMiniMap => 'Показать мини-карту';

  @override
  String get importShowAddress => 'Показать адрес';

  @override
  String get importShowCoordinates => 'Показать координаты';

  @override
  String get importShowDate => 'Показать дату и время';

  @override
  String get importSaveBtn => 'ГЕОТЕГ И СОХРАНИТЬ В ГАЛЕРЕЮ';

  @override
  String get importSaving => 'СОХРАНЕНИЕ…';

  @override
  String get importSuccess => 'Фото с геотегом сохранено в галерее!';

  @override
  String importSaveFailed(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String get importGpsFromPhoto => 'GPS из фото (нажмите для изменения)';

  @override
  String get galleryTitle => 'Галерея';

  @override
  String get galleryEmpty => 'Фотографий пока нет';

  @override
  String get galleryEmptyHint =>
      'Сделайте снимок в GeoCam Pro, чтобы он появился здесь';

  @override
  String get galleryDeleteTitle => 'Удалить фото';

  @override
  String get galleryDeleteMessage => 'Вы уверены, что хотите удалить это фото?';

  @override
  String galleryPhotosCount(int count) {
    return '$count фото';
  }

  @override
  String get sharePhoto => 'Поделиться фото';

  @override
  String get sharePhotoSubtitle => 'Отправить файл изображения';

  @override
  String get shareWithGps => 'Поделиться с GPS данными';

  @override
  String get shareWithGpsSubtitle => 'Включить информацию о местоположении';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageAuto => 'Авто (язык устройства)';

  @override
  String get settingsUnits => 'Единицы';

  @override
  String get settingsMetric => 'Метрические';

  @override
  String get settingsImperial => 'Имперские';

  @override
  String get settingsCelsius => 'Цельсий';

  @override
  String get settingsFahrenheit => 'Фаренгейт';

  @override
  String get settingsTemperature => 'Температура';

  @override
  String get onboardingTitle1 => 'Профессиональная GPS камера';

  @override
  String get onboardingDesc1 =>
      'Снимайте фотографии с автоматически встраиваемыми GPS координатами';

  @override
  String get onboardingTitle2 => 'Умное редактирование местоположения';

  @override
  String get onboardingDesc2 =>
      'Ищите любое место в мире и устанавливайте его как GPS-тег фото';

  @override
  String get onboardingTitle3 => 'Профессиональные водяные знаки';

  @override
  String get onboardingDesc3 =>
      'Добавляйте профессиональные GPS водяные знаки со спутниковыми картами';

  @override
  String get permissionsTitle => 'Требуются разрешения';

  @override
  String get permissionsCamera => 'Камера';

  @override
  String get permissionsLocation => 'Местоположение';

  @override
  String get permissionsStorage => 'Хранилище';

  @override
  String get permissionsGrantAll => 'Разрешить всё';

  @override
  String get premiumTitle => 'GeoCam Pro';

  @override
  String get premiumUnlockBtn => 'Разблокировать Premium';

  @override
  String get premiumWatchAd => 'Смотреть рекламу для бесплатного доступа';

  @override
  String get templateTitle => 'Шаблон водяного знака';

  @override
  String get templateMapType => 'Тип карты';

  @override
  String get templateSatellite => 'Спутник';

  @override
  String get templateTerrain => 'Рельеф';

  @override
  String get templateNormal => 'Обычная';

  @override
  String get templateHybrid => 'Гибрид';

  @override
  String get editLocationClearBtn => 'ОЧИСТИТЬ';

  @override
  String get galleryCancelBtn => 'Отмена';

  @override
  String get galleryDeleteBtn => 'Удалить';

  @override
  String get galleryShareBtn => 'Поделиться';

  @override
  String get galleryCapturedWith => 'Снято с GPS';

  @override
  String get photoDeleteTitle => 'Удалить фото';

  @override
  String get photoDeleteMessage => 'Вы уверены, что хотите удалить это фото?';

  @override
  String get photoImageNotFound => 'Изображение не найдено';

  @override
  String get photoShareTitle => 'Поделиться фото';

  @override
  String get photoShareSubtitle => 'Отправить файл изображения';

  @override
  String get photoShareWithGps => 'Поделиться с GPS данными';

  @override
  String get photoShareWithGpsSubtitle =>
      'Включить информацию о местоположении';

  @override
  String get photoCoordscopied => 'Координаты скопированы';

  @override
  String get settingsCameraSection => 'КАМЕРА И ОВЕРЛЕЙ';

  @override
  String get settingsGridLines => 'Сетка камеры';

  @override
  String get settingsGridLinesSubtitle => 'Помощь в компоновке снимка';

  @override
  String get settingsWatermarkOverlay => 'GPS-водяной знак';

  @override
  String get settingsWatermarkOverlaySubtitle => 'Встроить данные в фото';

  @override
  String get settingsDataFields => 'ВИДИМОСТЬ ПОЛЕЙ ДАННЫХ';

  @override
  String get settingsFullAddress => 'Полный адрес';

  @override
  String get settingsGpsCoordinates => 'GPS-координаты';

  @override
  String get settingsCompassHeading => 'Компас и направление';

  @override
  String get settingsDateTimeStamp => 'Дата и время';

  @override
  String get settingsDisplayFormats => 'ФОРМАТЫ ОТОБРАЖЕНИЯ';

  @override
  String get settingsDateDisplay => 'Формат даты';

  @override
  String get settingsCoordPrecision => 'Точность координат';

  @override
  String get settingsAltitudeDistance => 'Высота и расстояние';

  @override
  String get settingsStorageSection => 'ХРАНИЛИЩЕ И ДАННЫЕ';

  @override
  String get settingsExportGpsData => 'Экспорт GPS данных';

  @override
  String get settingsExportGpsSubtitle => 'Форматы GPX, KML или CSV';

  @override
  String get settingsClearPhotos => 'Очистить все фото';

  @override
  String get settingsClearPhotosSubtitle => 'Безвозвратное удаление';

  @override
  String get settingsLegalSection => 'ПРАВОВАЯ ИНФОРМАЦИЯ';

  @override
  String get settingsTerms => 'Условия использования';

  @override
  String get settingsPrivacy => 'Политика конфиденциальности';

  @override
  String get settingsPermissionsSection => 'СИСТЕМНЫЕ РАЗРЕШЕНИЯ';

  @override
  String get settingsManagePermissions => 'Управление разрешениями';

  @override
  String get settingsManagePermissionsSubtitle => 'Открыть системные настройки';

  @override
  String get settingsAboutSection => 'О GEOCAM PRO';

  @override
  String get settingsUpgradePremium => 'Перейти на Premium';

  @override
  String get settingsUpgradePremiumSubtitle =>
      'Разблокировать тактические стили карт';

  @override
  String get settingsAppVersion => 'Версия приложения';

  @override
  String get settingsExporting => 'Экспорт...';

  @override
  String get settingsExportGpsTitle => 'Экспорт GPS данных';

  @override
  String settingsExportLocations(int count) {
    return 'Экспорт $count локаций';
  }

  @override
  String get settingsGpxFile => 'Файл GPX';

  @override
  String get settingsGpxSubtitle =>
      'Для GPS-устройств и картографических приложений';

  @override
  String get settingsKmlFile => 'Файл KML';

  @override
  String get settingsKmlSubtitle => 'Для Google Earth';

  @override
  String get settingsCsvFile => 'Таблица CSV';

  @override
  String get settingsCsvSubtitle => 'Для Excel и анализа данных';

  @override
  String get settingsClearAllTitle => 'Очистить все фото';

  @override
  String settingsClearAllMessage(int count) {
    return 'Удалить все $count фото? Это действие нельзя отменить.';
  }

  @override
  String get settingsClearAllConfirm => 'Удалить всё';

  @override
  String get settingsAllPhotosDeleted => 'Все фото удалены';

  @override
  String settingsExportedTo(String format) {
    return 'Экспортировано в $format';
  }

  @override
  String get settingsNoPhotosExport => 'Нет фото для экспорта';

  @override
  String get settingsExportFailed => 'Ошибка экспорта';

  @override
  String get settingsShareAction => 'Поделиться';

  @override
  String get templateDataFields => 'ВИДИМОСТЬ ПОЛЕЙ ДАННЫХ';

  @override
  String get templateFullAddress => 'Полный адрес';

  @override
  String get templateGpsCoordinates => 'GPS-координаты';

  @override
  String get templateCompassHeading => 'Компас и направление';

  @override
  String get templateDateTimeStamp => 'Дата и время';

  @override
  String get templateDisplayFormats => 'ФОРМАТЫ ОТОБРАЖЕНИЯ';

  @override
  String get templateDateDisplay => 'Формат даты';

  @override
  String get templateCoordPrecision => 'Точность координат';

  @override
  String get templateApplyBtn => 'ПРИМЕНИТЬ ШАБЛОН';

  @override
  String get templateSettingsApplied => 'Профессиональные настройки применены';

  @override
  String get templateUnlockPremium => 'Разблокировать Premium стили';

  @override
  String get templateUnlockMessage =>
      'Посмотрите короткую рекламу, чтобы разблокировать все premium стили шаблонов на 24 часа!';

  @override
  String get templateWatchAd => 'СМОТРЕТЬ РЕКЛАМУ';

  @override
  String get templatePremiumUnlocked =>
      '🎉 Premium стили разблокированы на 24 часа!';

  @override
  String get templateAdNotReady => 'Реклама не готова, попробуйте ещё раз.';
}
