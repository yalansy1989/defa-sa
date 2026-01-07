import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/**
 * ✅ خدمة التحليلات الملكية لمشروع دِفا الرسمي (defa-sa-official)
 * تم ضبطها لجمع البيانات في منطقة بلجيكا لضمان سرعة معالجة التقارير.
 */
class AnalyticsService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// ✅ يدعم شكلين للاستدعاء لضمان المرونة الكاملة:
  /// 1) log(event: '...', screen: '...', extra: {...})
  /// 2) log(type: '...', source: '...', targetType: '...', targetId: '...', meta: {...})
  static Future<void> log({
    // الشكل الأول
    String? event,
    String? screen,
    Map<String, dynamic>? extra,

    // الشكل الثاني (الموجود في checkout_page)
    String? type,
    String? source,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final user = _auth.currentUser;

      // نحدد اسم الحدث النهائي بدقة
      final finalEvent = (event?.trim().isNotEmpty ?? false)
          ? event!.trim()
          : (type?.trim().isNotEmpty ?? false)
              ? type!.trim()
              : 'event';

      // نوحّد البيانات الإضافية لضمان عدم فقدان أي تفاصيل
      final payload = <String, dynamic>{
        ...?extra,
        ...?meta,
      };

      // تسجيل الحدث في قاعدة بيانات بلجيكا الرسمية
      await _db.collection('analytics_events').add({
        'projectId': 'defa-sa-official', // ✅ بصمة المشروع الرسمي الجديد
        'event': finalEvent,
        'screen': screen ?? source,
        'type': type,
        'source': source,
        'targetType': targetType,
        'targetId': targetId,
        'meta': payload,
        'userId': user?.uid,
        'userEmail': user?.email,
        'region': 'europe-west1',        // توثيق موقع الحدث في بلجيكا
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'flutter',
        'environment': 'production',
      });
    } catch (_) {
      // لا نكسر التطبيق لو فشل التتبع لضمان استمرارية تجربة المستخدم
    }
  }
}