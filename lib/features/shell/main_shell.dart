import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ استيراد الشاشات
import '../home/home_screen.dart';
import '../store/store_screen.dart';
import '../account/account_screen.dart';
import '../cart/cart_screen.dart';

import 'package:defa_sa/l10n/app_localizations.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  final String? initialOrderId;

  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.initialOrderId,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  late final List<Widget> _pages;

  final Color goldColor = const Color(0xFFE0C097);
  final Color deepDarkColor = const Color(0xFF0A0E14);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _pages = [
      const HomeScreen(),
      const StoreScreen(),
      const CartScreen(),
      const AccountScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: deepDarkColor,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      
      // ✅ تم تحويل Body إلى Stack للسماح بوضع السلة في أي مكان
      body: Stack(
        children: [
          // 1. محتوى الصفحات
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // 2. الكرت العائم للسلة (في الأعلى - جهة اليسار)
          if (user != null)
            Positioned(
              // نضعه أسفل الـ AppBar بقليل (ارتفاع البار + مسافة أمان)
              top: MediaQuery.of(context).padding.top + 60, 
              left: 20, // جهة اليسار (في التطبيقات العربية تكون فارغة عادةً)
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('cart')
                    .snapshots(),
                builder: (context, snapshot) {
                  int itemCount = 0;
                  if (snapshot.hasData) {
                    itemCount = snapshot.data!.docs.length;
                  }

                  // إظهار السلة بتأثير حركي
                  return OpenContainerWrapper(
                    openBuilder: (context, closedContainer) {
                       return const CartScreen(); 
                    },
                    closedBuilder: (context, openContainer) {
                      return GestureDetector(
                        onTap: () {
                           // عند الضغط ننقل المستخدم لتبويب السلة (رقم 2)
                           setState(() => _currentIndex = 2);
                        },
                        child: _FloatingCartCard(
                          count: itemCount, 
                          goldColor: goldColor
                        ),
                      );
                    }
                  );
                },
              ),
            ),
        ],
      ),

      // 🏛️ شريط التنقل السفلي
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: goldColor,
                unselectedItemColor: Colors.white.withOpacity(0.35),
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  height: 1.6,
                  fontFamily: 'Cairo',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  height: 1.6,
                  fontFamily: 'Cairo',
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined, size: 22),
                    activeIcon: const Icon(Icons.home_rounded, size: 26),
                    label: t.navHome,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.storefront_outlined, size: 22),
                    activeIcon: const Icon(Icons.storefront_rounded, size: 26),
                    label: t.navStore,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                    activeIcon: const Icon(Icons.shopping_bag_rounded, size: 26),
                    label: "السلة",
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline, size: 22),
                    activeIcon: const Icon(Icons.person_rounded, size: 26),
                    label: t.navAccount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ تصميم كرت السلة العائم الفخم
class _FloatingCartCard extends StatelessWidget {
  final int count;
  final Color goldColor;

  const _FloatingCartCard({required this.count, required this.goldColor});

  @override
  Widget build(BuildContext context) {
    return FadeInLeft( // حركة دخول من اليسار
      duration: const Duration(milliseconds: 600),
      child: Container(
        height: 55, // حجم أصغر قليلاً ليناسب الموقع العلوي
        width: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // لون داكن شفاف مع حدود ذهبية
          color: Colors.black.withOpacity(0.6), 
          border: Border.all(color: goldColor.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, color: goldColor, size: 24),
            
            // 🔴 عداد المنتجات
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: ZoomIn( // تأثير تكبير عند تحديث الرقم
                  key: ValueKey(count), 
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ]
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OpenContainerWrapper extends StatelessWidget {
  final Widget Function(BuildContext, void Function()) closedBuilder;
  final Widget Function(BuildContext, void Function()) openBuilder;

  const OpenContainerWrapper({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return closedBuilder(context, () {});
  }
}