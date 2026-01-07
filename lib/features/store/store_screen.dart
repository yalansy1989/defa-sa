import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product.dart';
import '../products/product_details_screen.dart';
import '../auth/login_screen.dart';
import 'package:defa_sa/l10n/app_localizations.dart';
import 'package:defa_sa/widgets/price_text.dart'; 
import '../../widgets/smart_media_image.dart';
import '../../utils/media_processor.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const goldColor = Color(0xFFE0C097);
  static const deepDarkColor = Color(0xFF0A0E14);
  static const cardColor = Color(0xFF111827);

  String? _selectedCollectionId;
  String _selectedCollectionName = "الكل";

  void _showCategoriesFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: deepDarkColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("تصفية حسب القسم", style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('collections').where('isActive', isEqualTo: true).orderBy('order').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: goldColor));
                  
                  final docs = snapshot.data!.docs;
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, 
                      mainAxisSpacing: 15, 
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.8
                    ),
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _FilterItem(
                          title: "الكل",
                          isSelected: _selectedCollectionId == null,
                          onTap: () {
                            setState(() { _selectedCollectionId = null; _selectedCollectionName = "الكل"; });
                            Navigator.pop(ctx);
                          },
                          icon: Icons.apps,
                        );
                      }

                      final data = docs[index - 1].data() as Map<String, dynamic>;
                      final id = docs[index - 1].id;
                      final name = data['title'] ?? data['name'] ?? '';
                      final imageRef = data['coverImageId'] ?? data['icon'] ?? '';

                      return _FilterItem(
                        title: name,
                        isSelected: _selectedCollectionId == id,
                        mediaId: imageRef,
                        onTap: () {
                          setState(() { _selectedCollectionId = id; _selectedCollectionName = name; });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('visibility', whereIn: ['store', 'both']);

    if (_selectedCollectionId != null) {
      query = query.where('collectionIds', arrayContains: _selectedCollectionId);
    } else {
      query = query.orderBy('sort', descending: false).orderBy('createdAt', descending: true);
    }

    return Scaffold(
      backgroundColor: deepDarkColor, 
      appBar: AppBar(
        title: Column(
          children: [
            FadeInDown(
              child: Text(
                t.storeTitle, 
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22),
              ),
            ),
            if (_selectedCollectionId != null)
              FadeIn(
                child: Text(
                  "قسم: $_selectedCollectionName",
                  style: GoogleFonts.cairo(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCategoriesFilter, 
            icon: const Icon(Icons.sort_rounded, color: goldColor, size: 28),
            tooltip: "الأقسام",
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: goldColor, strokeWidth: 1.5));
          }

          if (snapshot.hasError) {
            return Center(child: Text("يرجى التأكد من الفهارس (Index)", style: GoogleFonts.cairo(color: Colors.white54)));
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, color: goldColor.withOpacity(0.15), size: 80),
                  const SizedBox(height: 24),
                  Text(
                    "لا توجد منتجات في هذا القسم", 
                    style: GoogleFonts.cairo(color: Colors.white30, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_selectedCollectionId != null)
                    TextButton(
                      onPressed: () => setState(() { _selectedCollectionId = null; _selectedCollectionName = "الكل"; }), 
                      child: Text("عرض الكل", style: GoogleFonts.cairo(color: goldColor))
                    )
                ],
              ),
            );
          }

          final products = docs.map((d) => Product.fromDoc(d)).toList();

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), 
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 25, 
              crossAxisSpacing: 15,
              childAspectRatio: 0.55, 
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _StoreProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}

class _StoreProductCard extends StatefulWidget {
  final Product product;
  const _StoreProductCard({required this.product});

  @override
  State<_StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends State<_StoreProductCard> {
  bool _isLoading = false;
  static const goldColor = Color(0xFFE0C097);

  Future<void> _addToCart() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _showLoginDialog();
      } else {
        final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(widget.product.id);
        final doc = await cartRef.get();

        if (doc.exists) {
          await cartRef.update({'quantity': FieldValue.increment(1)});
        } else {
          await cartRef.set({
            'productId': widget.product.id,
            'productName': widget.product.name,
            'unitPrice': widget.product.price,
            'quantity': 1,
            'imageMediaId': widget.product.imageMediaId,
            'imageUrl': widget.product.coverImage,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تمت إضافة ${widget.product.name} للسلة", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: goldColor,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showLoginDialog() async {
    setState(() => _isLoading = false);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ حساب نسبة الخصم برمجياً
    int discountPercent = 0;
    if (widget.product.priceBefore != null && widget.product.priceBefore! > widget.product.price) {
      discountPercent = (((widget.product.priceBefore! - widget.product.price) / widget.product.priceBefore!) * 100).round();
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: widget.product.id)));
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SmartMediaImage(
                        mediaId: widget.product.imageMediaId ?? '',
                        useCase: MediaUseCase.product,
                        fit: BoxFit.cover,
                      ),
                      // ✅ شارة الخصم الفاخرة
                      if (discountPercent > 0)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: FadeInLeft(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                              ),
                              child: Text(
                                "خصم $discountPercent%",
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: const Icon(Icons.info_outline, color: Colors.white, size: 16),
                        ),
                      )
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
                      widget.product.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    // ✅ السعر الحالي والسعر القديم
                    Row(
                      children: [
                        PriceText(
                          priceInEur: widget.product.price,
                          style: GoogleFonts.cairo(color: goldColor, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        if (discountPercent > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            "${widget.product.priceBefore?.toInt()}",
                            style: GoogleFonts.cairo(
                              color: Colors.white24,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_shopping_cart, size: 16),
                                const SizedBox(width: 4),
                                Text("أضف للسلة", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final String? mediaId;
  final IconData? icon;

  const _FilterItem({required this.title, required this.isSelected, required this.onTap, this.mediaId, this.icon});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFE0C097);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? goldColor : Colors.white12, width: isSelected ? 2 : 1),
              color: isSelected ? goldColor.withOpacity(0.1) : Colors.transparent,
            ),
            child: ClipOval(
              child: mediaId != null && mediaId!.isNotEmpty
                  ? SmartMediaImage(mediaId: mediaId!, useCase: MediaUseCase.banner, fit: BoxFit.cover)
                  : Icon(icon ?? Icons.grid_view, color: isSelected ? goldColor : Colors.white38),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: isSelected ? goldColor : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            ),
          )
        ],
      ),
    );
  }
}