import 'dart:math';
import 'package:flutter/foundation.dart';
import '../database/app_db.dart';

class OtpService {
  static String _generateOtp() =>
      (Random().nextInt(900000) + 100000).toString();

  // ================= SEND OTP =================
  static Future<bool> sendOtp(String email) async {
    try {
      final otp = _generateOtp();

      // Save OTP
      await AppDB.instance.saveOtp(email: email, code: otp);

      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║          🔐 OTP FOR TESTING            ║');
      debugPrint('╠════════════════════════════════════════╣');
      debugPrint('║  Email: $email');
      debugPrint('║  OTP Code: $otp');
      debugPrint('╚════════════════════════════════════════╝');

      return true;
    } catch (e) {
      debugPrint(' OTP generation error: $e');
      return false;
    }
  }

  // ================= VERIFY OTP =================
  static Future<bool> verifyOtp(String email, String input) async {
    return AppDB.instance.verifyOtp(email: email, input: input);
  }
}
