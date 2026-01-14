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

    // Desktop support
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'login_secure.db');

    debugPrint('Database path: $path');

    return openDatabase(
      path,
      version: 4,
      onCreate: (Database db, int version) async {
        debugPrint('Creating fresh database tables...');
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE NOT NULL,
              email TEXT UNIQUE NOT NULL,
              password TEXT NOT NULL
            )
          ''');
          debugPrint('✅ users table created');

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
          debugPrint('✅ otp_codes table created');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_otp_email ON otp_codes(email)',
          );
          debugPrint('✅ index created');
        } catch (e) {
          debugPrint('❌ Error creating tables: $e');
          rethrow;
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint(
          '🔄 Upgrading database from version $oldVersion to $newVersion',
        );
        try {
          await db.execute('DROP TABLE IF EXISTS otp_codes');
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('DROP INDEX IF EXISTS idx_otp_email');
          debugPrint('✅ Old tables dropped');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE NOT NULL,
              email TEXT UNIQUE NOT NULL,
              password TEXT NOT NULL
            )
          ''');
          debugPrint('✅ users table recreated');

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
          debugPrint('✅ otp_codes table recreated');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_otp_email ON otp_codes(email)',
          );
          debugPrint('✅ index recreated');
        } catch (e) {
          debugPrint('❌ Error upgrading database: $e');
          rethrow;
        }
      },
    );
  }

  // ============ USER METHODS ============

  Future<int> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final database = await db;
      final result = await database.insert('users', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      debugPrint('✅ User created with ID: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      rethrow;
    }
  }

  Future<Map<String, Object?>?> loginByUsername(
    String username,
    String password,
  ) async {
    try {
      final database = await db;
      final res = await database.query(
        'users',
        where: 'name = ? AND password = ?',
        whereArgs: [username.trim(), password],
        limit: 1,
      );
      debugPrint('✅ Login query executed for: $username');
      return res.isEmpty ? null : res.first;
    } catch (e) {
      debugPrint('❌ Error in loginByUsername: $e');
      rethrow;
    }
  }

  Future<Map<String, Object?>?> getUserByUsername(String username) async {
    try {
      final database = await db;
      final res = await database.query(
        'users',
        where: 'name = ?',
        whereArgs: [username.trim()],
        limit: 1,
      );
      debugPrint('✅ getUserByUsername found: ${res.isNotEmpty}');
      return res.isEmpty ? null : res.first;
    } catch (e) {
      debugPrint('❌ Error getting user by username: $e');
      rethrow;
    }
  }

  Future<Map<String, Object?>?> getUserByEmail(String email) async {
    try {
      final database = await db;
      final res = await database.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.trim()],
        limit: 1,
      );
      debugPrint('✅ getUserByEmail found: ${res.isNotEmpty}');
      return res.isEmpty ? null : res.first;
    } catch (e) {
      debugPrint('❌ Error getting user by email: $e');
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final database = await db;
      final res = await database.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email.trim(), password],
        limit: 1,
      );
      return res.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error in login: $e');
      rethrow;
    }
  }

  Future<int> updatePassword(String email, String newPassword) async {
    try {
      final database = await db;
      final result = await database.update(
        'users',
        {'password': newPassword},
        where: 'email = ?',
        whereArgs: [email.trim()],
      );
      debugPrint('✅ Password updated for: $email');
      return result;
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }

  Future<int> updateUser(
    String oldEmail,
    String newName,
    String newEmail,
  ) async {
    try {
      final database = await db;
      final result = await database.update(
        'users',
        {'name': newName.trim(), 'email': newEmail.trim()},
        where: 'email = ?',
        whereArgs: [oldEmail.trim()],
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      debugPrint('✅ User updated: $oldEmail -> $newEmail');
      return result;
    } catch (e) {
      debugPrint('❌ Error updating user: $e');
      rethrow;
    }
  }

  Future<int> deleteUser(String email) async {
    try {
      final database = await db;
      final result = await database.delete(
        'users',
        where: 'email = ?',
        whereArgs: [email.trim()],
      );
      debugPrint('✅ User deleted: $email');
      return result;
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // ============ OTP METHODS ============

  Future<void> saveOtp({
    required String email,
    required String code,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    try {
      final database = await db;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;

      await database.delete(
        'otp_codes',
        where: 'email = ?',
        whereArgs: [email.trim()],
      );

      await database.insert('otp_codes', {
        'email': email.trim(),
        'code': code,
        'created_at': now,
        'expires_at': expiresAt,
        'used': 0,
      });
      debugPrint('✅ OTP saved for: $email (Code: $code)');
    } catch (e) {
      debugPrint('❌ Error saving OTP: $e');
      rethrow;
    }
  }

  Future<Map<String, Object?>?> getOtpByEmail(String email) async {
    try {
      final database = await db;
      final res = await database.query(
        'otp_codes',
        where: 'email = ?',
        whereArgs: [email.trim()],
        orderBy: 'id DESC',
        limit: 1,
      );
      debugPrint('✅ getOtpByEmail found: ${res.isNotEmpty}');
      return res.isEmpty ? null : res.first;
    } catch (e) {
      debugPrint('❌ Error getting OTP: $e');
      rethrow;
    }
  }

  Future<bool> verifyOtp({required String email, required String input}) async {
    try {
      final database = await db;
      final row = await getOtpByEmail(email);
      if (row == null) {
        debugPrint('⚠️ No OTP found for: $email');
        return false;
      }

      final id = row['id'] as int;
      final code = row['code'] as String;
      final expiresAt = row['expires_at'] as int;
      final used = row['used'] as int;

      final now = DateTime.now().millisecondsSinceEpoch;

      if (used == 1) {
        debugPrint('⚠️ OTP already used for: $email');
        return false;
      }
      if (now > expiresAt) {
        debugPrint('⚠️ OTP expired for: $email');
        return false;
      }
      if (input.trim() != code) {
        debugPrint('⚠️ OTP mismatch. Expected: $code, Got: ${input.trim()}');
        return false;
      }

      await database.update(
        'otp_codes',
        {'used': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('✅ OTP verified for: $email');
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      rethrow;
    }
  }
}
