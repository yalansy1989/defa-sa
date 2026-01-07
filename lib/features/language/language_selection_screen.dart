import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/locale_controller.dart';
import '../../main.dart'; // للوصول لـ globalLocaleController

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFE0C097);
    const deepDarkColor = Color(0xFF0A0E14);

    return Scaffold(
      backgroundColor: deepDarkColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 120),
            const SizedBox(height: 40),
            Text(
              "اختر اللغة / Choose Language",
              style: GoogleFonts.cairo(color: goldColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _buildLangButton(context, "العربية", const Locale('ar')),
            const SizedBox(height: 15),
            _buildLangButton(context, "English", const Locale('en')),
          ],
        ),
      ),
    );
  }

  Widget _buildLangButton(BuildContext context, String label, Locale locale) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0C097),
        minimumSize: const Size(200, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        await globalLocaleController.changeLocale(locale);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      },
      child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }
}