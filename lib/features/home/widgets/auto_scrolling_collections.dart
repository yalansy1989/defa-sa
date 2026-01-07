import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:defa_sa/services/store_settings_service.dart';
import 'package:defa_sa/models/category_model.dart'; 
import 'package:defa_sa/features/products/collection_details_screen.dart';
// ✅ تمت إعادة تفعيل هذا المكتبة لأننا أصلحناها لتدعم التخزين المؤقت (Caching)
import 'package:defa_sa/widgets/smart_media_image.dart'; 
import 'package:defa_sa/utils/media_processor.dart';

class AutoScrollingCollections extends StatefulWidget {
  const AutoScrollingCollections({super.key});

  @override
  State<AutoScrollingCollections> createState() => _AutoScrollingCollectionsState();
}

class _AutoScrollingCollectionsState extends State<AutoScrollingCollections> {
  late final ScrollController _scrollController;
  Timer? _timer;
  bool _isUserInteracting = false;
  
  // اتجاه الحركة (true = لليمين، false = لليسار/العودة)
  bool _movingForward = true; 

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // شروط إيقاف الحركة:
      if (_isUserInteracting || 
          !_scrollController.hasClients || 
          _scrollController.position.maxScrollExtent <= 0) {
        return;
      }

      double currentPosition = _scrollController.offset;
      double maxScroll = _scrollController.position.maxScrollExtent;
      
      // منطق الحركة (رايح جاي) لضمان عدم التكرار
      if (_movingForward) {
        if (currentPosition >= maxScroll) {
          // وصلنا للنهاية، نعكس الاتجاه
           _movingForward = false;
        } else {
          _scrollController.animateTo(
            currentPosition + 1.0, // سرعة الحركة
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      } else {
        if (currentPosition <= 0) {
          // وصلنا للبداية، نعكس الاتجاه
          _movingForward = true;
        } else {
          _scrollController.animateTo(
            currentPosition - 1.0, 
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
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
    const goldColor = Color(0xFFE0C097);

    return StreamBuilder<List<CategoryModel>>(
      stream: StoreSettingsService.categoriesStream(), 
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); 
        }

        final categories = snapshot.data!;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_timer == null) _startAutoScroll();
        });

        return SizedBox(
          height: 120, 
          child: Listener(
            onPointerDown: (_) => setState(() => _isUserInteracting = true),
            onPointerUp: (_) => setState(() => _isUserInteracting = false),
            onPointerCancel: (_) => setState(() => _isUserInteracting = false),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              // هذا السطر يسمح بالسحب اليدوي دائماً
              physics: const AlwaysScrollableScrollPhysics(), 
              // العدد الحقيقي فقط
              itemCount: categories.length, 
              itemBuilder: (context, index) {
                final item = categories[index];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                           Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => CollectionDetailsScreen(collectionId: item.id)
                            )
                          );
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: goldColor.withOpacity(0.4), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withOpacity(0.1),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: ClipOval(
                            // ✅ العودة للأصل: استخدام SmartMediaImage
                            // الآن ستعمل الصور وبنفس الوقت نحصل على كفاءة الذاكرة (Caching)
                            child: SmartMediaImage(
                              mediaId: item.imageUrl, // الموديل يرسل الرابط الكامل الآن
                              useCase: MediaUseCase.product,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.2
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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