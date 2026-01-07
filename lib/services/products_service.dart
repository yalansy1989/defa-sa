import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:defa_sa/models/product.dart';

/**
 * ✅ خدمة المنتجات الملكية لمشروع دِفا الرسمي (defa-sa-official)
 * تم ضبط الاستعلامات لتعمل بتوافق تام مع سحابة بلجيكا (europe-west1).
 */
class ProductsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ كل المنتجات النشطة المرتبطة بالمشروع الرسمي
  /// يتم جلبها من منطقة بلجيكا وتصفيتها محلياً لضمان سرعة الاستجابة.
  static Stream<List<Product>> streamActiveProducts() {
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('projectId', isEqualTo: 'defa-sa-official') // ✅ فلترة المشروع الرسمي
        // ملاحظة: إذا كبر عدد المنتجات مستقبلاً، يفضل عمل Pagination هنا
        .snapshots()
        .map((snap) => snap.docs.map((d) => Product.fromDoc(d)).toList());
  }

  /// ✅ منتجات المتجر
  static Stream<List<Product>> streamStoreProducts() {
    return streamActiveProducts().map(
      (items) => items.where((p) => p.showInStore).toList(),
    );
  }

  /// ✅ منتجات الرئيسية
  static Stream<List<Product>> streamHomeProducts() {
    return streamActiveProducts().map(
      (items) => items.where((p) => p.showInHome).toList(),
    );
  }

  /// ✅ منتجات الباقات (subscription)
  static Stream<List<Product>> streamPlansProducts() {
    return streamActiveProducts().map(
      (items) => items.where((p) => p.isSubscription).toList(),
    );
  }

  /// ✅ منتجات تواصل معنا (contact)
  static Stream<List<Product>> streamContactProducts() {
    return streamActiveProducts().map(
      (items) => items.where((p) => p.isContact).toList(),
    );
  }

  /// ✅ سلايدر منتجات الرئيسية بتنظيم فخم
  static Stream<List<Product>> streamHomeCarouselProducts() {
    return streamActiveProducts().map((items) {
      final list = items
          .where((p) => p.showInHome)
          .where((p) => p.homeCarouselEnabled)
          .toList();

      // ترتيب العرض بناءً على معايير دِفا التنظيمية
      list.sort((a, b) {
        final ao = a.homeCarouselOrder;
        final bo = b.homeCarouselOrder;
        // الترتيب حسب الرقم، ثم الأبجدية
        if (ao != bo) return ao.compareTo(bo);
        return a.name.compareTo(b.name);
      });

      return list;
    });
  }

  /// ✅ منتجات داخل كولكشن (مع دعم الفلترة للرئيسية)
  static Stream<List<Product>> streamProductsForCollection(
    String collectionId, {
    bool forHomeOnly = false,
  }) {
    return streamActiveProducts().map((items) {
      // الشرط: مصفوفة الكولكشنات داخل المنتج تحتوي على هذا الـ ID
      final filtered =
          items.where((p) => p.collectionIds.contains(collectionId));
      
      return forHomeOnly
          ? filtered.where((p) => p.showInHome).toList()
          : filtered.toList();
    });
  }

  /// ✅ جلب منتج واحد من سحابة بلجيكا (يستخدم في شاشة التفاصيل)
  static Stream<Product?> streamProductById(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists ? Product.fromDoc(doc) : null);
  }
}