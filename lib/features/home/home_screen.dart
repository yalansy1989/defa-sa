import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:defa_sa/l10n/app_localizations.dart';

// ✅ استيراد الصفحات والتفاصيل
import 'package:defa_sa/features/products/product_details_screen.dart';
import 'package:defa_sa/features/products/collection_details_screen.dart';

// ✅ استيراد المكونات الموحدة
import 'package:defa_sa/features/home/widgets/home_banner.dart';
import 'package:defa_sa/features/home/widgets/home_slider_block.dart';

// 🔴 التعديل هنا: استبدلنا المكون التلقائي بمكوننا الذي يدعم اللمس
import 'package:defa_sa/features/home/widgets/home_categories_circle.dart'; 
import 'package:defa_sa/features/home/widgets/home_dynamic_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  void _openProductDetails(String productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(productId: productId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const goldColor = Color(0xFFE0C097);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14), 
      
      appBar: AppBar(
        title: FadeInDown(
          child: Image.asset(
             'assets/images/logo_text.png', 
             height: 30, 
             errorBuilder: (_,__,___) => Text(
               t.homeTitle,
               style: theme.textTheme.titleLarge?.copyWith(
                 fontWeight: FontWeight.w900,
                 color: Colors.white,
                 fontSize: 22,
               ),
             ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70, size: 28), 
            onPressed: () { },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white70, size: 28),
            onPressed: () { },
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: goldColor,
          backgroundColor: const Color(0xFF161B22),
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) setState(() {}); 
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // 1. البانر الرئيسي
                const Padding(
                  padding: EdgeInsets.fromLTRB(1, 12, 1, 0),
                  child: HomeBanner(),
                ),
                
                const SizedBox(height: 25),

                // 2. ✅ التحديث التقني هنا:
                // استخدمنا HomeCategoriesCircle بدلاً من AutoScrollingCollections
                // هذا المكون الآن يدعم اللمس الفوري ويمرر اسم الكولكشن بدقة
                const HomeCategoriesCircle(),

                const SizedBox(height: 25),

                // 3. السلايدر العريض
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: HomeSliderBlock(
                    sliderId: 'main_slider',
                    onOpenProduct: _openProductDetails,
                  ),
                ),

                const SizedBox(height: 25),

                // 4. الأقسام الديناميكية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HomeDynamicSections(
                    onOpenProduct: _openProductDetails,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}