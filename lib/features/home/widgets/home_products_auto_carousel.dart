import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:defa_sa/models/product.dart';
// ✅ استيراد ملف التعريب المعتمد
import 'package:defa_sa/l10n/app_localizations.dart';

class HomeProductsAutoCarousel extends StatefulWidget {
  final List<Product> products;
  final void Function(Product p)? onOpen;
  final double height;
  final Duration interval;

  const HomeProductsAutoCarousel({
    super.key,
    required this.products,
    this.onOpen,
    this.height = 245,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<HomeProductsAutoCarousel> createState() => _HomeProductsAutoCarouselState();
}

class _HomeProductsAutoCarouselState extends State<HomeProductsAutoCarousel>
    with AutomaticKeepAliveClientMixin {
  final _controller = PageController(viewportFraction: 0.90);
  Timer? _timer;
  int _index = 0;
  bool _holding = false;

  List<Product> get _items =>
      widget.products.where((p) => p.id.trim().isNotEmpty).toList();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant HomeProductsAutoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products.length != widget.products.length) {
      _stop();
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (!mounted) return;
    if (_items.isEmpty) return;

    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      if (_holding) return;
      if (!_controller.hasClients) return;

      final next = (_index + 1) % _items.length;
      _index = next;

      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutQuart,
      );
      if (mounted) setState(() {});
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pauseUser() async {
    _holding = true;
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    _holding = false;
  }

  @override
  void dispose() {
    _stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final goldColor = const Color(0xFFE0C097);

    if (_items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: widget.height + 45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                FadeInLeft(
                  child: Text(
                    "⭐ ${l10n.servicesTitle}",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: goldColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                FadeInRight(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "📦 ${_index + 1}/${_items.length}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: goldColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is UserScrollNotification || n is ScrollStartNotification) {
                  _pauseUser();
                }
                return false;
              },
              child: GestureDetector(
                onPanDown: (_) => _pauseUser(),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: _LuxuryProductCard(
                        product: p,
                        onTap: widget.onOpen,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Center(
            child: Wrap(
              spacing: 6,
              children: List.generate(_items.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  height: 6,
                  width: active ? 28 : 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: active
                        ? LinearGradient(colors: [goldColor, goldColor.withOpacity(0.6)])
                        : null,
                    color: active ? null : Colors.white10,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryProductCard extends StatelessWidget {
  final Product product;
  final void Function(Product p)? onTap;

  const _LuxuryProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final goldColor = const Color(0xFFE0C097);

    final img = (product.coverImage ?? '').trim().isNotEmpty
        ? product.coverImage!.trim()
        : (product.images.isNotEmpty ? product.images.first.trim() : '');

    // ✅ منتج عادي فقط: السعر يظهر إذا كان > 0
    final String? priceText =
        product.price > 0 ? "${product.price.toStringAsFixed(2)} ${product.currency}" : null;

    // ✅ شارة واحدة فقط (اطلب الآن)
    final String actionText = l10n.storeOrderNow;
    final Color actionColor = goldColor;

    return ZoomIn(
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: img.isEmpty
                    ? Container(
                        color: const Color(0xFF161B22),
                        child: const Icon(Icons.image_outlined, size: 50, color: Colors.white10),
                      )
                    : Image.network(
                        img,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : Container(
                                color: const Color(0xFF161B22),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF161B22),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 50,
                            color: Colors.white10,
                          ),
                        ),
                      ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 15,
                left: 15,
                child: _Pill(text: actionText, color: actionColor, compact: true),
              ),

              Positioned(
                left: 15,
                right: 15,
                bottom: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (priceText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: goldColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: goldColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              priceText,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: goldColor,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        InkWell(
                          onTap: () => onTap?.call(product),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: goldColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap?.call(product),
                    splashColor: goldColor.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final bool compact;

  const _Pill({required this.text, required this.color, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: compact ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
