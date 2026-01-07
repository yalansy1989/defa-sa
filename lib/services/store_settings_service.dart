import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:defa_sa/models/store_banner.dart';
import '../models/category_model.dart'; 
import '../models/walkthrough_model.dart'; 

class StoreSettingsService {
  static final _db = FirebaseFirestore.instance;

  // ... (دوال البانر والسلايدر والترحيب السابقة تبقى كما هي) ...

  // ✅✅ دالة جلب الكولكشنات الدائرية (لشريط الأقسام المتحرك)
  static Stream<List<CategoryModel>> categoriesStream() {
    return _db
        .collection('collections') // نفس الجدول الذي يحفظ فيه الأدمن
        .where('type', isEqualTo: 'category') // شرط: النوع دائري
        .where('isActive', isEqualTo: true)   // شرط: أن يكون مفعلاً
        .orderBy('order')                     // الترتيب حسب الأدمن
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // ✅ التعديل الجذري هنا:
        // بدلاً من بناء الموديل يدوياً وتجاهل منطق الصورة الجديد،
        // نستخدم دالة "fromFirestore" التي تحتوي على كود معالجة الروابط و coverImageId
        return CategoryModel.fromFirestore(data, doc.id);
        
      }).toList();
    });
  }
  
  // ✅ دالة جلب الأقسام العادية (التي ظهرت لديك سابقاً)
  static Stream<QuerySnapshot> productCollectionsStream() {
    return _db
        .collection('collections')
        .where('type', isEqualTo: 'products')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots();
  }
  
  // (أعد وضع دوال bannerStream و getSlidersStream هنا إذا كانت مفقودة)
   static Stream<StoreBanner?> bannerStream() {
    return _db.collection('store_settings').doc('global').snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      final b = data['banner'] as Map<String, dynamic>?;
      if (b == null) return null;
      return StoreBanner.fromMap(b);
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getSlidersStream() {
    return _db
        .collection('sliders')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots();
  }

  static Stream<List<WalkthroughModel>> getWalkthroughsStream() {
    return _db
        .collection('walkthroughs') 
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WalkthroughModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}