import 'package:flutter/material.dart';
import 'package:defa_sa/services/collections_service.dart';
import 'package:defa_sa/models/app_collection.dart';
import 'package:defa_sa/models/product.dart'; // ✅
import 'package:defa_sa/services/products_service.dart'; // ✅
import 'package:animate_do/animate_do.dart';

// ✅ استيراد السلايدر الذكي الذي أنشأناه
import 'package:defa_sa/features/home/widgets/home_collection_slider.dart'; 
import 'package:defa_sa/l10n/app_localizations.dart';

class HomeCollectionsSection extends StatelessWidget {
  final void Function(String productId) onOpenProduct;

  const HomeCollectionsSection({super.key, required this.onOpenProduct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<AppCollection>>(
      stream: CollectionsService.streamActiveCollections(),
      builder: (context, snap) {
        
        if (snap.hasData) {
          final items = snap.data ?? [];
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.map((collection) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 32), // مسافة بين الكولكشن والآخر
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. عنوان الكولكشن
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFE0C097), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            collection.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. ✅ السلايدر الذكي (يعرض المميز أو البانر)
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: HomeCollectionSlider(
                        collectionId: collection.id,
                        onOpenProduct: onOpenProduct,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 3. ✅ قائمة بقية المنتجات (أسفل السلايدر)
                    _CollectionProductsHorizontalList(
                      collectionId: collection.id,
                      onOpenProduct: onOpenProduct,
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE0C097))),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// --- ويدجت داخلي لعرض قائمة المنتجات العادية للكولكشن ---
class _CollectionProductsHorizontalList extends StatelessWidget {
  final String collectionId;
  final void Function(String) onOpenProduct;

  const _CollectionProductsHorizontalList({
    required this.collectionId,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      // نجلب المنتجات ونفلتر التابعة لهذا القسم
      stream: ProductsService.streamActiveProducts().map((all) {
        return all.where((p) => p.collectionId == collectionId || p.collectionIds.contains(collectionId)).toList();
      }),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();

        final products = snap.data!;
        
        return Container(
          height: 240,
          margin: const EdgeInsets.only(top: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: SizedBox(
                  width: 160,
                  // نستخدم كارت المنتج البسيط (نفس المستخدم في HomeDynamicSections)
                  // يمكنك استبداله بـ ProductCard إذا كان متاحاً لديك
                  child: _SimpleProductCard(
                    product: p,
                    onTap: () => onOpenProduct(p.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- كارت منتج بسيط (لضمان عمل الملف بشكل مستقل) ---
class _SimpleProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _SimpleProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final img = product.coverImage ?? (product.images.isNotEmpty ? product.images.first : '');
    final price = product.price > 0
        ? "${product.price.toStringAsFixed(2)} ${product.currency}"
        : l10n.storeContactUs;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white.withOpacity(0.05),
                width: double.infinity,
                child: img.isNotEmpty
                    ? Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24),
                      )
                    : const Icon(Icons.image, color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            price,
            style: const TextStyle(color: Color(0xFFE0C097), fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}