import 'dart:math';
import 'package:flutter/foundation.dart';
import '../database/app_db.dart';

class OtpService {
  static String generate6() => (Random().nextInt(900000) + 100000).toString();

  static Future<bool> sendOtp(String email) async {
    try {
      final otp = generate6();

      // Save OTP to database
      await AppDB.instance.saveOtp(email: email, code: otp);

      // Print OTP to terminal only
      debugPrint("════════════════════════════════════════");
      debugPrint("📧 OTP FOR: $email");
      debugPrint("🔐 OTP CODE: $otp");
      debugPrint("════════════════════════════════════════");

      return true;
    } catch (e) {
      debugPrint("❌ Error in sendOtp: $e");
      return false;
    }
  }

  static Future<bool> verifyOtp(String email, String input) async {
    try {
      final isValid = await AppDB.instance.verifyOtp(
        email: email,
        input: input,
      );
      if (isValid) {
        debugPrint("✅ OTP verified for $email");
      } else {
        debugPrint("❌ OTP verification failed for $email");
      }
      return isValid;
    } catch (e) {
      debugPrint("❌ Error verifying OTP: $e");
      return false;
    }
  }
}
