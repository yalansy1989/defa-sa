import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:defa_sa/widgets/smart_media_image.dart'; 
import 'package:defa_sa/utils/media_processor.dart';
import 'package:defa_sa/features/products/product_details_screen.dart';

class CollectionDetailsScreen extends StatelessWidget {
  final String collectionId;
  final String? collectionTitle;

  const CollectionDetailsScreen({
    super.key,
    required this.collectionId,
    this.collectionTitle,
  });

  @override
  Widget build(BuildContext context) {
    // استعلام المنتجات المرتبطة بالمجموعة
    final productQuery = FirebaseFirestore.instance
        .collection('products')
        .where('collectionIds', arrayContains: collectionId)
        .where('isActive', isEqualTo: true);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E14),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: collectionTitle != null && collectionTitle!.isNotEmpty
            ? Text(
                collectionTitle!,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('collections')
                    .doc(collectionId)
                    .snapshots(),
                builder: (context, snapshot) {
                  String dynamicTitle = 'المجموعة'; 
                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    dynamicTitle = data['title'] ?? data['name'] ?? 'المجموعة';
                  }
                  
                  return Text(
                    dynamicTitle,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE0C097)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.manage_search_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    "لم يتم العثور على منتجات في هذا القسم",
                    style: GoogleFonts.cairo(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62, // تم تعديل النسبة قليلاً لاستيعاب السعرين
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              
              // استخراج الصورة
              final String imageId = data['imageMediaId'] ?? 
                                   data['mediaId'] ?? 
                                   data['coverImageId'] ?? 
                                   data['imageUrl'] ?? 
                                   data['image'] ?? 
                                   '';

              // ✅ حساب نسبة الخصم
              int discountPercent = 0;
              num price = data['price'] ?? 0;
              num? priceBefore = data['priceBefore'];
              if (priceBefore != null && priceBefore > price && priceBefore > 0) {
                discountPercent = (((priceBefore - price) / priceBefore) * 100).round();
              }

              return FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: Duration(milliseconds: index * 50),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(productId: productId),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // صورة المنتج
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SmartMediaImage(
                                  mediaId: imageId,
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
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // زر المفضلة
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // تفاصيل المنتج
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? data['title'] ?? 'منتج فاخر',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (discountPercent > 0)
                                        Text(
                                          "${data['priceBefore']} ر.س",
                                          style: GoogleFonts.cairo(
                                            color: Colors.white30,
                                            fontSize: 10,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        "${data['price'] ?? 0} ر.س",
                                        style: GoogleFonts.cairo(
                                          color: const Color(0xFFE0C097),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0C097),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}