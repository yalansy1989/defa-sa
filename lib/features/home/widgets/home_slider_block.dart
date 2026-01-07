import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:defa_sa/models/product.dart';
import 'package:defa_sa/services/products_service.dart';
import 'package:defa_sa/l10n/app_localizations.dart';
import 'package:defa_sa/widgets/smart_media_image.dart' as sm;
import 'package:defa_sa/utils/media_processor.dart';
import 'package:defa_sa/widgets/price_text.dart';

class HomeSliderBlock extends StatefulWidget {
  final String sliderId; 
  final String? headerTitle;
  final void Function(String productId) onOpenProduct;

  const HomeSliderBlock({
    super.key,
    required this.sliderId,
    required this.onOpenProduct,
    this.headerTitle,
  });

  @override
  State<HomeSliderBlock> createState() => _HomeSliderBlockState();
}

class _HomeSliderBlockState extends State<HomeSliderBlock> with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  final _page = PageController(viewportFraction: 1.0);
  int _current = 0;

  @override
  bool get wantKeepAlive => true;

  void _startAuto(int seconds, int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(Duration(seconds: seconds.clamp(2, 20)), (_) {
        if (!mounted) return;
        _current = (_current + 1) % count;
        if (_page.hasClients) {
          _page.animateToPage(_current, duration: const Duration(milliseconds: 800), curve: Curves.fastOutSlowIn);
        }
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    // ✅ الترتيب عبر السيرفر (الأفضل)
    final slidersQuery = FirebaseFirestore.instance
        .collection('sliders')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: slidersQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: Color(0xFFE0C097))));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final raw = snapshot.data!.docs.map((d) => {'id': d.id, ...d.data()}).toList();

        if (_timer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAuto(4, raw.length));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((widget.headerTitle ?? '').trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(widget.headerTitle!, textAlign: TextAlign.right, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _page,
                itemCount: raw.length,
                onPageChanged: (i) => _current = i,
                itemBuilder: (context, i) {
                  final it = raw[i];
                  final title = (it['title'] ?? '').toString();
                  final imageId = (it['imageId'] ?? '').toString(); 
                  final imageUrl = (it['imageUrl'] ?? '').toString();
                  final linkedProductId = (it['linkedProductId'] ?? '').toString();
                  final externalLink = (it['link'] ?? '').toString();
                  bool isProduct = linkedProductId.isNotEmpty;
                  bool isLink = !isProduct && externalLink.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _SlideCard(
                      title: title,
                      imageId: imageId.isNotEmpty ? imageId : null,
                      fallbackUrl: imageUrl,
                      // ✅ تم التعديل هنا: استبدال "منتج" بـ "اضف للسلة" للمنتجات المرتبطة
                      badge: isProduct ? "أضف للسلة" : (isLink ? t.sliderBadgeLink : null),
                      onTap: () async {
                        if (isProduct) {
                          widget.onOpenProduct(linkedProductId);
                        } else if (isLink) {
                          final uri = Uri.tryParse(externalLink);
                          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      footer: isProduct
                          ? StreamBuilder<Product?>(
                              stream: ProductsService.streamProductById(linkedProductId),
                              builder: (context, pSnap) => (pSnap.data == null) ? const SizedBox.shrink() : _ProductFooter(p: pSnap.data!),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _ProductFooter extends StatelessWidget {
  final Product p;
  const _ProductFooter({required this.p});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0C097).withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.shopping_bag_outlined, color: Color(0xFFE0C097), size: 16), const SizedBox(width: 8), PriceText(priceInEur: p.price, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900))]),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final String title;
  final String? badge;
  final String? imageId;
  final String? fallbackUrl;
  final VoidCallback? onTap;
  final Widget footer;
  const _SlideCard({required this.title, this.badge, required this.footer, this.imageId, this.fallbackUrl, this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF0A0E14), border: Border.all(color: const Color(0xFFE0C097).withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageId != null && imageId!.trim().isNotEmpty) sm.SmartMediaImage(mediaId: imageId!.trim(), useCase: MediaUseCase.banner, fit: BoxFit.cover)
              else if (fallbackUrl != null && fallbackUrl!.isNotEmpty) Image.network(fallbackUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.image_not_supported, color: Colors.white24)))
              else const Center(child: Icon(Icons.image, size: 50, color: Colors.white10)),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.5, 1.0])))),
              if (badge != null) Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE0C097), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)]), child: Text(badge!, style: theme.textTheme.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w900)))),
              Positioned(right: 16, bottom: 16, left: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [if (title.trim().isNotEmpty) Text(title.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, shadows: [const Shadow(color: Colors.black, blurRadius: 10)])), footer])),
            ],
          ),
        ),
      ),
    );
  }
}