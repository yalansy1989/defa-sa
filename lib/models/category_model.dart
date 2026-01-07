class CategoryModel {
  final String id;
  final String name;
  final String imageUrl; // سيحمل هنا اسم الملف (مثل image.png)

  CategoryModel({
    required this.id, 
    required this.name, 
    required this.imageUrl
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> json, String docId) {
    String finalImage = '';

    // ✅ التغيير الجذري: الأولوية لاسم الملف الجديد (coverImageId)
    // حتى لو كان هناك رابط قديم في imageUrl، سنتجاهله إذا وجدنا الملف الجديد
    if (json['coverImageId'] != null && json['coverImageId'].toString().isNotEmpty) {
      finalImage = json['coverImageId'];
    } 
    // إذا لم نجد الجديد، نستخدم القديم
    else if (json['imageUrl'] != null && json['imageUrl'].toString().startsWith('http')) {
      finalImage = json['imageUrl'];
    }

    return CategoryModel(
      id: docId,
      name: json['title'] ?? json['name'] ?? '',
      imageUrl: finalImage,
    );
  }
}