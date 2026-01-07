import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';

import 'package:defa_sa/models/product.dart';
import 'package:defa_sa/widgets/smart_media_image.dart';
import 'package:defa_sa/utils/media_processor.dart';
import 'package:defa_sa/widgets/price_text.dart';
import 'package:defa_sa/features/products/collection_details_screen.dart';

class HomeDynamicSections extends StatelessWidget {
  final void Function(String productId) onOpenProduct;

  const HomeDynamicSections({
    super.key,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final sectionsQuery = FirebaseFirestore.instance
        .collection('collections')
        .where('isActive', isEqualTo: true)
        .orderBy('order');

    return StreamBuilder<QuerySnapshot>(
      stream: sectionsQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final collections = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'];
          return type != 'category'; 
        }).toList();

        if (collections.isEmpty) return const SizedBox.shrink();

        return Column(
          children: collections.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ProductGroupSection(
              collectionId: doc.id,
              title: data['title'] ?? data['name'] ?? '',
              subtitle: data['description'] ?? '',
              onOpenProduct: onOpenProduct,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProductGroupSection extends StatefulWidget {
  final String collectionId;
  final String title;
  final String subtitle;
  final void Function(String) onOpenProduct;

  const _ProductGroupSection({
    required this.collectionId,
    required this.title,
    required this.subtitle,
    required this.onOpenProduct,
  });

  @override
  State<_ProductGroupSection> createState() => _ProductGroupSectionState();
}

class _ProductGroupSectionState extends State<_ProductGroupSection> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  static const double _itemWidth = 162; // عرض الكارد (150) + السبيسر (12)
  static const Duration _interval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      final next = current + _itemWidth;

      if (next >= maxScroll + (_itemWidth / 2)) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.animateTo(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsQuery = FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('collectionIds', arrayContains: widget.collectionId);

    return StreamBuilder<QuerySnapshot>(
      stream: productsQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final products = snapshot.data!.docs
            .map((d) => Product.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: widget.title, 
              subtitle: widget.subtitle,
              collectionId: widget.collectionId,
            ),
            
            SizedBox(
              height: 240,
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction != ScrollDirection.idle) {
                    _timer?.cancel();
                  } else {
                    _startAutoScroll();
                  }
                  return false;
                },
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return SizedBox(
                      width: 150,
                      child: _SimpleProductCard(
                        product: p,
                        onTap: () => widget.onOpenProduct(p.id),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String collectionId;

  const _SectionHeader({
    required this.title, 
    required this.subtitle,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollectionDetailsScreen(collectionId: collectionId),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE0C097),
            ),
            child: Text(
              "مشاهدة الكل",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _SimpleProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFE0C097);
    
    int discountPercent = 0;
    if (product.priceBefore != null && product.priceBefore! > product.price) {
      discountPercent = ((product.priceBefore! - product.price) / product.priceBefore! * 100).round();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmartMediaImage(
                      mediaId: product.imageMediaId ?? '',
                      useCase: MediaUseCase.product,
                      fit: BoxFit.cover,
                    ),
                    if (discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)
                            ],
                          ),
                          child: Text(
                            "خصم $discountPercent%",
                            style: GoogleFonts.cairo(
                              color: Colors.white, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              height: 1.2
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      PriceText(
                        priceInEur: product.price,
                        style: GoogleFonts.cairo(
                          color: goldColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (product.priceBefore != null && product.priceBefore! > product.price)
                        Text(
                          "${product.priceBefore!.toInt()}",
                          style: GoogleFonts.cairo(
                            color: Colors.white30,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}