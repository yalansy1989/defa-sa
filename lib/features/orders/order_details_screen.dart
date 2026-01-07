import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import 'package:defa_sa/models/cart_item.dart';
import 'package:defa_sa/features/home/order_confirm_page.dart';
import 'package:defa_sa/features/chat/chat_screen.dart'; // ✅ الاستيراد الصحيح
import 'package:defa_sa/services/order_service.dart';
import 'package:defa_sa/widgets/price_text.dart';

/// ✅ شاشة تفاصيل الطلب الملكية لمشروع دِفا
/// تم تحديث الصور لتملأ الكرت بالكامل وتعديل ربط الدردشة.
class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  // ألوان الهوية الملكية المعتمدة
  static const _bg = Color(0xFF0A0E14);
  static const _gold = Color(0xFFE0C097);
  static const _cardColor = Color(0xFF111827);

  CollectionReference<Map<String, dynamic>> _ordersCol() =>
      FirebaseFirestore.instance.collection('orders');

  List<Map<String, dynamic>> _asItems(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  List<CartItem> _toCartItems(List<Map<String, dynamic>> items) {
    return items.map((m) {
      return CartItem(
        productId: (m['productId'] ?? m['id'] ?? '').toString(),
        productName: (m['productName'] ?? m['name'] ?? m['title'] ?? 'منتج دِفا').toString(),
        unitPrice: (m['unitPrice'] is num) ? (m['unitPrice'] as num).toDouble() : 0.0,
        quantity: (m['quantity'] is num) ? (m['quantity'] as num).toInt() : 1,
      );
    }).toList();
  }

  double _num(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تفاصيل الطلب الملكي',
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontStyle: FontStyle.italic,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ordersCol().doc(orderId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('تعذر جلب بيانات الطلب من السحابة', style: TextStyle(color: Colors.white38)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 1.5));
          }
          final doc = snap.data!;
          if (!doc.exists) {
            return const Center(child: Text('الطلب غير موجود في قاعدة بيانات دِفا', style: TextStyle(color: Colors.white38)));
          }

          final data = doc.data() ?? {};
          final orderNumber = (data['orderNumber'] ?? data['number'] ?? '').toString();
          final status = (data['status'] ?? 'قيد المراجعة').toString();
          final currency = (data['currency'] ?? 'SAR').toString();
          final items = _asItems(data['items']);
          final subtotal = _num(data['subtotal']);
          final total = _num(data['total']);
          final notes = (data['notes'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            physics: const BouncingScrollPhysics(),
            children: [
              FadeInDown(
                child: _HeaderCard(
                  orderNumber: orderNumber.isEmpty ? orderId : orderNumber,
                  status: status,
                ),
              ),
              const SizedBox(height: 24),

              _SectionTitle('محتويات الطلب'),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _EmptyCard(text: 'لا توجد منتجات مسجلة في هذا الطلب')
              else
                ...items.map((it) => FadeInLeft(
                  child: _ItemTile(
                    name: (it['productName'] ?? it['name'] ?? 'منتج دِفا الفاخر').toString(),
                    qty: (it['quantity'] is num) ? (it['quantity'] as num).toInt() : 1,
                    price: _num(it['unitPrice']),
                    currency: currency,
                    imageUrl: (it['imageUrl'] ?? it['productImage'] ?? '').toString(),
                  ),
                )),

              const SizedBox(height: 24),
              _SectionTitle('الملخص المالي'),
              const SizedBox(height: 12),
              FadeInUp(
                child: _SummaryCard(
                  currency: currency,
                  subtotal: subtotal,
                  total: total == 0 ? subtotal : total,
                ),
              ),

              if (notes.trim().isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionTitle('ملاحظاتك الخاصة'),
                const SizedBox(height: 12),
                _InfoCard(text: notes),
              ],

              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 4,
                        shadowColor: _gold.withOpacity(0.3),
                      ),
                      onPressed: () {
                        // ✅ الربط الصحيح: فتح محادثة خاصة بهذا الطلب
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen.order(
                              orderNumber: orderNumber.isEmpty ? orderId : orderNumber,
                              orderDocId: orderId,
                              orderTitle: 'متابعة الطلب #$orderNumber',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 22),
                      label: const Text('تواصل مع الدعم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: items.isEmpty ? null : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderConfirmPage(
                              customerId: (data['customerId'] ?? '').toString(),
                              customerName: (data['customerName'] ?? 'عميل دِفا').toString(),
                              customerPhone: (data['customerPhone'] ?? '').toString(),
                              cartItems: _toCartItems(items),
                              total: total == 0 ? subtotal : total,
                              shippingAddress: (data['shippingAddress'] is Map)
                                  ? Map<String, dynamic>.from(data['shippingAddress'])
                                  : const {'city': 'توصيل سريع', 'line1': 'عنوان مسجل سابقاً'},
                              notes: "إعادة طلب سابق رقم: $orderNumber",
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 22),
                      label: const Text('إعادة الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Center(
                child: Opacity(
                  opacity: 0.15,
                  child: Text(
                    "دِفا - فخامة الخدمة والاهتمام بالتفاصيل",
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
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

class _HeaderCard extends StatelessWidget {
  final String orderNumber;
  final String status;
  const _HeaderCard({required this.orderNumber, required this.status});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFE0C097);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: goldColor.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.receipt_long_rounded, color: goldColor, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('طلب رقم #$orderNumber', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                  child: Text(status, style: const TextStyle(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5));
  }
}

class _ItemTile extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  final String currency;
  final String imageUrl;

  const _ItemTile({required this.name, required this.qty, required this.price, required this.currency, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // ✅ تعديل الكرت ليظهر الصورة كاملة وبدون مساحات فارغة
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 80, height: 80, // زيادة الحجم قليلاً للفخامة
              color: Colors.white.withOpacity(0.03),
              child: (imageUrl.isEmpty)
                  ? const Icon(Icons.image_outlined, color: Colors.white12)
                  : Image.network(
                      imageUrl, 
                      fit: BoxFit.cover, // ✅ تملأ الكرت بالكامل وتزيل المساحات الفارغة
                      width: double.infinity, 
                      height: double.infinity,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 8),
                Text('الكمية: $qty', style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          PriceText(
            priceInEur: price * qty,
            style: const TextStyle(color: Color(0xFFE0C097), fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String currency;
  final double subtotal;
  final double total;
  const _SummaryCard({required this.currency, required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _SummaryRow(label: 'المجموع الفرعي', amount: subtotal, currency: currency),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white10, thickness: 1.2),
          ),
          _SummaryRow(label: 'الإجمالي النهائي', amount: total, currency: currency, isTotal: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isTotal;
  const _SummaryRow({required this.label, required this.amount, required this.currency, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white54, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, fontSize: isTotal ? 17 : 14)),
        PriceText(
          priceInEur: amount,
          style: TextStyle(color: isTotal ? const Color(0xFFE0C097) : Colors.white, fontWeight: FontWeight.w900, fontSize: isTotal ? 20 : 15),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.05))),
      padding: const EdgeInsets.all(18),
      child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.7, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(22)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold))),
    );
  }
}