import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/**
 * ✅ مكون عرض الصور الملكي لمشروع دِفا الرسمي (defa-sa-official)
 * تم تحسينه لمنع الوميض (Flicker) وضمان تجربة تصفح فخمة وسلسة.
 */
class CachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ضبط خلفية التحميل لتناسب هوية دِفا البصرية الفاخرة
    final bg = theme.colorScheme.surfaceContainerHighest.withOpacity(0.35);

    final clean = url.trim();
    
    // التعامل مع الروابط الفارغة بمعايير دِفا الرسمية
    if (clean.isEmpty) {
      return Container(
        color: bg,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 28, color: Colors.white24)
        ),
      );
    }

    // استخدام مزود الصور المخزنة مؤقتاً لضمان السرعة وتوفير البيانات
    final provider = CachedNetworkImageProvider(clean);

    /**
     * ✅ تقنية Gapless Playback:
     * تمنع ظهور مساحات فارغة عند تبديل الصور، مما يعطي إحساساً بالفخامة التقنية.
     */
    return Image(
      image: provider,
      fit: fit,
      gaplessPlayback: true, 
      filterQuality: FilterQuality.medium, // رفع الجودة لتناسب الهوية الرسمية
      
      // بناء واجهة التحميل الثابتة لضمان استقرار التصميم
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: bg,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white10),
            ),
          ),
        );
      },
      
      // معالجة الأخطاء في حالة فشل جلب الصورة من سحابة بلجيكا
      errorBuilder: (_, __, ___) => Container(
        color: bg,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.white24)
        ),
      ),
    );
  }
}