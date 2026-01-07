import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ 1. تم تصحيح مسار استيراد تفاصيل الطلب حسب مسارك
import 'package:defa_sa/features/orders/order_details_screen.dart'; 

// ❌ 2. تم حذف استيراد الهوم سكرين لأنه غير مستخدم (نستخدم '/' بدلاً منه)

enum OrderResultStatus { success, failed, sent }

class OrderResultScreen extends StatelessWidget {
  final OrderResultStatus status;
  final String title;
  final String message;
  final String orderNumber;
  
  // معرف الطلب لفتح التفاصيل
  final String? orderId; 

  final String? secondaryMessage;

  final VoidCallback? onPrimary;
  final String primaryText;

  final VoidCallback? onSecondary;
  final String? secondaryText;

  const OrderResultScreen({
    super.key,
    required this.status,
    required this.title,
    required this.message,
    required this.orderNumber,
    this.orderId,
    this.secondaryMessage,
    this.onPrimary,
    this.primaryText = "العودة للرئيسية",
    this.onSecondary,
    this.secondaryText,
  });

  // الألوان الملكية
  static const Color goldColor = Color(0xFFE0C097);
  static const Color deepDarkColor = Color(0xFF0A0E14);

  String get _emoji {
    switch (status) {
      case OrderResultStatus.success:
        return "🎉";
      case OrderResultStatus.sent:
        return "📩";
      case OrderResultStatus.failed:
        return "⚠️";
    }
  }

  String get _pillLabel {
    switch (status) {
      case OrderResultStatus.success:
        return "تم بنجاح";
      case OrderResultStatus.sent:
        return "تم الإرسال";
      case OrderResultStatus.failed:
        return "لم يكتمل";
    }
  }

  Color get _statusColor {
    switch (status) {
      case OrderResultStatus.success:
        return Colors.greenAccent;
      case OrderResultStatus.sent:
        return goldColor;
      case OrderResultStatus.failed:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepDarkColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              deepDarkColor,
              const Color(0xFF111827), 
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TopBadge(
                        emoji: _emoji, 
                        label: _pillLabel, 
                        color: _statusColor
                      ),
                      const SizedBox(height: 24),

                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),

                      if (secondaryMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          secondaryMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _OrderNumberBox(orderNumber: orderNumber),
                      const SizedBox(height: 32),

                      // زر العودة للرئيسية
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: onPrimary ?? () {
                            // ✅ العودة للرئيسية باستخدام الروت المسمى (Named Route)
                            // هذا يغنيك عن استيراد ملف الهوم سكرين
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            primaryText,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                      // زر عرض تفاصيل الطلب
                      if (secondaryText != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: onSecondary ?? () {
                              if (orderId != null) {
                                // ✅ فتح صفحة تفاصيل الطلب (الآن المسار صحيح)
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(orderId: orderId!),
                                  ), // تأكد أن OrderDetailsScreen تستقبل orderId كمتغير
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("رقم الطلب غير متوفر", style: GoogleFonts.cairo())),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              secondaryText!,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 40,
            offset: const Offset(0, 20),
            color: Colors.black.withOpacity(0.4),
          )
        ],
      ),
      child: child,
    );
  }
}

class _TopBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _TopBadge({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderNumberBox extends StatelessWidget {
  final String orderNumber;
  const _OrderNumberBox({required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: const Color(0xFFE0C097).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Color(0xFFE0C097)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "رقم الطلب المرجعي",
                  style: GoogleFonts.cairo(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  orderNumber,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}