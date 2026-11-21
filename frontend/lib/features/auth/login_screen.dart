import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../main_navigation_shell.dart';

class JalKawachLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. White Shield Path
    final shieldPath = Path()
      ..moveTo(w * 0.50, h * 0.14)
      ..cubicTo(w * 0.58, h * 0.17, w * 0.70, h * 0.22, w * 0.78, h * 0.28)
      ..lineTo(w * 0.78, h * 0.56)
      ..cubicTo(w * 0.78, h * 0.72, w * 0.65, h * 0.84, w * 0.50, h * 0.90)
      ..cubicTo(w * 0.35, h * 0.84, w * 0.22, h * 0.72, w * 0.22, h * 0.56)
      ..lineTo(w * 0.22, h * 0.28)
      ..cubicTo(w * 0.30, h * 0.22, w * 0.42, h * 0.17, w * 0.50, h * 0.14)
      ..close();

    final shieldPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldPaint);

    // 2. Water Droplet at bottom tip of shield
    final dropPath = Path()
      ..moveTo(w * 0.50, h * 0.70)
      ..cubicTo(w * 0.41, h * 0.79, w * 0.38, h * 0.83, w * 0.38, h * 0.88)
      ..arcToPoint(
        Offset(w * 0.62, h * 0.88),
        radius: Radius.circular(w * 0.12),
        clockwise: false,
      )
      ..cubicTo(w * 0.62, h * 0.83, w * 0.59, h * 0.79, w * 0.50, h * 0.70)
      ..close();

    final dropPaint = Paint()
      ..color = const Color(0xFFD4F0FF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dropPath, dropPaint);

    // 3. Inner accent reflection in water drop
    final arcPaint = Paint()
      ..color = const Color(0xFF1E6CE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(
      center: Offset(w * 0.50, h * 0.89),
      radius: w * 0.055,
    );
    canvas.drawArc(arcRect, 1.8, 1.8, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final strokeWidth = w * 0.20;
    final innerRadius = radius - (strokeWidth / 2);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: innerRadius);

    // Red arc (top)
    canvas.drawArc(rect, -2.356, 1.571, false, redPaint);
    // Yellow arc (left)
    canvas.drawArc(rect, 2.356, 1.571, false, yellowPaint);
    // Green arc (bottom)
    canvas.drawArc(rect, 0.785, 1.571, false, greenPaint);
    // Blue arc (right)
    canvas.drawArc(rect, -0.785, 1.571, false, bluePaint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(center.dx, center.dy - (strokeWidth / 2), innerRadius, strokeWidth);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  String? _detectedLocationText = 'Detecting nearest flood basin...';
  String? _emailValidationStatus;
  bool _isEmailValid = true;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      final res = await _apiService.detectUserLocation();
      if (mounted) {
        final detected = res['detected'] as Map<String, dynamic>?;
        final city = detected?['city'] ?? 'Delhi';
        final region = detected?['region'] ?? 'NCR';
        final matched = res['matchedLocation'] as Map<String, dynamic>?;
        final basin = matched?['basin'] ?? 'Yamuna Basin';

        setState(() {
          _detectedLocationText = '📍 $city, $region • $basin';
          _isDetectingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _detectedLocationText = '📍 India • Central Water Commission Zone';
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _checkEmailValidity(String email) async {
    if (!email.contains('@') || email.length < 5) {
      setState(() {
        _emailValidationStatus = null;
        _isEmailValid = true;
      });
      return;
    }

    final res = await _apiService.validateEmail(email);
    if (!mounted) return;

    setState(() {
      final bool disposable = res['disposable'] == true;
      final bool valid = res['valid'] == true;
      _isEmailValid = valid && !disposable;

      if (disposable) {
        _emailValidationStatus = '⚠️ Temporary/disposable email not allowed for emergency alerts';
      } else if (valid) {
        _emailValidationStatus = '✓ Verified deliverable email (${res['domain'] ?? ''})';
      } else {
        _emailValidationStatus = res['message']?.toString();
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    // Check email with Disify Email API
    final email = _emailController.text.trim();
    if (email.contains('@')) {
      final emailCheck = await _apiService.validateEmail(email);
      if (emailCheck['disposable'] == true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailCheck['message'] ?? 'Disposable emails are blocked for safety.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    debugPrint("Login successful: ${_emailController.text}");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  void _handleGoogleLogin() {
    debugPrint("Google Login");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  void _handleForgotPassword() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A306C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF3296EE)),
        ),
        title: const Text(
          "Reset Password",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your registered email address. We will verify it via the Mail API and send a recovery token.",
              style: TextStyle(color: Color(0xFFC7E8FF), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter your email",
                hintStyle: const TextStyle(color: Color(0xFFB6D1F4), fontSize: 14),
                filled: true,
                fillColor: Colors.white.withAlpha(20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF66B5FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF8DE3FF), width: 1.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFFB9D9FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1596EF),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final targetEmail = resetController.text.trim();
              Navigator.pop(ctx);
              if (targetEmail.isNotEmpty) {
                final result = await _apiService.requestPasswordReset(targetEmail);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Recovery email sent.'),
                      backgroundColor: const Color(0xFF1596EF),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.65, 1.0],
            colors: [
              Color(0xFF174DA1),
              Color(0xFF07317C),
              Color(0xFF001E59),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBrandSection(),
                  const SizedBox(height: 24),
                  _buildLoginCard(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF388BFD),
                Color(0xFF1E6CE4),
                Color(0xFF1350B8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E6CE4).withAlpha(120),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(60, 60),
              painter: JalKawachLogoPainter(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppConstants.appName,
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF78BAFF).withAlpha(130),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            "FLOOD DISASTER PREPAREDNESS",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC7E8FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: const Color(0xFF0A4297).withAlpha(115),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF3296EE),
                width: 1,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Auto-Detected Geolocation Chip from Location API
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF66B5FF).withAlpha(90)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF8DE3FF), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _detectedLocationText ?? 'Location detection ready',
                            style: const TextStyle(
                              color: Color(0xFFC7E8FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isDetectingLocation)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          GestureDetector(
                            onTap: _detectLocation,
                            child: const Icon(Icons.refresh_rounded, color: Color(0xFFBCE6FF), size: 16),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Sign in to stay informed and safe.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB9D9FF),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Email / Phone Number",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC2E6FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (val) {
                      _checkEmailValidity(val);
                    },
                    decoration: InputDecoration(
                      hintText: "Enter email or phone number",
                      hintStyle: const TextStyle(color: Color(0xFFB6D1F4), fontSize: 14),
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF66B5FF), width: 1.4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF8DE3FF), width: 1.8),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.4),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Please enter email or phone number";
                      }
                      if (!_isEmailValid) {
                        return "Please use a valid, active email address";
                      }
                      return null;
                    },
                  ),

                  // Real-time Email Verification Badge (Disify API)
                  if (_emailValidationStatus != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _emailValidationStatus!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _isEmailValid ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    "Password",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC2E6FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: "Enter password",
                      hintStyle: const TextStyle(color: Color(0xFFB6D1F4), fontSize: 14),
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      suffixIcon: TextButton(
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                        child: Text(
                          _showPassword ? "Hide" : "Show",
                          style: const TextStyle(
                            color: Color(0xFFBCE6FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF66B5FF), width: 1.4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF8DE3FF), width: 1.8),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.4),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Please enter password";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0xFF48DFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1596EF),
                          Color(0xFF0872D9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1596EF).withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFF91C9FF).withAlpha(120),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color: Color(0xFFC4E4FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFF91C9FF).withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handleGoogleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF142C53),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(20, 20),
                              painter: GoogleIconPainter(),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF142C53),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "🛡️",
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(width: 8),
          Text(
            "Your Safety, Our Priority",
            style: TextStyle(
              color: Color(0xFFC5E6FF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
