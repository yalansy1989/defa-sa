import 'package:cloud_firestore/cloud_firestore.dart';

class AppCollection {
  final String id;
  final String title;
  final String description;
  final int order;
  final bool isActive;

  AppCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.isActive,
  });

  factory AppCollection.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppCollection(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
      isActive: (data['isActive'] is bool) ? data['isActive'] as bool : true,
    );
  }
}
