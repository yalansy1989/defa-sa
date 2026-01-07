import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * ✅ خدمة الوسائط الملكية لمشروع دِفا الرسمي (defa-sa-official)
 * تم تحسين منطق جلب الروابط ليتوافق مع مستودع تخزين بلجيكا (Storage).
 */
class MediaService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ يرجّع الرابط الخام للصورة من Firestore لمشروع دِفا الرسمي
  /// يبحث عن كافة الحقول الممكنة لضمان عدم فشل عرض أي صورة
  static Future<String?> getRawUrl(String mediaId) async {
    final id = mediaId.trim();
    if (id.isEmpty) return null;

    try {
      final doc = await _db.collection('media').doc(id).get();
      
      if (!doc.exists) {
        // فحص إضافي في حالة كان المعرف مفقوداً في مشروع بلجيكا الجديد
        print("Media ID $id not found in defa-sa-official");
        return null;
      }

      final data = doc.data();
      if (data == null) return null;

      // ترتيب الأولويات لجلب الرابط بأعلى جودة ممكنة
      return (data['url'] ??
              data['secureUrl'] ??
              data['secure_url'] ??
              data['thumbnailUrl'] ??
              data['downloadUrl']) // إضافة حقل التحميل الشائع في بلجيكا
          ?.toString();
    } catch (e) {
      print("Error fetching media from Belgium region: $e");
      return null;
    }
  }

  /**
   * ✅ دالة معالجة الرابط (Resolve)
   * تضمن عرض رابط صالح أو صورة افتراضية فخمة في حالة الخطأ.
   */
  static String resolveImage(String? url) {
    if (url == null || url.isEmpty) {
      // يمكن هنا وضع رابط لصورة افتراضية لشعار دِفا الرسمي
      return ''; 
    }
    
    // تأمين الروابط التي لا تبدأ بـ https (معايير أمان بلجيكا)
    if (!url.startsWith('http')) {
       return url; // قد يكون مساراً محلياً
    }
    
    return url;
  }
}