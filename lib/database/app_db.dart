import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDB {
  AppDB._();
  static final AppDB instance = AppDB._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<List<Map<String, Object?>>> getAllUsers() async {
    final database = await db;
    return database.query('users', orderBy: 'id DESC');
  }

  Future<Database> _init() async {
  if (kIsWeb) {
    throw UnsupportedError('sqflite/SQLite is not supported on Web.');
  }

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'login_secure.db');

  return openDatabase(
    path,
    version: 6, // 🔴 IMPORTANT: INCREASE VERSION
    onCreate: (db, version) async {
      // USERS TABLE
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL
        )
      ''');

      // 🔐 OTP TABLE (REQUIRED)
      await db.execute('''
        CREATE TABLE otp_codes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL,
          code TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL,
          used INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_otp_email ON otp_codes(email)',
      );
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // SAFELY CREATE OTP TABLE IF MISSING
      await db.execute('''
        CREATE TABLE IF NOT EXISTS otp_codes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL,
          code TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL,
          used INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_otp_email ON otp_codes(email)',
        );
      },
    );
  }


  // ============ USER METHODS (UNCHANGED) ============

  Future<int> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final database = await db;
    return database.insert('users', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Map<String, Object?>?> loginByUsername(
    String username,
    String password,
  ) async {
    final database = await db;
    final res = await database.query(
      'users',
      where: 'name = ? AND password = ?',
      whereArgs: [username.trim(), password],
      limit: 1,
    );
    return res.isEmpty ? null : res.first;
  }

  Future<Map<String, Object?>?> getUserByEmail(String email) async {
    final database = await db;
    final res = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim()],
      limit: 1,
    );
    return res.isEmpty ? null : res.first;
  }

  Future<Map<String, Object?>?> getUserByUsername(String username) async {
    final database = await db;
    final res = await database.query(
      'users',
      where: 'name = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    return res.isEmpty ? null : res.first;
  }

  Future<int> updatePassword(String email, String newPassword) async {
    final database = await db;
    return database.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email.trim()],
    );
  }

  Future<int> deleteUser(String email) async {
    final database = await db;
    return database.delete(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim()],
    );
  }

  Future<int> updateUser(
    String oldEmail,
    String newName,
    String newEmail,
  ) async {
    final database = await db;
    return database.update(
      'users',
      {'name': newName, 'email': newEmail},
      where: 'email = ?',
      whereArgs: [oldEmail.trim()],
    );
  }

  // ============ OTP METHODS ============

    Future<void> saveOtp({
      required String email,
      required String code,
      Duration ttl = const Duration(minutes: 5),
    }) async {
      final database = await db;

      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt =
          DateTime.now().add(ttl).millisecondsSinceEpoch;

      // Remove old OTPs for this email
      await database.delete(
        'otp_codes',
        where: 'email = ?',
        whereArgs: [email.trim()],
      );

      // ✅ INSERT ALL REQUIRED FIELDS
      await database.insert(
        'otp_codes',
        {
          'email': email.trim(),
          'code': code,
          'created_at': now,
          'expires_at': expiresAt,
          'used': 0,
        },
      );
    }


  Future<bool> verifyOtp({required String email, required String input}) async {
    final database = await db;
    final res = await database.query(
      'otp_codes',
      where: 'email = ? AND code = ?',
      whereArgs: [email.trim(), input],
      limit: 1,
    );

    if (res.isNotEmpty) {
      // OTP verified, delete it
      await database.delete(
        'otp_codes',
        where: 'email = ?',
        whereArgs: [email.trim()],
      );
      return true;
    }
    return false;
  }
}
