import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:defa_sa/utils/cloudinary_transform.dart';
// ✅ إضافة التبعيات اللازمة لنظام العملة الجديد دون حذف أي كود أصلي
import 'package:defa_sa/widgets/price_text.dart'; 
import 'package:defa_sa/l10n/app_localizations.dart';

/// ✅ NEW SYSTEM OPTIMIZED
/// يدعم التخزين المؤقت (KeepAlive) لعدم إعادة التحميل
class HomeCollectionSlider extends StatefulWidget {
  final String collectionId;
  final void Function(String productId)? onOpenProduct;

  const HomeCollectionSlider({
    super.key,
    required this.collectionId,
    this.onOpenProduct,
  });

  @override
  State<HomeCollectionSlider> createState() => _HomeCollectionSliderState();
}

// ✅ 1. إضافة Mixin (كما ورد في كودك الأصلي)
class _HomeCollectionSliderState extends State<HomeCollectionSlider> with AutomaticKeepAliveClientMixin {
  final _pageCtrl = PageController(viewportFraction: 0.92);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _colSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sliderSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _itemsSub;

  Timer? _timer;

  String? _sliderId;
  bool _enabled = true;
  String _motion = 'auto'; // auto | manual
  String _effect = 'slide'; // slide | fade
  int _intervalSeconds = 4;

  List<Map<String, dynamic>> _items = [];
  final Map<String, String> _mediaUrlById = {};
  bool _mounted = false;

