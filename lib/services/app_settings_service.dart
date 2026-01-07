import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/walkthrough_model.dart';

class AppSettingsService {
  // ... بقية الكود الموجود مسبقاً

  // ✅ دالة جلب شاشات الترحيب
  static Stream<List<WalkthroughModel>> getWalkthroughs() {
    return FirebaseFirestore.instance
        .collection('walkthroughs') // ⚠️ تأكد أن اسم الكولكشن في الأدمن هو 'walkthroughs'
        .where('isActive', isEqualTo: true) // إذا كان لديك خيار تفعيل/تعطيل
        .orderBy('order') // الترتيب حسب الرقم
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WalkthroughModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}