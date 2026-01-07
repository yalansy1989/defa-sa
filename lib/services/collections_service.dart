import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:defa_sa/models/app_collection.dart';
import 'package:defa_sa/models/product.dart';

class CollectionsService {
  static final _db = FirebaseFirestore.instance;

  /// ✅ الترتيب عبر الفايربيس مباشرة (الأفضل للأداء)
  static Stream<List<AppCollection>> streamActiveCollections() {
    return _db
        .collection('collections')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false) // ✅ استرجاع الترتيب من السيرفر
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppCollection.fromDoc(d))
            .toList());
  }

  static Stream<List<Map<String, dynamic>>> streamCollectionSliders(String collectionId) {
    return _db
        .collection('collections')
        .doc(collectionId)
        .collection('sliders')
        .orderBy('order', descending: false) // ✅ استرجاع الترتيب من السيرفر
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          })
          .where((x) => (x['isActive'] is bool) ? x['isActive'] as bool : true)
          .toList();
    });
  }

  static Stream<List<Product>> streamProductsLinkedToCollection(String collectionId) {
    final Stream<List<Product>> multiStream = _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('collectionIds', arrayContains: collectionId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Product.fromDoc(d)).toList());

    final Stream<List<Product>> legacyStream = _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('collectionId', isEqualTo: collectionId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Product.fromDoc(d)).toList());

    return _mergeStreams([multiStream, legacyStream]);
  }

  static Stream<List<Product>> _mergeStreams(List<Stream<List<Product>>> streams) {
    final controller = StreamController<List<Product>>();
    final List<List<Product>?> lastValues = List.filled(streams.length, null);
    final List<StreamSubscription> subs = [];

    void emit() {
      final Set<String> seenIds = {};
      final List<Product> merged = [];

      for (final list in lastValues) {
        if (list != null) {
          for (final p in list) {
            if (!seenIds.contains(p.id)) {
              seenIds.add(p.id);
              merged.add(p);
            }
          }
        }
      }
      // ترتيب المنتجات يفضل أن يبقى في التطبيق لأننا دمجنا قائمتين مختلفتين
      merged.sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
      controller.add(merged);
    }

    for (int i = 0; i < streams.length; i++) {
      subs.add(streams[i].listen((data) {
        lastValues[i] = data;
        emit();
      }));
    }

    controller.onCancel = () {
      for (var sub in subs) sub.cancel();
      controller.close();
    };

    return controller.stream;
  }
}