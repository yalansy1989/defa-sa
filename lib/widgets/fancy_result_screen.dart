import 'package:flutter/material.dart';
import 'package:defa_sa/widgets/smart_media_image.dart'; // ✅ دمج محرك الصور الذكي
import 'package:defa_sa/utils/media_processor.dart';

/**
 * ✅ شاشة النتائج الفاخرة لمشروع دِفا الرسمي (defa-sa-official)
 * تعرض تفاصيل نجاح الطلبات أو الفشل بنمط بصري ملكي.
 */
class FancyResultScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
  final Color tone;

  final String? orderId;
  final int? orderNumber;

  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;

  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  final String? imageUrl; // صورة المنتج (اختياري)
  final String? imageMediaId; // ✅ دعم MediaId للمشروع الرسمي

  const FancyResultScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.tone,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.orderId,
    this.orderNumber,
    this.imageUrl,
    this.imageMediaId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ خلفية متدرجة تعكس فخامة الهوية في بلجيكا
    final bg = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        tone.withOpacity(0.22),
        Colors.white.withOpacity(0.06),
        Colors.black.withOpacity(0.08),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("النتيجة"),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bg),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                color: theme.cardColor.withOpacity(0.06),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    color: Colors.black.withOpacity(0.20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge: ريح بالك
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                      color: Colors.black.withOpacity(0.20),
                    ),
                    child: Text(
                      "$emoji ريّح بالك",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Icon circle: مؤشر الحالة البصري
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tone.withOpacity(0.14),
                      border: Border.all(color: tone.withOpacity(0.40), width: 1.5),
                    ),
                    child: Icon(icon, size: 54, color: tone),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ✅ عرض صورة المنتج بذكاء (Cloudinary/Storage)
                  if ((imageMediaId ?? '').isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: SmartMediaImage(
                          mediaId: imageMediaId!,
                          useCase: MediaUseCase.product,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (imageUrl != null && imageUrl!.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black.withOpacity(0.12),
                            child: const Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                      ),
                    ),

                  if (((imageMediaId ?? '').isNotEmpty) || (imageUrl ?? '').isNotEmpty)
                    const SizedBox(height: 12),

                  // Order identifiers: تفاصيل الطلب
                  if (orderNumber != null || (orderId ?? '').trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                        color: Colors.white.withOpacity(0.06),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (orderNumber != null)
                            _kv("رقم الطلب", "#$orderNumber"),
                          if ((orderId ?? '').trim().isNotEmpty)
                            _kv("Order ID", orderId!.trim()),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Buttons: إجراءات المتابعة
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tone,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onPrimaryPressed,
                      child: Text(
                        primaryButtonText,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ),

                  if (secondaryButtonText != null && onSecondaryPressed != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.22)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onSecondaryPressed,
                        child: Text(
                          secondaryButtonText!,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
    );
  }

  static Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(v, textAlign: TextAlign.left)),
          const SizedBox(width: 12),
          Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}