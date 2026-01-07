import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * ✅ مكون عرض الأسعار الملكي لمشروع دِفا الرسمي (defa-sa-official)
 * يدعم تحويل العملات ديناميكياً بناءً على إعدادات سحابة بلجيكا.
 */
class PriceText extends StatelessWidget {
  /// ✅ النظام الجديد: السعر الأساسي باليورو (Base Currency)
  final double? priceInEur;

  /// ✅ دعم النظام القديم: المبلغ والعملة (Backward Compatibility)
  final double? amount;
  final String? currency;

  final TextStyle? style;

  const PriceText({
    super.key,
    this.priceInEur,
    this.amount,
    this.currency,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد القيمة الأساسية للمعالجة
    final double base = (priceInEur ?? amount ?? 0).toDouble();

    // ✅ إذا تم تمرير العملة صراحةً (مثل فواتير الطلبات السابقة) نعرضها مباشرة
    final String? cur = currency?.trim();
    if (cur != null && cur.isNotEmpty) {
      return Text(
        "${base.toStringAsFixed(2)} $cur",
        style: style ?? const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      );
    }

    /**
     * ✅ منطق التحويل الديناميكي:
     * يتم جلب أسعار الصرف من مشروع دِفا الرسمي لضمان الدقة.
     */
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('currency_config')
          .snapshots(),
      builder: (context, configSnap) {
        // الإعدادات الافتراضية لمشروع دِفا (SAR)
        String symbol = "SAR";
        double rate = 1.0;

        if (configSnap.hasData && (configSnap.data?.exists ?? false)) {
          final raw = configSnap.data!.data();
          if (raw is Map<String, dynamic>) {
            // التحقق من أن الإعدادات تتبع المشروع الرسمي
            final active = (raw['active_currency'] ?? "SAR").toString();
            symbol = (raw['symbol'] ?? symbol).toString();

            if (active != "EUR") {
              final rates = raw['rates'];
              if (rates is Map) {
                final r = rates[active];
                if (r is num) rate = r.toDouble();
              }
            } else {
              // في حالة تفعيل اليورو كعملة عرض أساسية
              symbol = (raw['symbol'] ?? "€").toString();
              rate = 1.0;
            }
          }
        }

        // احتساب السعر النهائي بناءً على سعر الصرف المحدث
        final double finalPrice = base * rate;

        return Text(
          "${finalPrice.toStringAsFixed(2)} $symbol",
          style: style ?? const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        );
      },
    );
  }
}