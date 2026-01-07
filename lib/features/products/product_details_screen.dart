import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ لإضافة للسلة
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:defa_sa/models/product.dart';
import 'package:defa_sa/services/products_service.dart';
import 'package:defa_sa/features/auth/login_screen.dart';
import 'package:defa_sa/widgets/price_text.dart';
import 'package:defa_sa/l10n/app_localizations.dart';
import 'package:defa_sa/widgets/smart_media_image.dart';
import 'package:defa_sa/utils/media_processor.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const _bg = Color(0xFF0A0E14);
  static const _card = Color(0xFF111827);
  static const _gold = Color(0xFFE0C097);

  bool _isAddingToCart = false; // حالة تحميل الزر

  Future<User?> _requireLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('دخول الأعضاء', style: GoogleFonts.cairo(color: _gold, fontWeight: FontWeight.w900)),
          content: Text('يرجى تسجيل الدخول لإضافة المنتجات للسلة.', style: GoogleFonts.cairo(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white38))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx, true), 
              child: Text('دخول', style: GoogleFonts.cairo(fontWeight: FontWeight.w900))
            ),
          ],
        ),
      ),
    );

    if (go == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
    return FirebaseAuth.instance.currentUser;
  }

  // ✅ دالة الإضافة للسلة في الفايربيس
  Future<void> _addToCart(Product product) async {
    final user = await _requireLogin();
    if (user == null) return;

    setState(() => _isAddingToCart = true);

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(product.id);

      final doc = await cartRef.get();

      if (doc.exists) {
        // المنتج موجود، نزيد الكمية
        await cartRef.update({
          'quantity': FieldValue.increment(1),
        });
      } else {
        // منتج جديد
        await cartRef.set({
          'productId': product.id,
          'productName': product.name,
          'unitPrice': product.price,
          'quantity': 1,
          'imageMediaId': product.imageMediaId,
          'imageUrl': product.coverImage,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تمت الإضافة للسلة بنجاح", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: _gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), 
              onPressed: () => Navigator.pop(context)
            ),
          ),
        ),
      ),
      body: StreamBuilder<Product?>(
        stream: ProductsService.streamProductById(widget.productId),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('خطأ', style: TextStyle(color: _gold)));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _gold));

          final product = snap.data!;
          
          // تجميع الصور
          final allImages = <String>[];
          final allMediaIds = <String>[];
          
          if (product.imageMediaId != null) {
             allMediaIds.add(product.imageMediaId!);
             allImages.add(''); 
          } else if (product.coverImage != null) {
             allImages.add(product.coverImage!);
             allMediaIds.add(''); 
          }
          
          if (product.galleryMediaIds.isNotEmpty) {
             allMediaIds.addAll(product.galleryMediaIds);
             allImages.addAll(List.filled(product.galleryMediaIds.length, ''));
          } else {
             allImages.addAll(product.images);
             allMediaIds.addAll(List.filled(product.images.length, ''));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _ProductGallery(images: allImages, mediaIds: allMediaIds),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, height: 1.2),
                          ),
                          const SizedBox(height: 12),
                          _PriceTag(price: product.price, before: product.priceBefore, currency: product.currency),
                          const SizedBox(height: 32),
                          Text('عن المنتج', style: GoogleFonts.cairo(color: _gold.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 12),
                          Text(
                            product.description.isEmpty ? 'لا يوجد وصف.' : product.description,
                            style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.7), height: 1.8, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // ✅ زر الإضافة للسلة المحدث
              _BottomAction(
                price: product.price,
                currency: product.currency,
                buttonText: _isAddingToCart ? "جاري الإضافة..." : "إضافة للسلة",
                isLoading: _isAddingToCart,
                onTap: () => _addToCart(product),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductGallery extends StatelessWidget {
  final List<String> images;
  final List<String> mediaIds;

  const _ProductGallery({required this.images, required this.mediaIds});

  @override
  Widget build(BuildContext context) {
    final count = mediaIds.isNotEmpty ? mediaIds.length : images.length;
    final safeCount = count == 0 ? 1 : count;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: safeCount,
            itemBuilder: (context, index) {
              final mid = (mediaIds.isNotEmpty && index < mediaIds.length) ? mediaIds[index] : '';
              final url = (images.isNotEmpty && index < images.length) ? images[index] : '';

              return Container(
                color: Colors.black,
                child: mid.isNotEmpty
                    ? SmartMediaImage(
                        mediaId: mid,
                        useCase: MediaUseCase.product,
                        fit: BoxFit.contain,
                      )
                    : (url.isNotEmpty 
                        ? Image.network(url, fit: BoxFit.contain)
                        : const Icon(Icons.image_outlined, color: Colors.white10, size: 80)
                    ),
              );
            },
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF0A0E14), Colors.transparent])
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final double price;
  final double? before;
  final String? currency;

  const _PriceTag({required this.price, this.before, this.currency});

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = before != null && before! > price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PriceText(
          priceInEur: price, 
          style: GoogleFonts.cairo(color: const Color(0xFFE0C097), fontWeight: FontWeight.w900, fontSize: 24),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 12),
          Text(
            before!.toStringAsFixed(0),
            style: GoogleFonts.cairo(color: Colors.white24, decoration: TextDecoration.lineThrough, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ]
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  final double price;
  final String? currency;
  final String buttonText;
  final VoidCallback onTap;
  final bool isLoading;

  const _BottomAction({
    required this.price, 
    this.currency,
    required this.buttonText, 
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سعر الوحدة', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              PriceText(
                 priceInEur: price, 
                 style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0C097),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: isLoading ? null : onTap,
                child: Center(
                  child: isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Text(
                        buttonText, 
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}