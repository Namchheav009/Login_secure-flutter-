import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'reset_pw.dart';
import 'createaccount.dart';
import 'home.dart';
import 'database/app_db.dart';
import 'widgets/custom_alert.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;
  bool _loading = false;

  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  // ================= NORMAL LOGIN =================

  Future<void> _login() async {
    final username = _usernameC.text.trim();
    final password = _passwordC.text;

    if (username.isEmpty || password.isEmpty) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Warning',
        message: 'Username and password are required',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await AppDB.instance.loginByUsername(username, password);

      if (!mounted) return;
      setState(() => _loading = false);

      if (user != null) {
        CustomAlert.show(
          context: context,
          type: AlertType.success,
          title: 'Welcome',
          message: 'Login successful!',
          onOk: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    HomeScreen(currentEmail: user['email'] as String?),
              ),
            );
          },
        );
      } else {
        CustomAlert.show(
          context: context,
          type: AlertType.error,
          title: 'Login Failed',
          message: 'Wrong username or password',
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  // ================= GOOGLE SIGN IN =================

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);

    try {
     
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final email = googleUser.email;

      final user = await AppDB.instance.getUserByEmail(email);

      setState(() => _loading = false);

      if (user == null) {
        CustomAlert.show(
          context: context,
          type: AlertType.error,
          title: 'Account not found',
          message:
              'This Google account is not registered. Please sign up first.',
        );
        return;
      }

      CustomAlert.show(
        context: context,
        type: AlertType.success,
        title: 'Welcome',
        message: 'Signed in with Google!',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(currentEmail: email)),
          );
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Google Sign-In Error',
        message: e.toString(),
      );
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/login.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Sign in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 40),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            _inputField(
                              controller: _usernameC,
                              icon: Icons.person_outline,
                              hint: 'Username',
                            ),

                            const SizedBox(height: 16),

                            _passwordField(controller: _passwordC),

                            const SizedBox(height: 2),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResetPw(
                                        email: _usernameC.text.trim(),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // SIGN IN BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.35,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  _loading ? 'SIGNING IN...' : 'SIGN IN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            const Text(
                              'Or',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),

                            // GOOGLE SIGN IN
                            GestureDetector(
                              onTap: _loading ? null : _loginWithGoogle,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white.withOpacity(0.18),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/google.svg',
                                      height: 20,
                                    ),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateAccountScreen(),
                            ),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Color.fromARGB(255, 221, 225, 34),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _passwordField({required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
        hintText: 'Password',
        hintStyle: const TextStyle(color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
