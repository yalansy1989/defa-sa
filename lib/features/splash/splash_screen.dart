import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ إضافة المكتبة للفحص

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // الألوان الملكية
  static const Color goldColor = Color(0xFFE0C097);
  static const Color deepDarkColor = Color(0xFF0A0E14);

  @override
  void initState() {
    super.initState();
    // ✅ المؤقت: بعد 3.5 ثانية ينتقل للصفحة التالية بناءً على الإعدادات المحفوظة
    Timer(const Duration(seconds: 3, milliseconds: 500), () {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    // ✅ فحص هل اختار المستخدم اللغة مسبقاً أم لا
    final prefs = await SharedPreferences.getInstance();
    final bool isLanguageSet = prefs.getBool('is_language_set') ?? false;

    if (isLanguageSet) {
      // 🚀 إذا تم اختيار اللغة سابقاً: انتقل مباشرة لصفحة الترحيب (Onboarding)
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      // 🚀 إذا كانت المرة الأولى: انتقل لشاشة اختيار اللغة
      Navigator.of(context).pushReplacementNamed('/language_selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepDarkColor, // الخلفية السوداء الفخمة
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✨ 1. تأثير إضاءة خلفية خافتة وراء الشعار
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              child: FadeIn(
                duration: const Duration(seconds: 2),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withOpacity(0.15),
                        blurRadius: 100,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 👑 2. الشعار والاسم
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // حركة ظهور الشعار (logo.png المفرغ الجديد)
                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: Image.asset(
                    'assets/images/logo.png', 
                    width: 180,
                  ),
                ),
                
                const SizedBox(height: 20),

                // حركة ظهور النص
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  duration: const Duration(milliseconds: 1000),
                  child: Column(
                    children: [
                      Text(
                        "DEEFAA STORE",
                        style: GoogleFonts.cairo(
                          color: goldColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "عالم من الفخامة والتميز",
                        style: GoogleFonts.cairo(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ⏳ 3. مؤشر تحميل صغير وأنيق
            Positioned(
              bottom: 50,
              child: FadeIn(
                delay: const Duration(seconds: 1),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: goldColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}