import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:defa_sa/models/product.dart';
import 'package:defa_sa/services/products_service.dart';

class HomeCollectionSlider extends StatefulWidget {
  final String collectionId;
  final void Function(String productId)? onOpenProduct;

  const HomeCollectionSlider({
    super.key,
    required this.collectionId,
    this.onOpenProduct,
  });

  @override
  State<HomeCollectionSlider> createState() => _HomeCollectionSliderState();
}

class _HomeCollectionSliderState extends State<HomeCollectionSlider> with AutomaticKeepAliveClientMixin {
  final _pageCtrl = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _currentPage = 0;
  bool _isUserInteracting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isUserInteracting || !_pageCtrl.hasClients) return;

      _currentPage++;
      if (_currentPage >= count) {
        _currentPage = 0;
      }
      
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<Product>>(
      stream: ProductsService.streamActiveProducts().map((all) {
        return all.where((p) => 
          p.collectionId == widget.collectionId || 
          p.collectionIds.contains(widget.collectionId)
        ).toList();
      }),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();

        final allColProducts = snap.data!;
        var sliderProducts = allColProducts.where((p) => p.isFeatured).toList();
        
        if (sliderProducts.isEmpty) {
           sliderProducts = allColProducts.take(5).toList();
        }

        // إعادة تشغيل المؤقت عند تغير البيانات
        if (_timer == null || !_timer!.isActive) _startAutoScroll(sliderProducts.length);

        return SizedBox(
          height: 220, // زيادة الارتفاع قليلاً لاستيعاب تفاصيل السعر
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserInteracting = true;
              } else if (notification is ScrollEndNotification) {
                _isUserInteracting = false;
                if (_pageCtrl.hasClients && _pageCtrl.page != null) {
                   _currentPage = _pageCtrl.page!.round();
                }
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: sliderProducts.length,
              onPageChanged: (val) => _currentPage = val,
              itemBuilder: (context, idx) {
                final product = sliderProducts[idx];
                
                // حساب نسبة الخصم
                int discountPercent = 0;
                if (product.priceBefore != null && product.priceBefore! > product.price) {
                  discountPercent = (((product.priceBefore! - product.price) / product.priceBefore!) * 100).round();
                }

                return GestureDetector(
                  onTap: () => widget.onOpenProduct?.call(product.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // صورة المنتج
                          Image.network(
                            product.primaryImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Container(color: const Color(0xFF1A1A1A)),
                          ),

                          // تدرج لوني أغمق في الأسفل لتحسين وضوح النصوص
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.9)
                                ],
                              ),
                            ),
                          ),

                          // تفاصيل المنتج (الاسم والأسعار)
                          Positioned(
                            bottom: 15,
                            right: 20,
                            left: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${product.price} ر.س",
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFFE0C097),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (discountPercent > 0) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        "${product.priceBefore?.toInt()} ر.س",
                                        style: GoogleFonts.cairo(
                                          color: Colors.white38,
                                          fontSize: 12,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // شارة الخصم الفاخرة
                          if (discountPercent > 0)
                            Positioned(
                              top: 15,
                              right: 15,
                              child: FadeInRight(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                                  ),
                                  child: Text(
                                    "خصم $discountPercent%",
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // أيقونة مميز
                          Positioned(
                            top: 15,
                            left: 15,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE0C097).withOpacity(0.3))
                              ),
                              child: const Icon(Icons.star, color: Color(0xFFE0C097), size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}