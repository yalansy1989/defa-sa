import 'package:flutter/material.dart';
import 'package:defa_sa/models/product.dart';
import 'package:defa_sa/widgets/app_button_styles.dart';

// ✅ حل نهائي: استيراد نسبي + alias لضمان فخامة استدعاء الصور المحسنة
import 'smart_media_image.dart' as sm;

import 'package:defa_sa/utils/media_processor.dart';
import 'package:defa_sa/widgets/price_text.dart'; // ✅ ويدجت السعر المعتمد على الأدمن

/**
 * ✅ بطاقة المنتج الملكية لمشروع دِفا الرسمي (defa-sa-official)
 * تم التحديث: توحيد الزر ليكون "أضف للسلة" فقط لجميع المنتجات.
 */
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  /// ✅ الاسم الجديد للأكشن الموحد
  final VoidCallback? onAction;

  /// ✅ الاسم القديم لضمان عدم تعطل ملفات المشروع السابقة
  final VoidCallback? onPrimaryAction;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAction,
    this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final action = onAction ?? onPrimaryAction;

    // ✅ حساب الخصم للعرض فقط
    final hasDiscount = product.priceBefore != null &&
        product.priceBefore! > product.price;

    final hasMediaId =
        (product.imageMediaId != null && product.imageMediaId!.trim().isNotEmpty);
    final hasCoverUrl =
        (product.coverImage != null && product.coverImage!.trim().isNotEmpty);

    // ✅ توحيد نص الزر (تم إلغاء اشترك وتواصل)
    const actionLabel = "أضف للسلة";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: hasMediaId
                        ? sm.SmartMediaImage(
                            mediaId: product.imageMediaId!,
                            useCase: MediaUseCase.product,
                            fit: BoxFit.cover,
                          )
                        : hasCoverUrl
                            ? Image.network(
                                product.coverImage!.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade300,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ✅ عرض السعر دائماً بدون شروط
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // السعر الحالي
                          PriceText(
                            priceInEur: product.price,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // السعر السابق (إذا وجد خصم)
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            PriceText(
                              priceInEur: product.priceBefore!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        
        // ✅ زر موحد لجميع المنتجات
        if (action != null)
          SizedBox(
            height: 40,
            child: ElevatedButton(
              style: AppButtonStyles.primaryRounded(context, 999),
              onPressed: action,
              child: const Text(actionLabel),
            ),
          ),
      ],
    );
  }
}