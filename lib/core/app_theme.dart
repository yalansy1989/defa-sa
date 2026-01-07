import 'package:flutter/material.dart';

class AppColors {
  // ✅ الألوان الفاخرة الجديدة (Luxury Palette)
  static const background = Color(0xFF0A0E14); // أسود عميق جداً
  static const primarySoft = Color(0xFF161B22); // رمادي غامق جداً للأسطح والبطاقات
  static const accentGold = Color(0xFFE0C097); // الذهب الملكي (مطفي)
  static const textPrimary = Color(0xFFFFFFFF); // أبيض ناصع للنصوص الرئيسية
  static const textSecondary = Color(0xFF9CA3AF); // رمادي للنصوص الفرعية
  static const borderDivider = Color(0xFF30363D); // لون الحدود الرفيعة
}

class AppTheme {
  /// ✅ ثيم التطبيق المطور (Luxury Dark Theme)
  /// يحافظ على التوافق التقني الكامل مع مشروعك
  static ThemeData themeForLocale(Locale locale) {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentGold,
      brightness: Brightness.dark,
      primary: AppColors.accentGold,
      secondary: AppColors.accentGold,
      surface: AppColors.primarySoft,
      background: AppColors.background,
      onPrimary: Colors.black, // النص فوق الأزرار الذهبية يكون أسود
    );

    final String fontFamily = (locale.languageCode == 'ar') ? 'Cairo' : 'Inter';

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // ✅ تنسيق الـ AppBar الفاخر (شفاف أو لون السطح)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),

      // ✅ تنسيق الخطوط العام
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.accentGold,
      ),

      // ✅ تنسيق حقول الإدخال (النمط الفاخر الموحد)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
        ),
        labelStyle: TextStyle(fontFamily: fontFamily, color: AppColors.textSecondary),
        hintStyle: TextStyle(fontFamily: fontFamily, color: Colors.white24),
      ),

      // ✅ تنسيق الأزرار (نفس النمط المستخدم في شاشة الترحيب)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),

      // ✅ شريط التنقل السفلي
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.accentGold,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // ✅ تنسيق الكروت (Cards) لتصبح زجاجية داكنة
      // ✅ التنسيق الصحيح المتوافق مع إصدارات Flutter الحديثة
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.primarySoft,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.accentGold),
    );
  }

  static ThemeData get lightTheme => themeForLocale(const Locale('ar'));
}
