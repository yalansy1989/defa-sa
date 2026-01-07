import 'package:flutter/material.dart';
import 'package:defa_sa/models/app_collection.dart';
import 'package:defa_sa/models/product.dart';
import 'package:defa_sa/services/collections_service.dart';
import 'package:defa_sa/features/home/home_collection_slider.dart';
import 'package:defa_sa/l10n/app_localizations.dart';

class HomeCollectionBlock extends StatelessWidget {
  final AppCollection collection;
  final void Function(String productId) onOpenProduct;

  const HomeCollectionBlock({
    super.key,
    required this.collection,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          collection.title,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (collection.description.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            collection.description.trim(),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 10),

        HomeCollectionSlider(
          collectionId: collection.id,
          onOpenProduct: onOpenProduct,
        ),

        const SizedBox(height: 10),

        StreamBuilder<List<Product>>(
          stream: CollectionsService.streamProductsLinkedToCollection(collection.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text(
                l10n.storeLoadError,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
              );
            }

            final products = snapshot.data ?? const <Product>[];
            if (products.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 285,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final p = products[i];
                  return SizedBox(
                    width: 200,
                    child: _CollectionProductCard(
                      product: p,
                      onOpen: () => onOpenProduct(p.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CollectionProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onOpen;

  const _CollectionProductCard({
    required this.product,
    required this.onOpen,
  });

  /// ✅ العملة من قاعدة البيانات:
  /// نحاول قراءة product.currencyCode أو product.currency
  /// وإلا الافتراضي EUR.
  String _currencySymbol(Product p) {
    final code = ((p as dynamic).currencyCode ?? (p as dynamic).currency ?? 'EUR')
        .toString()
        .toUpperCase();

    switch (code) {
      case 'USD':
        return r'$';
      case 'SAR':
        return 'ر.س';
      case 'EUR':
      default:
        return '€';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;

    final isSubscription = product.isSubscription;
    final hasDiscount = !isSubscription &&
        product.priceBefore != null &&
        product.priceBefore! > product.price;

    final priceText =
        "${product.price.toStringAsFixed(2)} ${_currencySymbol(product)}";

    final beforePriceText = product.priceBefore == null
        ? null
        : "${product.priceBefore!.toStringAsFixed(2)} ${_currencySymbol(product)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: (product.coverImage ?? '').trim().isNotEmpty
                        ? Image.network(
                            product.coverImage!.trim(),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.low,
                            loadingBuilder: (c, child, p) {
                              if (p == null) return child;
                              return Container(
                                color: cs.surfaceContainerHighest.withOpacity(0.35),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if ((product.description ?? '').trim().isNotEmpty)
                        Text(
                          (product.description ?? '').trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                      const SizedBox(height: 6),

                      // ✅ السعر + العملة من قاعدة البيانات
                      if (isSubscription) ...[
                        Text(
                          (product.price > 0) ? priceText : l10n.notAvailable,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              priceText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasDiscount && beforePriceText != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                beforePriceText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: cs.secondary,
              foregroundColor: Colors.black,
              elevation: 0,
              alignment: Alignment.center,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: onOpen,
            child: Text(
              isSubscription ? l10n.storeSubscribeNow : l10n.storeOrderNow,
            ),
          ),
        ),
      ],
    );
  }
}
