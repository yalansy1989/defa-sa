import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';

import 'package:defa_sa/widgets/smart_media_image.dart';
import 'package:defa_sa/utils/media_processor.dart';
import 'package:defa_sa/features/products/collection_details_screen.dart';

class HomeCategoriesCircle extends StatefulWidget {
  const HomeCategoriesCircle({super.key});

  @override
  State<HomeCategoriesCircle> createState() => _HomeCategoriesCircleState();
}

class _HomeCategoriesCircleState extends State<HomeCategoriesCircle> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  static const double _itemWidth = 90;
  static const Duration _interval = Duration(seconds: 4); // جعلناه 4 ثوانٍ لراحة العين

  @override
  void initState() {
    super.initState();
    // تأخير البدء قليلاً لضمان بناء الواجهة
    Future.delayed(const Duration(seconds: 1), () => _startAutoScroll());
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      final next = current + _itemWidth;

      if (next >= maxScroll + (_itemWidth / 2)) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _scrollController.animateTo(
          next,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('collections')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'];
          return type == 'category' || type == null || type == '';
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 130,
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              // ذكاء اصطناعي في التعامل مع اللمس:
              if (notification.direction != ScrollDirection.idle) {
                _timer?.cancel(); // إيقاف الحركة فوراً عند ملامسة إصبع المستخدم
              } else {
                _startAutoScroll(); // إعادة الحركة بعد الانتهاء من التصفح اليدوي
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
                final name = (data['title'] ?? data['name'] ?? '').toString();
                final imageRef = (data['coverImageId'] ?? data['icon'] ?? '').toString();

                return SizedBox(
                  width: _itemWidth,
                  child: InkWell(
                    // منع تأثير التموج من تشويه الدائرة
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollectionDetailsScreen(
                            collectionId: id,
                            collectionTitle: name,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE0C097).withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: SmartMediaImage(
                              mediaId: imageRef,
                              useCase: MediaUseCase.banner,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}