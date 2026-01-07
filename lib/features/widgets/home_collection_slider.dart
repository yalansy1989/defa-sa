import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _HomeCollectionSliderState extends State<HomeCollectionSlider> {
  Timer? _timer;
  int _current = 0;

  bool _enabled = false;
  int _intervalSeconds = 4;
  String _motion = "auto";

  List<Map<String, dynamic>> _slides = [];

  @override
  void initState() {
    super.initState();
    _loadSlider();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSlider() async {
    final snap = await FirebaseFirestore.instance
        .collection('collections')
        .doc(widget.collectionId)
        .get();

    if (!snap.exists) return;

    final data = snap.data()!;
    _enabled = data['sliderEnabled'] == true;
    _intervalSeconds = (data['sliderIntervalSeconds'] ?? 4).toInt();
    _motion = data['sliderMotion'] ?? 'auto';

    final items = List<Map<String, dynamic>>.from(
      data['sliderItems'] ?? [],
    );

    if (!mounted) return;

    setState(() {
      _slides = items;
    });

    if (_enabled && _motion == 'auto' && _slides.length > 1) {
      _timer = Timer.periodic(
        Duration(seconds: _intervalSeconds),
        (_) {
          if (!mounted) return;
          setState(() {
            _current = (_current + 1) % _slides.length;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 16 / 8, // ✅ حل القص في الويب
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: PageView.builder(
            controller: PageController(viewportFraction: 1),
            onPageChanged: (i) => _current = i,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final image = slide['imageUrl'] as String?;
              final productId = slide['productId'] as String?;

              return GestureDetector(
                onTap: productId != null && widget.onOpenProduct != null
                    ? () => widget.onOpenProduct!(productId)
                    : null,
                child: image != null
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      )
                    : Container(color: Colors.black12),
              );
            },
          ),
        ),
      ),
    );
  }
}
