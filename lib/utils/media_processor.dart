/**
 * ✅ معالج الوسائط الملكي لمشروع دِفا الرسمي (defa-sa-official)
 * يقوم بضبط أبعاد الصور وجودتها برمجياً لضمان سرعة التحميل وفخامة العرض.
 */
enum MediaUseCase { logo, banner, slider, product }

class MediaProcessor {
  /**
   * ✅ توليد رابط الصورة المحسن بناءً على نوع الاستخدام
   * يدعم الربط مع Cloudinary وسحابة بلجيكا (Firebase Storage).
   */
  static String urlFor(String rawUrl, MediaUseCase useCase) {
    final cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) return '';

    // إذا كان الرابط لا يحتوي على وسم الرفع الخاص بـ Cloudinary، نرجعه كما هو
    // هذا يضمن عمل روابط Firebase Storage في بلجيكا بنجاح
    if (!cleanUrl.contains("/upload/")) {
      return cleanUrl;
    }

    // تحديد الأبعاد المثالية لكل حالة استخدام لضمان الفخامة التقنية
    int w, h;
    switch (useCase) {
      case MediaUseCase.logo:
        w = 512; h = 512; break;
      case MediaUseCase.banner:
        w = 1440; h = 560; break;
      case MediaUseCase.slider:
        w = 1200; h = 675; break;
      case MediaUseCase.product:
        w = 1024; h = 1024; break;
    }

    try {
      final parts = cleanUrl.split("/upload/");
      final prefix = parts.first;
      final suffix = parts.sublist(1).join("/upload/");

      /**
       * تحسين الصورة فورياً (On-the-fly Transformation):
       * f_auto: اختيار أفضل صيغة (مثل WebP)
       * q_auto:good: جودة عالية مع حجم ملف صغير
       * c_fill, g_auto: ملء المساحة مع التركيز التلقائي على محتوى الصورة
       */
      final transform = "f_auto,q_auto:good,c_fill,g_auto,w_$w,h_$h";
      
      return "$prefix/upload/$transform/$suffix";
    } catch (e) {
      // في حال حدوث خطأ في المعالجة، نرجع الرابط الأصلي لضمان عدم تعطل التطبيق
      return cleanUrl;
    }
  }
}