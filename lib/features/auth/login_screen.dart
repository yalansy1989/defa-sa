import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart'; 
import '../shell/main_shell.dart';
import '../../l10n/app_localizations.dart';
import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  // الألوان الملكية لمشروع دِفا
  static const goldColor = Color(0xFFE0C097);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ✅ تسجيل الدخول بالبريد
  Future<void> _loginEmail() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      final user = await AuthService.signInWithEmail(
        email: _email.text.trim(), 
        password: _password.text.trim(),
      );
      
      if (user != null) {
        await NotificationService.updateDeviceToken('user');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ تسجيل الدخول بـ Google
  Future<void> _loginWithGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null) {
        await NotificationService.updateDeviceToken('user');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ الانتقال لشاشة الهاتف المنفصلة
  void _loginWithPhone() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openRegister() {
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  // صندوق زجاجي فاخر
  Widget _buildGlassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.5),
            radius: 1.5,
            colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: goldColor.withOpacity(0.1),
                        border: Border.all(color: goldColor.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.lock_person_outlined, size: 65, color: goldColor),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  FadeInUp(
                    child: Column(
                      children: [
                        Text(
                          t.loginWelcome,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "سجل دخولك لتجربة تسوق فريدة ومتابعة دردشاتك",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildGlassBox(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: t.email,
                                labelStyle: const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.email_outlined, color: goldColor),
                                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                              ),
                              validator: (v) => v == null || !v.contains('@') ? t.invalidEmail : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: t.password,
                                labelStyle: const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.lock_outline, color: goldColor),
                                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                              ),
                              validator: (v) => v == null || v.length < 6 ? t.shortPassword : null,
                            ),
                            const SizedBox(height: 35),
                            
                            // زر تسجيل الدخول (مع إصلاح قص النص)
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: goldColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 3,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: _loading ? null : _loginEmail,
                                child: _loading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : Center(
                                      child: Text(
                                        t.login, 
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w900, 
                                          fontSize: 18,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        Text(t.or, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 25),
                        
                        // ✅ زر Google الأصلي (تمت إعادته كما كان في كودك السابق)
                        InkWell(
                          onTap: _loading ? null : _loginWithGoogle,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85, 
                            height: 55, 
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // تم إرجاع Image.asset كما طلبت
                                Image.asset(
                                  'assets/images/google_logo.png', 
                                  height: 24,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.g_mobiledata, size: 30, color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  t.loginWithGoogle,
                                  style: const TextStyle(
                                    fontSize: 15, 
                                    fontWeight: FontWeight.w700, 
                                    color: Color(0xFF1F1F1F),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),

                        // زر الدخول بالهاتف
                        TextButton.icon(
                          onPressed: _loading ? null : _loginWithPhone,
                          icon: const Icon(Icons.phone_android_rounded, color: goldColor, size: 20),
                          label: Text(
                            "الدخول بواسطة رقم الهاتف",
                            style: GoogleFonts.cairo(
                              color: goldColor, 
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t.noAccount, style: const TextStyle(color: Colors.white54)),
                            TextButton(
                              onPressed: _openRegister,
                              child: Text(
                                t.registerNow,
                                style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}