import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String? shortDescription;

  // ✅ السعر الأساسي المخزن
  final double price;
  final double? priceBefore;

  // ✅ العملة
  final String currency;

  final bool isActive;
  final String visibility;

  // ✅ الحقل الجديد للتحكم في السلايدر العلوي
  final bool homeCarouselEnabled;
  final int homeCarouselOrder;

  // ✅ خاصية التمييز (Featured) - لحل مشكلة عدم الظهور في الرئيسية
  final bool isFeatured; 

  // ✅ الحقل الخاص بالترتيب
  final int? sort;

  final String pricingMode;
  final String? coverImage;
  final List<String> images;
  final String? imageMediaId;
  final List<String> galleryMediaIds;

  // ✅ قائمة المميزات الفنية
  final List<String> features;

  // ✅ الحقول المطلوبة لربط الكولكشن
  final String collectionId;
  final List<String> collectionIds;

  final String? category;
  final String? couponCode;
  final String? couponType;
  final num? couponValue;
  final String? sku;
  final num? weight;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.shortDescription,
    required this.price,
    this.priceBefore,
    required this.currency,
    required this.isActive,
    required this.visibility,
    required this.homeCarouselEnabled,
    required this.homeCarouselOrder,
    required this.isFeatured, // ✅ مطلوب الآن
    this.sort,
    required this.pricingMode,
    this.coverImage,
    required this.images,
    this.imageMediaId,
    required this.galleryMediaIds,
    this.features = const [],
    required this.collectionId,
    required this.collectionIds,
    this.category,
    this.couponCode,
    this.couponType,
    this.couponValue,
    this.sku,
    this.weight,
    this.createdAt,
    this.updatedAt,
  });

  // ✅ دالة empty
  factory Product.empty() {
    return Product(
      id: '',
      name: '',
      description: '',
      price: 0,
      priceBefore: null,
      currency: 'SAR',
      isActive: false,
      visibility: 'none',
      homeCarouselEnabled: false,
      homeCarouselOrder: 0,
      isFeatured: false, // افتراضي
      sort: 0,
      pricingMode: 'normal',
      coverImage: null,
      images: [],
      imageMediaId: null,
      galleryMediaIds: [],
      features: [],
      collectionId: '',
      collectionIds: [],
      category: null,
      couponCode: null,
      couponType: null,
      couponValue: null,
      sku: null,
      weight: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  // Helper properties
  bool get showInHome => visibility == 'home' || visibility == 'both' || isFeatured;
  bool get showInStore => visibility == 'store' || visibility == 'both';
  bool get isSubscription => pricingMode == 'subscription';
  bool get isContact => pricingMode == 'contact';

  String get primaryImage => (coverImage != null && coverImage!.trim().isNotEmpty)
      ? coverImage!.trim()
      : (images.isNotEmpty ? images.first : '');

  // Helpers
  static double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    return double.tryParse(s) ?? fallback;
  }

  static String _toString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List) {
      return v
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime? tsToDt(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate();
      return null;
    }

    final images = _toStringList(data['images']);
    final galleryMediaIds = _toStringList(data['galleryMediaIds']);
    final features = _toStringList(data['features']);
    final collectionIds = _toStringList(data['collectionIds']);
    final rawPricingMode = _toString(data['pricingMode'], fallback: 'normal');
    final normalizedPricingMode = rawPricingMode == 'price' ? 'normal' : rawPricingMode;

    String rawColId = _toString(data['collectionId']);
    if (rawColId.isEmpty) rawColId = _toString(data['categoryId']);
    if (rawColId.isEmpty) rawColId = _toString(data['category']);

    String rawCurrency = _toString(
      data['currency'] ??
          data['currencyCode'] ??
          data['currency_symbol'] ??
          data['currencySymbol'],
      fallback: 'SAR', 
    );

    if (rawCurrency == 'ر.س' || rawCurrency.toLowerCase() == 'sar') {
      rawCurrency = 'SAR';
    }

    // ✅ منطق تحديد ما إذا كان المنتج مميزاً (للظهور في الرئيسية)
    // نعتبره مميزاً إذا كان:
    // 1. لديه حقل isFeatured = true
    // 2. أو visibility = home
    // 3. أو visibility = both
    final String visibilityVal = _toString(data['visibility'], fallback: 'store');
    final bool explicitFeatured = (data['isFeatured'] == true) || (data['featured'] == true);
    final bool visibleHome = visibilityVal == 'home' || visibilityVal == 'both';

    return Product(
      id: doc.id,
      name: _toString(data['name']),
      description: _toString(data['description']),
      shortDescription: (data['shortDescription'] == null)
          ? null
          : _toString(data['shortDescription']),

      price: _toDouble(data['price'] ?? data['price_eur'], fallback: 0),
      priceBefore: data['priceBefore'] == null && data['price_before_eur'] == null
          ? null
          : _toDouble(data['priceBefore'] ?? data['price_before_eur']),

      currency: rawCurrency,

      isActive: (data['isActive'] == true),
      visibility: visibilityVal,

      homeCarouselEnabled: (() {
        final v = data['homeCarouselEnabled'] ?? data['showInHomeCarousel'];
        if (v is bool) return v;
        return false; // الافتراضي false للسلايدر العلوي
      })(),

      homeCarouselOrder: (() {
        final v = data['homeCarouselOrder'] ?? data['homeOrder'];
        if (v is num) return v.toInt();
        return 9999;
      })(),

      // ✅ تعيين قيمة التمييز بناءً على المنطق أعلاه
      isFeatured: explicitFeatured || visibleHome,

      sort: (data['sort'] is num) ? (data['sort'] as num).toInt() : 0,

      pricingMode: normalizedPricingMode,
      coverImage: (data['coverImage'] == null) ? null : _toString(data['coverImage']),
      images: images,
      imageMediaId: (data['imageMediaId'] == null) ? null : _toString(data['imageMediaId']),
      galleryMediaIds: galleryMediaIds,
      features: features,

      collectionId: rawColId,
      collectionIds: collectionIds,

      category: (data['category'] == null) ? null : _toString(data['category']),
      couponCode: (data['couponCode'] == null) ? null : _toString(data['couponCode']),
      couponType: (data['couponType'] == null) ? null : _toString(data['couponType']),
      couponValue: data['couponValue'] as num?,
      sku: (data['sku'] == null) ? null : _toString(data['sku']),
      weight: data['weight'] as num?,
      createdAt: tsToDt(data['createdAt']),
      updatedAt: tsToDt(data['updatedAt']),
    );
  }
}