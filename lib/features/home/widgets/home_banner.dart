import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:defa_sa/l10n/app_localizations.dart';

import 'package:defa_sa/models/store_banner.dart';
import 'package:defa_sa/services/store_settings_service.dart';
import 'package:defa_sa/services/analytics_service.dart';

import 'package:defa_sa/widgets/smart_media_image.dart';
import 'package:defa_sa/utils/media_processor.dart';

class HomeBanner extends StatefulWidget {
  final void Function(String productId)? onOpenProduct;

  const HomeBanner({super.key, this.onOpenProduct});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> with SingleTickerProviderStateMixin {
  bool _viewLogged = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // ✅ زيادة المدة الزمنية إلى 15 ثانية لجعل الحركة بطيئة وملكيه
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    // ✅ استخدام Curve أكثر نعومة (easeOutQuart) لمنع الارتعاش عند نقاط التحول
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.0, 1.0, curve: Curves.linear), // خطي لضمان ثبات الإطارات
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAction(BuildContext context, StoreBanner banner) async {
    try {
      await AnalyticsService.log(
        type: 'banner_click',
        source: 'home',
        targetType: 'banner',
        targetId: 'banner_main',
      );
    } catch (_) {}

    final a = banner.action;
    if (a.type == 'product' && a.productId != null && a.productId!.isNotEmpty) {
      widget.onOpenProduct?.call(a.productId!);
      return;
    }
    if (a.type == 'link' && a.url != null && a.url!.isNotEmpty) {
      final uri = Uri.tryParse(a.url!);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    const goldColor = Color(0xFFE0C097);
    const deepDarkColor = Color(0xFF0A0E14);

    return StreamBuilder<StoreBanner?>(
      stream: StoreSettingsService.bannerStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final banner = snap.data;
        if (banner == null || !banner.isActive) return const SizedBox.shrink();

        if (!_viewLogged) {
          _viewLogged = true;
          AnalyticsService.log(
            type: 'banner_view',
            source: 'home',
            targetType: 'banner',
            targetId: 'banner_main',
          ).catchError((_) {});
        }

        return FadeIn(
          duration: const Duration(seconds: 1),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
            width: double.infinity,
            height: 220, 
            decoration: BoxDecoration(
              color: deepDarkColor,
              borderRadius: BorderRadius.circular(24), 
              border: Border.all(color: goldColor.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ إضافة طبقة عازلة للرسم لتحسين الأداء ومنع الارتعاش
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          // ✅ استخدام filter بجودة عالية لمنع تكسر البكسلات أثناء الزوم
                          filterQuality: FilterQuality.high,
                          child: child,
                        );
                      },
                      child: Builder(
                        builder: (context) {
                          if (banner.imageMediaId != null && banner.imageMediaId!.isNotEmpty) {
                            return SmartMediaImage(
                              mediaId: banner.imageMediaId!,
                              useCase: MediaUseCase.banner,
                              fit: BoxFit.cover,
                            );
                          } else if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty) {
                            return Image.network(banner.imageUrl!, fit: BoxFit.cover);
                          }
                          return Container(color: deepDarkColor);
                        },
                      ),
                    ),
                  ),
                  // ✅ تدرج ظلي (Gradient) محسن لزيادة فخامة النصوص
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ عنوان فخم مع تأثير FadeIn من animate_do
                        FadeInRight(
                          duration: const Duration(milliseconds: 800),
                          child: Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo( // استخدام خط كاريو للفخامة
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (banner.action.type != 'none')
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 200),
                            child: InkWell(
                              onTap: () => _handleAction(context, banner),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  // ✅ خلفية ذهبية ملكية للزر مع تأثير زجاجي
                                  gradient: const LinearGradient(
                                    colors: [goldColor, Color(0xFFB49673)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: goldColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      banner.action.buttonText ?? l10n.storeOrderNow,
                                      style: GoogleFonts.cairo(
                                        color: deepDarkColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.arrow_forward_ios, color: deepDarkColor, size: 14),
                                  ],
                                ),
                              ),
                            ),
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
  }
}