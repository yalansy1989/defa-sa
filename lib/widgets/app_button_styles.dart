import 'package:flutter/material.dart';

/**
 * ✅ أنماط الأزرار الملكية لمشروع دِفا الرسمي (defa-sa-official)
 * تم تحسين الأبعاد لمنع قص النصوص العربية وضمان سلاسة العرض في سحابة بلجيكا.
 */
class AppButtonStyles {
  /**
   * ✅ نمط الزر الأساسي المنحني
   * يستخدم في العمليات الرئيسية مثل "اطلب الآن" و "اشترك".
   */
  static ButtonStyle primaryRounded(BuildContext context, double radius) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ElevatedButton.styleFrom(
      // ✅ الاعتماد على ألوان الهوية الرسمية من الـ ColorScheme
      backgroundColor: cs.secondary,        
      foregroundColor: Colors.black,        
      elevation: 0,
      
      // ✅ ضبط الحجم الأدنى لمنع قص النص وتوفير مساحة لمس مريحة (UX)
      minimumSize: const Size.fromHeight(48), 
      
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      visualDensity: VisualDensity.standard,
      
      // ✅ التحكم في انحناء الحواف بناءً على التصميم المطلوب
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      
      // ✅ معالجة الخطوط العربية لضمان الفخامة وعدم القص العلوي أو السفلي
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.2, // زيادة طفيفة لضمان استقرار الخطوط مثل Cairo
        letterSpacing: 0.5,
      ),
    );
  }

  /**
   * ✅ نمط الزر الشفاف (Outlined) - اختياري للعمليات الثانوية
   * تم إضافته لتعزيز التنوع في واجهات مشروع دِفا الفاخرة.
   */
  static ButtonStyle secondaryOutline(BuildContext context, double radius) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return OutlinedButton.styleFrom(
      foregroundColor: cs.primary,
      side: BorderSide(color: cs.primary, width: 1.5),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }
}