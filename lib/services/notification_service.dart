import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ✅ خدمة الإشعارات الملكية لمشروع دِفا الرسمي (defa-sa-official)
/// تم تحديث الهيكلية لتتوافق مع السيرفر الجديد في منطقة بلجيكا (europe-west1) لضمان فخامة التنبيهات.
class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ تحديث وحفظ التوكن (معدل ليتوافق مع مشروع defa-sa-official)
  /// يضمن هذا التحديث أن الأدمن يمكنه الوصول لجهاز العميل فور تسجيل الدخول.
  static Future<void> updateDeviceToken(String role) async {
    String? token = await FirebaseMessaging.instance.getToken();
    String? uid = _auth.currentUser?.uid;

    if (token != null && uid != null) {
      if (role == 'admin') {
        // للأدمن: حفظ التوكن في المسار المخصص للوحة التحكم داخل المشروع الرسمي
        await _db.collection('admins').doc(uid).collection('fcmTokens').doc(token).set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': 'flutter_admin',
          'projectId': 'defa-sa-official', // ✅ المعرف الرسمي الجديد
          'location': 'europe-west1',     // تأكيد التوافق مع بلجيكا
        });
        
        await _db.collection('admins').doc(uid).set({
            'hasPush': true,
            'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

      } else {
        // للعميل (User): تحديث المستند الرئيسي ليتمكن السيرفر من القراءة الفورية
        await _db.collection('users').doc(uid).set({
          'fcmToken': token, 
          'projectId': 'defa-sa-official', // ✅ المعرف الرسمي الجديد
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'serviceLocation': 'europe-west1',
        }, SetOptions(merge: true));
        
        // حفظ إضافي لدعم تعدد الأجهزة في مشروع دِفا الفاخر
        await _db.collection('users').doc(uid).collection('fcmTokens').doc(token).set({
          'token': token,
          'platform': 'mobile_app',
          'lastSeen': FieldValue.serverTimestamp(),
          'projectId': 'defa-sa-official',
        });
      }
    }
  }

  /// ✅ إنشاء إشعار بهيكلة تتطابق مع الـ Worker في بلجيكا
  /// تم إضافة حقول التوجيه لفتح شاشات الدردشة والطلبات مباشرة.
  static Future<DocumentReference<Map<String, dynamic>>> create({
    required String type, // order | chat | support
    required String title,
    required String body,
    required String targetRole, // "admin" or "user"

    String? targetUserId, // مطلوب إذا كان الهدف user
    String? screen,       // chat, order_details, support
    String? id,           // orderId أو chatId

    Map<String, dynamic>? extra,
    bool pushEnabled = true,
  }) async {
    
    if (targetRole == 'user' && targetUserId == null) {
      throw Exception("targetUserId مطلوب عندما يكون الهدف مستخدماً");
    }

    // تجهيز بيانات التوجيه الدقيقة (Payload) للمشروع الرسمي
    final targetMap = {
      'screen': screen ?? 'home',
      'id': id ?? '',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'projectId': 'defa-sa-official',
    };

    final data = <String, dynamic>{
      'type': type,
      'title': title,
      'body': body,
      'projectId': 'defa-sa-official', // ✅ المعرف الرسمي الجديد

      'targetRole': targetRole,
      'targetUserId': targetUserId,

      'target': targetMap,

      'extra': extra ?? {},
      'isRead': false,

      'push': {
        'enabled': pushEnabled,
        'sent': false,
        'processing': false,
        'targetRole': targetRole,
      },

      'createdAt': FieldValue.serverTimestamp(),
    };

    // إرسال الإشعار للكولكشن الرئيسي ليقوم السيرفر (Worker) بمعالجته في بلجيكا
    return await _db.collection('notifications').add(data);
  }

  /// تحديث حالة الإشعار إلى "تمت القراءة"
  static Future<void> markAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}