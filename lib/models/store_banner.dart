class BannerAction {
  final String type; // none | product | link | category
  final String? buttonText;
  final String? productId;
  final String? url;
  final String? categoryId; // ✅ إضافة دعم للأقسام

  BannerAction({
    required this.type,
    this.buttonText,
    this.productId,
    this.url,
    this.categoryId,
  });

  factory BannerAction.fromMap(Map<String, dynamic>? m) {
    final mm = m ?? {};
    return BannerAction(
      type: (mm['type'] ?? 'none').toString(),
      buttonText: mm['buttonText']?.toString(),
      productId: mm['productId']?.toString(),
      url: mm['url']?.toString(),
      categoryId: mm['categoryId']?.toString(),
    );
  }
}

class StoreBanner {
  final bool isActive;
  final String title;
  final String subtitle;
  final String? imageUrl; 
  final String? imageMediaId; // ✅ التسمية الرسمية في المشروع الجديد
  final BannerAction action;

  StoreBanner({
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.action,
    this.imageUrl,
    this.imageMediaId,
  });

  factory StoreBanner.fromMap(Map<String, dynamic>? m) {
    final mm = m ?? {};
    return StoreBanner(
      isActive: (mm['isActive'] ?? false) == true,
      title: (mm['title'] ?? '').toString(),
      subtitle: (mm['subtitle'] ?? '').toString(),
      // ✅ دعم قراءة MediaId من الحقل الجديد أو القديم لضمان التوافق
      imageUrl: mm['imageUrl']?.toString(),
      imageMediaId: mm['imageMediaId']?.toString() ?? mm['imageId']?.toString(), 
      action: BannerAction.fromMap(mm['action'] as Map<String, dynamic>?),
    );
  }
}