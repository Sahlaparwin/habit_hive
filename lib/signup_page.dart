import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'main_page.dart';
import 'dart:math';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _passwordStrength = "";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = "");
    } else if (password.length < 6) {
      setState(() => _passwordStrength = "Weak");
    } else if (password.length < 10) {
      setState(() => _passwordStrength = "Medium");
    } else {
      setState(() => _passwordStrength = "Strong");
    }
  }

  bool _isPasswordValid(String password) {
    String pattern =
        r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$';
    return RegExp(pattern).hasMatch(password);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _signup() async {
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmController.text.trim();

    if (!_isPasswordValid(password)) {
      _showMessage(
          "Password must be at least 8 characters, include 1 uppercase, 1 number, and 1 special character.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match");
      return;
    }

    setState(() => _loading = true);

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        _showMessage("Signup successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = "Password is too weak (min 6 characters).";
          break;
        case 'email-already-in-use':
          message = "That email is already registered.";
          break;
        case 'invalid-email':
          message = "Invalid email format.";
          break;
        default:
          message = "Signup failed: ${e.message}";
      }
      _showMessage(message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      bool isPassword,
      {Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      obscureText: isPassword
          ? (label == "Password" ? _obscurePassword : _obscureConfirm)
          : false,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.transparent)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (label == "Password" ? _obscurePassword : _obscureConfirm)
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    if (label == "Password") {
                      _obscurePassword = !_obscurePassword;
                    } else {
                      _obscureConfirm = !_obscureConfirm;
                    }
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _gradientButton({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          return null; // allows gradient background
        }),
        overlayColor: MaterialStateProperty.all(Colors.black12),
      ),
      onPressed: onPressed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.brown, Colors.black87]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🍯 Honeycomb overlay
          const HoneycombBackground(),

          // 🐝 Main signup content
          Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 20,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  width: isWeb ? 450 : double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/images/bee_logo.png", height: 120),
                      const SizedBox(height: 20),
                      const Text("Create Account",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      const Text("Sign up to get started",
                          style: TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 24),
                      _buildTextField("Email", _emailController, false),
                      const SizedBox(height: 16),
                      _buildTextField("Password", _passwordController, true,
                          onChanged: _checkPasswordStrength),
                      if (_passwordStrength.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text("Password Strength: $_passwordStrength",
                            style: TextStyle(
                              color: _passwordStrength == "Weak"
                                  ? Colors.red
                                  : _passwordStrength == "Medium"
                                      ? Colors.orange
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                      const SizedBox(height: 16),
                      _buildTextField("Confirm Password", _confirmController, true),
                      const SizedBox(height: 24),
                      _loading
                          ? const CircularProgressIndicator()
                          : _gradientButton(label: "Sign Up", onPressed: _signup),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text("Already have an account? Login",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🍯 Honeycomb Painter for background
class HoneycombBackground extends StatelessWidget {
  const HoneycombBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: HoneycombPainter(),
    );
  }
}

class HoneycombPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double hexSize = 40.0;
    final double hexHeight = sqrt(3) * hexSize;
    final double hexWidth = 2 * hexSize;
    final double vertSpacing = hexHeight;
    final double horizSpacing = 3 / 4 * hexWidth;

    for (double y = 0; y < size.height + hexHeight; y += vertSpacing) {
      for (double x = 0; x < size.width + hexWidth; x += horizSpacing) {
        final double offsetX = (y ~/ vertSpacing) % 2 == 0 ? 0 : hexSize * 0.75;
        _drawHexagon(canvas, paint, Offset(x + offsetX, y), hexSize);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
