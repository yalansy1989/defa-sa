class WalkthroughModel {
  final String id;
  final String title;
  
  // ✅ تم تغيير الاسم من body إلى description ليطابق ملف العرض
  final String description; 
  
  // ✅ تم تغيير الاسم من image إلى imageUrl ليطابق ملف العرض
  final String imageUrl; 
  
  final int order;
  final bool isActive;

  WalkthroughModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.order,
    this.isActive = true,
  });

  factory WalkthroughModel.fromMap(Map<String, dynamic>? data, String documentId) {
    if (data == null) {
      return WalkthroughModel(
        id: documentId,
        title: '',
        description: '',
        imageUrl: '',
        order: 0,
        isActive: false,
      );
    }

    return WalkthroughModel(
      id: documentId,
      title: (data['title'] ?? '').toString(),
      
      // ✅ دعم قراءة 'body' أو 'description' من قاعدة البيانات لضمان المرونة
      description: (data['description'] ?? data['body'] ?? '').toString(),
      
      // ✅ دعم قراءة 'image' أو 'imageUrl'
      imageUrl: (data['imageUrl'] ?? data['image'] ?? '').toString(),
      
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
      isActive: data['isActive'] ?? true,
    );
  }
}