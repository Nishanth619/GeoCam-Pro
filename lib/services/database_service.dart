import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/photo_model.dart';
import '../models/project.dart';

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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// v1 → v2: projects, offline geocode cache, photo project/pending columns.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE photos ADD COLUMN project_id TEXT');
      await db.execute(
          'ALTER TABLE photos ADD COLUMN geocode_pending INTEGER NOT NULL DEFAULT 0');
      await _createV2Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS geocode_cache (
        lat_key REAL NOT NULL,
        lng_key REAL NOT NULL,
        address TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        PRIMARY KEY (lat_key, lng_key)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_photos_project ON photos(project_id)');
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
        windSpeed REAL,
        project_id TEXT,
        geocode_pending INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_photos_capturedAt ON photos(capturedAt DESC)');
    await db.execute('CREATE INDEX idx_photos_location ON photos(latitude, longitude)');
    await _createV2Tables(db);
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

  /// Get the file paths of all stored photos
  Future<List<String>> getAllPhotoPaths() async {
    final db = await database;
    final result = await db.query('photos', columns: ['imagePath']);
    return result.map((row) => row['imagePath'] as String).toList();
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

  // ============= Projects =============

  Future<Project> createProject(String name, int color) async {
    final db = await database;
    final project = Project(
      id: Project.generateId(),
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
    );
    await db.insert('projects', project.toMap());
    _changeController.add(null);
    return project;
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final maps = await db.query('projects', orderBy: 'created_at ASC');
    return maps.map(Project.fromMap).toList();
  }

  Future<Project?> getProjectById(String id) async {
    final db = await database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Project.fromMap(maps.first);
  }

  Future<void> renameProject(String id, String name) async {
    final db = await database;
    await db.update('projects', {'name': name.trim()},
        where: 'id = ?', whereArgs: [id]);
    _changeController.add(null);
  }

  /// Deletes the project. Its photos are kept and become unassigned.
  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('photos', {'project_id': null},
          where: 'project_id = ?', whereArgs: [id]);
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
    _changeController.add(null);
  }

  /// Assigns photos to a project (null = remove from any project).
  Future<void> assignPhotosToProject(List<int> photoIds, String? projectId) async {
    if (photoIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(photoIds.length, '?').join(',');
    await db.update('photos', {'project_id': projectId},
        where: 'id IN ($placeholders)', whereArgs: photoIds);
    _changeController.add(null);
  }

  Future<void> assignPhotoToProject(int photoId, String? projectId) =>
      assignPhotosToProject([photoId], projectId);

  Future<List<Photo>> getPhotosByProject(String projectId) async {
    final db = await database;
    final maps = await db.query('photos',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'capturedAt DESC');
    return maps.map(Photo.fromMap).toList();
  }

  // ============= Offline geocoding =============

  static double _geoKey(double v) => double.parse(v.toStringAsFixed(4));

  Future<void> cacheAddress(double lat, double lng, String address) async {
    final db = await database;
    await db.insert(
      'geocode_cache',
      {
        'lat_key': _geoKey(lat),
        'lng_key': _geoKey(lng),
        'address': address,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cached address for the ~11 m cell around (lat, lng), or null if absent
  /// or older than [maxAge] (pass null to accept any age).
  Future<String?> getCachedAddress(double lat, double lng,
      {Duration? maxAge = const Duration(days: 30)}) async {
    final db = await database;
    final maps = await db.query('geocode_cache',
        columns: ['address', 'cached_at'],
        where: 'lat_key = ? AND lng_key = ?',
        whereArgs: [_geoKey(lat), _geoKey(lng)]);
    if (maps.isEmpty) return null;
    if (maxAge != null) {
      final cachedAt =
          DateTime.fromMillisecondsSinceEpoch(maps.first['cached_at'] as int);
      if (DateTime.now().difference(cachedAt) > maxAge) return null;
    }
    return maps.first['address'] as String;
  }

  Future<List<Photo>> getGeocodePendingPhotos() async {
    final db = await database;
    final maps = await db.query('photos', where: 'geocode_pending = 1');
    return maps.map(Photo.fromMap).toList();
  }

  /// Sets a resolved address and clears the pending flag.
  Future<void> resolvePhotoAddress(int photoId, String address) async {
    final db = await database;
    await db.update('photos', {'address': address, 'geocode_pending': 0},
        where: 'id = ?', whereArgs: [photoId]);
    _changeController.add(null);
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
