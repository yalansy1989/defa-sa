import 'dart:async';
import 'package:flutter/material.dart';
import 'package:defa_sa/models/product.dart';
import 'package:defa_sa/l10n/app_localizations.dart';

class HomeProductsTicker extends StatefulWidget {
  final List<Product> products;
  final void Function(Product p)? onOpen;
  final double height;
  final Duration tick;
  final double stepPx;

  const HomeProductsTicker({
    super.key,
    required this.products,
    this.onOpen,
    this.height = 120,
    this.tick = const Duration(milliseconds: 30),
    this.stepPx = 1.0,
  });

  @override
  State<HomeProductsTicker> createState() => _HomeProductsTickerState();
}

class _HomeProductsTickerState extends State<HomeProductsTicker>
    with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  Timer? _timer;
  bool _userHolding = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(covariant HomeProductsTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products.length != widget.products.length) {
      _stop();
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (!mounted || widget.products.isEmpty) return;
    _stop();

    _timer = Timer.periodic(widget.tick, (_) {
      if (!mounted || _userHolding || !_controller.hasClients) return;

      final maxScroll = _controller.position.maxScrollExtent;
      final current = _controller.position.pixels;

      if (current >= maxScroll) {
        _controller.jumpTo(0);
      } else {
        _controller.jumpTo(current + widget.stepPx);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    _controller.dispose();
    super.dispose();
  }

  void _pauseForUser() async {
    _userHolding = true;
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) _userHolding = false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.colorScheme.primary.withOpacity(0.14),
            theme.colorScheme.secondary.withOpacity(0.10),
            Colors.white.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is UserScrollNotification || n is ScrollStartNotification) {
              _pauseForUser();
            }
            return false;
          },
          child: GestureDetector(
            onPanDown: (_) => _pauseForUser(),
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemBuilder: (context, i) {
                final index = i % widget.products.length;
                final p = widget.products[index];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: _TickerProductCard(
                    product: p,
                    onTap: widget.onOpen,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TickerProductCard extends StatelessWidget {
  final Product product;
  final void Function(Product p)? onTap;

  const _TickerProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final img = (product.coverImage ?? '').trim().isNotEmpty
        ? product.coverImage!.trim()
        : (product.images.isNotEmpty ? product.images.first.trim() : '');

    final priceText = product.price > 0
        ? "${product.price.toStringAsFixed(0)} ${product.currency}"
        : l10n.storeContactUs;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap?.call(product),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Container(
                width: 92,
                height: double.infinity,
                color: Colors.white10,
                child: img.isEmpty
                    ? const Center(
                        child: Icon(Icons.image_outlined, color: Colors.white54),
                      )
                    : Image.network(
                        img,
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white54),
                        ),
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "✨ ${product.name}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.orange.withOpacity(0.12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.22),
                            ),
                          ),
                          child: Text(
                            l10n.storeOrderNow,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 10),
                          ),
                        ),
                        Text(
                          priceText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