  // ✅ 2. تفعيل الحفاظ على الحالة (كما ورد في كودك الأصلي)
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _listenCollection();
  }

  @override
  void dispose() {
    _mounted = false;
    _timer?.cancel();
    _colSub?.cancel();
    _sliderSub?.cancel();
    _itemsSub?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_mounted) return;
    if (!mounted) return;
    setState(fn);
  }

  void _listenCollection() {
    _colSub?.cancel();
    _colSub = FirebaseFirestore.instance
        .collection('collections')
        .doc(widget.collectionId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) {
        _detachSlider();
        _safeSetState(() {
          _sliderId = null;
          _items = [];
        });
        return;
      }
      final data = snap.data() ?? {};
      final sid = (data['sliderId'] ?? '').toString().trim();
      
      // إذا لم يكن هناك sliderId، لا تفعل شيئاً
      if (sid.isEmpty) {
        _detachSlider();
        _safeSetState(() {
          _sliderId = null;
          _items = [];
        });
        return;
      }

      if (_sliderId != sid) {
        _sliderId = sid;
        _listenSliderDoc();
        _listenItems();
      }
    });
  }

  void _detachSlider() {
    _timer?.cancel();
    _sliderSub?.cancel();
    _itemsSub?.cancel();
    _mediaUrlById.clear();
  }

  void _listenSliderDoc() {
    if (_sliderId == null) return;

    _sliderSub?.cancel();
    _sliderSub = FirebaseFirestore.instance
        .collection('sliders')
        .doc(_sliderId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final d = snap.data() ?? {};
      final enabled = d['enabled'] == true; 
      final motion = (d['motion'] ?? 'auto').toString();
      final effect = (d['effect'] ?? 'slide').toString();
      final interval = (d['intervalSeconds'] ?? 4);

      _safeSetState(() {
        _enabled = enabled;
        _motion = motion;
        _effect = effect;
        _intervalSeconds = (interval is num) ? interval.toInt() : 4;
      });

      _resetAutoTimer();
    });
  }

  void _listenItems() {
    if (_sliderId == null) return;

    _itemsSub?.cancel();
    _itemsSub = FirebaseFirestore.instance
        .collection('sliders')
        .doc(_sliderId)
        .collection('items') 
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
        .snapshots()
        .listen((snap) async {
      final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      // prefetch media URLs for imageId
      final imageIds = <String>{};
      for (final it in list) {
        final imageId = (it['imageId'] ?? '').toString();
        if (imageId.isNotEmpty) imageIds.add(imageId);
      }
      if (imageIds.isNotEmpty) {
        await _prefetchMediaUrls(imageIds.toList());
      }

      _safeSetState(() {
        _items = list;
      });

      _resetAutoTimer();
    });
  }

  Future<void> _prefetchMediaUrls(List<String> ids) async {
    final missing = ids.where((id) => !_mediaUrlById.containsKey(id)).toList();
    if (missing.isEmpty) return;

    // Fetch in chunks optimized
    const chunkSize = 10;
    for (var i = 0; i < missing.length; i += chunkSize) {
      final chunk = missing.sublist(i, (i + chunkSize).clamp(0, missing.length));
      
      // Parallel fetch for speed
      final snaps = await Future.wait(
        chunk.map((id) => FirebaseFirestore.instance.collection('media').doc(id).get()),
      );
      
      for (final s in snaps) {
        if (!s.exists) continue;
        final d = s.data() as Map<String, dynamic>;
        final url = (d['url'] ?? d['secureUrl'] ?? d['secure_url'] ?? '').toString();
        if (url.isNotEmpty) _mediaUrlById[s.id] = url;
      }
    }
    // Update UI after fetching images
    if (mounted) setState(() {});
  }

  void _resetAutoTimer() {
    _timer?.cancel();

    if (!_enabled) return;
    if (_motion != 'auto') return;
    if (_items.length <= 1) return;

    final seconds = _intervalSeconds <= 0 ? 4 : _intervalSeconds;
    _timer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (!_pageCtrl.hasClients) return;
      final next = (_pageCtrl.page ?? 0).round() + 1;
      final target = next >= _items.length ? 0 : next;
      
      _pageCtrl.animateToPage(
        target,
        duration: const Duration(milliseconds: 800), 
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openProduct(String productId) {
    if (productId.isEmpty) return;
    if (widget.onOpenProduct != null) {
      widget.onOpenProduct!(productId);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ 3. ضروري مع Mixin

    if (_sliderId == null) return const SizedBox.shrink();
    if (!_enabled) return const SizedBox.shrink();
    if (_items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220, // زيادة الارتفاع لضمان عرض السعر بوضوح (كما في نسختنا الملكية)
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: _items.length,
        itemBuilder: (context, idx) {
          final it = _items[idx];
          final type = (it['type'] ?? 'image').toString(); 
          final title = (it['title'] ?? '').toString();
          // ✅ جلب السعر المرجعي (يورو) من الداتابيز
          final priceInEur = (it['price'] ?? 0).toDouble();

          final imageId = (it['imageId'] ?? '').toString();
          String? url = imageId.isEmpty ? null : _mediaUrlById[imageId];
          
          if (url != null) {
              url = cloudinaryTransform(url, preset: CloudinaryPreset.collectionSlider);
          }

          final card = _SlideCard(
            effect: _effect,
            imageUrl: url,
            title: title.isEmpty ? null : title,
            // ✅ تمرير السعر للبطاقة ليتم تحويله
            priceInEur: type == 'product' ? priceInEur : null,
          );

          if (type == 'product') {
            final productId = (it['productId'] ?? '').toString();
            return GestureDetector(
              onTap: () => _openProduct(productId),
              child: card,
            );
          }

          if (type == 'link') {
            final link = (it['externalLink'] ?? '').toString();
            return GestureDetector(
              onTap: () => _openLink(link),
              child: card,
            );
          }

          return card;
        },
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String effect;
  final double? priceInEur; // ✅ معامل السعر المضاف

  const _SlideCard({
    required this.effect,
    this.imageUrl,
    this.title,
    this.priceInEur,
  });

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFE0C097);

    final img = imageUrl == null || imageUrl!.isEmpty
        ? Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.white24),
          )
        : Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // ✅ الحفاظ على إعدادات الـ Cache من كودك الأصلي
            cacheWidth: 600, 
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(color: const Color(0xFF161B22));
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF161B22),
                child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
              );
            },
          );

    final overlay = title == null
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  // ✅ عرض السعر الديناميكي المحول
                  if (priceInEur != null && priceInEur! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: PriceText(
                        priceInEur: priceInEur!,
                        style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          );

    final child = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: img),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.40), // زيادة الظل لجمالية النص والسعر
                  ],
                ),
              ),
            ),
          ),
          overlay,
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: child,
    );
  }
}
