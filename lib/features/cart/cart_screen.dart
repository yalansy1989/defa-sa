import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:defa_sa/models/cart_item.dart';
import 'package:defa_sa/widgets/smart_media_image.dart';
import 'package:defa_sa/widgets/price_text.dart';
import 'package:defa_sa/features/home/order_confirm_page.dart';
import 'package:defa_sa/l10n/app_localizations.dart';
import 'package:defa_sa/utils/media_processor.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _removeFromCart(String userId, String itemId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .delete();
  }

  Future<void> _updateQuantity(String userId, String itemId, int current, int change) async {
    final newQty = current + change;
    if (newQty < 1) return;
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .update({'quantity': newQty});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const goldColor = Color(0xFFE0C097);

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E14),
        body: Center(
          child: Text(
            "يرجى تسجيل الدخول لعرض السلة",
            style: GoogleFonts.cairo(color: Colors.white54),
          ),
        ),
      );
    }

    final cartQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        title: Text(
          "سلة المشتريات",
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E14),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: goldColor));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 20),
                  Text(
                    "السلة فارغة حالياً",
                    style: GoogleFonts.cairo(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // ✅ تصحيح الخطأ الأول: إزالة المتغير الثاني (d.id) لأن المودل يقبل متغيراً واحداً
          final cartItems = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return CartItem.fromMap(data); 
          }).toList();

          double total = 0;
          for (var item in cartItems) {
            total += (item.unitPrice * item.quantity);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 50),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: SmartMediaImage(
                                  mediaId: item.imageMediaId ?? '',
                                  // ✅ تصحيح الخطأ الثاني: استبدال thumbnail بـ product
                                  useCase: MediaUseCase.product,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  PriceText(
                                    priceInEur: item.unitPrice,
                                    style: GoogleFonts.cairo(
                                      color: goldColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _updateQuantity(user.uid, docs[index].id, item.quantity, -1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.remove, color: Colors.white70, size: 16),
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      InkWell(
                                        onTap: () => _updateQuantity(user.uid, docs[index].id, item.quantity, 1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.add, color: Colors.white70, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _removeFromCart(user.uid, docs[index].id),
                                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5))
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('إجمالي السلة', style: GoogleFonts.cairo(color: Colors.white70)),
                          PriceText(
                            priceInEur: total,
                            style: GoogleFonts.cairo(color: goldColor, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderConfirmPage(
                                  customerId: user.uid,
                                  customerName: user.displayName ?? 'عميل',
                                  customerPhone: '',
                                  cartItems: cartItems,
                                  total: total,
                                  shippingAddress: const {'city': 'Riyadh'},
                                  notes: '',
                                ),
                              ),
                            );
                          },
                          // ✅ استخدام FittedBox لضبط النص
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'إتمام الشراء (${cartItems.length})',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, 
                                fontSize: 16,
                                height: 1.2, 
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}