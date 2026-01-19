import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'sigin.dart';
import 'home.dart';
import 'database/app_db.dart';
import 'widgets/custom_alert.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _obscurePassword = true;
  bool _loading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  // ================= VALIDATION =================

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidUsername(String username) {
    return username.length >= 3 &&
        username.length <= 20 &&
        RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(username);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6 &&
        RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password);
  }

  // ================= EMAIL SIGN UP =================

  Future<void> _signUp() async {
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    final password = _passwordC.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Warning',
        message: 'All fields are required',
      );
      return;
    }

    if (!_isValidUsername(name)) {
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Invalid Username',
        message: '3–20 chars, letters & numbers only',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Invalid Email',
        message: 'Please enter a valid email address',
      );
      return;
    }

    if (!_isValidPassword(password)) {
      CustomAlert.show(
        context: context,
        type: AlertType.warning,
        title: 'Weak Password',
        message: 'At least 6 characters with letters & numbers',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (await AppDB.instance.getUserByUsername(name) != null) {
        setState(() => _loading = false);
        CustomAlert.show(
          context: context,
          type: AlertType.error,
          title: 'Oops...',
          message: 'Username already taken',
        );
        return;
      }

      if (await AppDB.instance.getUserByEmail(email) != null) {
        setState(() => _loading = false);
        CustomAlert.show(
          context: context,
          type: AlertType.error,
          title: 'Oops...',
          message: 'Email already registered',
        );
        return;
      }

      await AppDB.instance.createUser(
        name: name,
        email: email,
        password: password,
      );

      setState(() => _loading = false);

      CustomAlert.show(
        context: context,
        type: AlertType.success,
        title: 'Success',
        message: 'Account created successfully!',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(currentEmail: email),
            ),
          );
        },
      );
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

  // ================= GOOGLE SIGN UP =================

  Future<void> _signUpWithGoogle() async {
  setState(() => _loading = true);

  try {
  
    await _googleSignIn.signOut();

    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) {
      setState(() => _loading = false);
      return;
    }

    final email = googleUser.email;
    final name = googleUser.displayName ?? 'Google User';

    if (await AppDB.instance.getUserByEmail(email) != null) {
      setState(() => _loading = false);
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Oops...',
        message: 'Email already registered',
      );
      return;
    }

    await AppDB.instance.createUser(
      name: name,
      email: email,
      password: 'google_account',
    );

    setState(() => _loading = false);

    CustomAlert.show(
      context: context,
      type: AlertType.success,
      title: 'Success',
      message: 'Account created with Google!',
      onOk: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(currentEmail: email),
          ),
        );
      },
    );
    } catch (e) {
      setState(() => _loading = false);
      CustomAlert.show(
        context: context,
        type: AlertType.error,
        title: 'Google Error',
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
                  image: AssetImage('assets/create.png'),
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
                    'Create Account',
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
                            _input(_nameC, Icons.person, 'Username'),
                            const SizedBox(height: 16),
                            _input(
                              _emailC,
                              Icons.email,
                              'Email',
                              type: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _password(),
                            const SizedBox(height: 24),

                            // SIGN UP BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  _loading ? 'CREATING...' : 'SIGN UP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            const Text('Or',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 14),


                            // 🔵 CONTINUE WITH GOOGLE
                            GestureDetector(
                              onTap: _loading ? null : _signUpWithGoogle,
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
                                    const SizedBox(width: 10),
                                    Text(
                                      _loading
                                          ? 'Signing in...'
                                          : 'Continue with Google',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
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

                  const SizedBox(height: 30),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          ),
                          child: const Text(
                            'Sign in',
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

  Widget _input(
    TextEditingController c,
    IconData icon,
    String hint, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
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

  Widget _password() {
    return TextField(
      controller: _passwordC,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.white),
        hintText: 'Password',
        hintStyle: const TextStyle(color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
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
