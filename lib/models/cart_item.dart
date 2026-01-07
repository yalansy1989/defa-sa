/// ✅ نموذج عنصر السلة المحدث (CartItem)
/// يدعم الآن نظام الصور الذكية (Media ID) لضمان سرعة وفخامة العرض في السلة.
class CartItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  /// ✅ رابط الصورة التقليدي (Fallback)
  final String? imageUrl;

  /// ✅ معرف الصورة الذكي (الجديد) - لربطه مع SmartMediaImage
  final String? imageMediaId;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.imageMediaId,
  });

  /// إنشاء نسخة جديدة مع تعديل القيم
  CartItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    String? imageUrl,
    String? imageMediaId,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      imageMediaId: imageMediaId ?? this.imageMediaId,
    );
  }

  /// حساب الإجمالي لهذا العنصر تلقائياً
  double get totalPrice => unitPrice * quantity;

  /// تحويل إلى Map لحفظه في Firestore أو مشاركته داخل الطلب
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice, // نرسل الإجمالي المحسوب

      if (imageUrl != null && imageUrl!.trim().isNotEmpty)
        'imageUrl': imageUrl,
      
      // ✅ حفظ Media ID لضمان ظهور الصورة الذكية في طلبات الأدمن والعميل
      if (imageMediaId != null && imageMediaId!.trim().isNotEmpty)
        'imageMediaId': imageMediaId,
    };
  }

  /// إنشاء CartItem من بيانات Firestore بأمان تام
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      
      // ✅ تحويل آمن للأرقام (سواء كانت int أو double في القاعدة)
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,

      imageUrl: (map['imageUrl'] ?? map['image'] ?? map['coverImage'])?.toString(),
      
      // ✅ دعم استرجاع Media ID الجديد
      imageMediaId: map['imageMediaId']?.toString(),
    );
  }
}