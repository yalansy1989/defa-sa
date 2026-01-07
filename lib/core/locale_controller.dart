import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  // ✅ 1. المفاتيح الموحدة لحفظ الإعدادات في ذاكرة الهاتف
  static const String _key = 'language_code'; 
  static const String _isSetKey = 'is_language_set'; // ✅ مفتاح حالة إتمام اختيار اللغة
  
  Locale? _locale;

  Locale? get locale => _locale;

  /// تحميل اللغة المحفوظة عند فتح التطبيق
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    
    // إذا لم توجد لغة محفوظة، نستخدم العربية (ar) كافتراضي لمشروع دِفا
    if (code == null || code.isEmpty) {
      _locale = const Locale('ar');
    } else {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  /// ✅ 2. دالة تغيير اللغة وحفظ حالة "إتمام الإعداد"
  Future<void> changeLocale(Locale locale) async {
    // تحديث الحالة المحلية فوراً لسرعة الاستجابة
    _locale = locale;
    notifyListeners(); // 🔥 هذا السطر يخبر التطبيق بإعادة بناء الواجهة فوراً
    
    final prefs = await SharedPreferences.getInstance();
    
    // حفظ كود اللغة
    await prefs.setString(_key, locale.languageCode);
    
    // ✅ حفظ أن المستخدم قد أكمل إعداد اللغة لأول مرة
    // هذا السطر يضمن أن شاشة اختيار اللغة لن تظهر مجدداً في المرة القادمة
    await prefs.setBool(_isSetKey, true);
  }

  /// فحص إذا كانت الواجهة حالياً من اليمين لليسار (RTL)
  bool isRTL(BuildContext context) {
    final code = (_locale?.languageCode) ?? Localizations.localeOf(context).languageCode;
    return code == 'ar';
  }
}