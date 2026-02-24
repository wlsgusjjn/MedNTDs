import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb 확인용
import 'package:image/image.dart' as img;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// [HistoryDatabase]
/// Manages local storage for medical diagnostic history.
/// Handles SQLite database operations and saves captured images to the local filesystem.
class HistoryDatabase {
  // Singleton instance for global access
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  HistoryDatabase._init();

  /// [Platform-Specific Path Configuration]
  /// Determines where to store images and the database file based on the OS.
  Future<String> get _safePath async {
    if (Platform.isWindows) {
      // Windows: Stores data in a 'diagnosed_data' folder within the project/executable directory.
      final baseDir = Directory.current.path;
      final targetPath = p.join(baseDir, 'diagnosed_data');
      final dir = Directory(targetPath);
      if (!dir.existsSync()) await dir.create(recursive: true);
      return targetPath;
    } else {
      // Android/iOS: Stores data in the app's official internal documents directory.
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetPath = p.join(appDocDir.path, 'diagnosed_data');
      final dir = Directory(targetPath);
      if (!dir.existsSync()) await dir.create(recursive: true);
      return targetPath;
    }
  }

  /// Returns the database instance, initializing it if it doesn't exist.
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Desktop initialization: FFI is required for SQLite to run on Windows/Linux.
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDB('medical_history.db');
    return _database!;
  }

  /// Opens the database file at the platform-safe path.
  Future<Database> _initDB(String fileName) async {
    final basePath = await _safePath;
    final dbPath = p.join(basePath, fileName);
    return await openDatabase(dbPath, version: 1, onCreate: _createDB);
  }

  /// Creates the 'history' table schema.
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        result TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  /// [Core Logic: Saving Diagnostic Records]
  /// Decodes raw bytes, applies platform-specific corrections (mirroring),
  /// saves the image as a physical file, and logs the metadata in SQLite.
  Future<void> saveRecord(Uint8List originalBytes, String result) async {
    if (originalBytes.isEmpty) return;

    final basePath = await _safePath;
    final fileName = "img_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final savedPath = p.join(basePath, fileName);

    try {
      // 1. Decode original bytes into an Image object
      img.Image? decodedImage = img.decodeImage(originalBytes);
      if (decodedImage == null) throw Exception("Failed to decode image");

      // 2. [Platform Correction] Handle Windows Laptop Webcam Mirroring.
      // Laptop webcams usually provide a mirrored 'selfie' view.
      // We flip it horizontally so the saved file matches a natural observation.
      if (Platform.isWindows) {
        decodedImage = img.flipHorizontal(decodedImage);
      }

      // 3. Re-encode the image as a high-quality JPG
      final jpgBytes = img.encodeJpg(decodedImage);

      // 4. Write the processed image to the filesystem
      await File(savedPath).writeAsBytes(jpgBytes);

      // 5. Insert metadata (file path, AI result, time) into the database
      final db = await database;
      await db.insert('history', {
        'imagePath': savedPath,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print("History Saved & Flipped: $savedPath");
    } catch (e) {
      print("error occur: $e");
    }
  }

  /// Retrieves all history records ordered by the most recent first.
  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await instance.database;
    return await db.query('history', orderBy: 'timestamp DESC');
  }

  /// Deletes a specific history record by ID.
  Future<void> deleteHistory(int id) async {
    final db = await instance.database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}