import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/photo_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  
  // Stream to notify UI of data changes
  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onChange => _changeController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'geocam.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        speed REAL,
        heading REAL,
        address TEXT,
        capturedAt TEXT NOT NULL,
        temperature REAL,
        weatherCondition TEXT,
        weatherIcon TEXT,
        humidity INTEGER,
        windSpeed REAL
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_photos_capturedAt ON photos(capturedAt DESC)');
    await db.execute('CREATE INDEX idx_photos_location ON photos(latitude, longitude)');
  }

  /// Insert a new photo
  Future<int> insertPhoto(Photo photo) async {
    final db = await database;
    final id = await db.insert('photos', photo.toMap());
    _changeController.add(null); // Notify listeners
    return id;
  }

  /// Get all photos ordered by capture date (newest first)
  Future<List<Photo>> getAllPhotos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      orderBy: 'capturedAt DESC',
    );
    return List.generate(maps.length, (i) => Photo.fromMap(maps[i]));
  }

  /// Get photos for a specific date
  Future<List<Photo>> getPhotosByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'capturedAt >= ? AND capturedAt < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'capturedAt DESC',
    );
    return List.generate(maps.length, (i) => Photo.fromMap(maps[i]));
  }

  /// Get photos within a geographic bounding box
  Future<List<Photo>> getPhotosInBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?',
      whereArgs: [minLat, maxLat, minLon, maxLon],
    );
    return List.generate(maps.length, (i) => Photo.fromMap(maps[i]));
  }

  /// Get a single photo by ID
  Future<Photo?> getPhoto(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Photo.fromMap(maps.first);
  }

  /// Update a photo
  Future<int> updatePhoto(Photo photo) async {
    final db = await database;
    final count = await db.update(
      'photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
    if (count > 0) _changeController.add(null);
    return count;
  }

  /// Delete a photo
  Future<int> deletePhoto(int id) async {
    final db = await database;
    final count = await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count > 0) _changeController.add(null);
    return count;
  }

  /// Get photo count
  Future<int> getPhotoCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM photos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get photos grouped by date for gallery display
  Future<Map<DateTime, List<Photo>>> getPhotosGroupedByDate() async {
    final photos = await getAllPhotos();
    final Map<DateTime, List<Photo>> grouped = {};

    for (final photo in photos) {
      final dateKey = DateTime(
        photo.capturedAt.year,
        photo.capturedAt.month,
        photo.capturedAt.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(photo);
    }

    return grouped;
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
