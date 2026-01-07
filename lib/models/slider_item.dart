class SliderItem {
  final String id;
  final String imageUrl;
  final String? imageId; // ✅ ضروري جداً لظهور الصور من المكتبة
  final String? linkedProductId;
  final String? link; // ✅ للروابط الخارجية
  final String title;
  final String subtitle;
  final bool isActive;
  final int order;

  SliderItem({
    required this.id,
    required this.imageUrl,
    this.imageId,
    this.linkedProductId,
    this.link,
    this.title = '',
    this.subtitle = '',
    this.isActive = true,
    this.order = 0,
  });

  factory SliderItem.fromMap(Map<String, dynamic> data, String id) {
    return SliderItem(
      id: id,
      // قراءة رابط الصورة
      imageUrl: (data['imageUrl'] ?? '').toString(),
      
      // ✅ قراءة معرف الصورة (مهم جداً)
      imageId: (data['imageId'] ?? '').toString(),

      // قراءة معرف المنتج المرتبط (مع معالجة القيم الفارغة)
      linkedProductId: data['linkedProductId']?.toString().isEmpty == true 
          ? null 
          : data['linkedProductId']?.toString(),

      // قراءة الرابط الخارجي
      link: data['link']?.toString(),

      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      
      isActive: data['isActive'] ?? true,
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }
}