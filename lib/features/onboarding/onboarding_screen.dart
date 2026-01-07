import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../services/store_settings_service.dart'; 
import '../../models/walkthrough_model.dart';
import '../../widgets/smart_media_image.dart'; 
import '../../utils/media_processor.dart';

class OnboardingScreen extends StatefulWidget {
  final LocaleController localeController;

  const OnboardingScreen({
    super.key,
    required this.localeController,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  
  final Color primaryDark = const Color(0xFF0A0E14);
  final Color accentGold = const Color(0xFFE0C097);
  final Color lightGold = const Color(0xFFF3E5D8);

  @override
  void initState() {
    super.initState();
    _checkIfSeen();
  }

  Future<void> _checkIfSeen() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool('seen_onboarding') ?? false) && mounted) {
      Navigator.pushReplacementNamed(context, '/app');
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/app');
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: primaryDark,
      body: StreamBuilder<List<WalkthroughModel>>(
        stream: StoreSettingsService.getWalkthroughsStream(), 
        builder: (context, snapshot) {
          
          // ✅ تم إزالة شاشة اللغة من هنا لأنها أصبحت تظهر قبل الـ Onboarding بشكل مستقل
          List<Widget> pages = [];

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            pages.addAll(snapshot.data!.map((data) => _buildDynamicPage(data)).toList());
          } else {
            // في حال عدم وجود بيانات من السيرفر، نعرض محتوى ترحيبي افتراضي فخم
            pages.add(_buildDefaultWelcomePage(t));
          }

          int totalPages = pages.length;

          return Stack(
            children: [
              _buildBackgroundGlow(),
              
              PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),

              _buildNavigationOverlay(t, totalPages),
              _buildBottomIndicatorAndButton(t, totalPages),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.5, -0.4),
            radius: 1.2,
            colors: [accentGold.withOpacity(0.07), primaryDark],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationOverlay(AppLocalizations t, int totalPages) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (_currentPage > 0)
              IconButton(
                onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.ease),
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: lightGold.withOpacity(0.6)),
              ),
            const Spacer(),
            if (_currentPage < totalPages - 1)
              TextButton(
                onPressed: _finishOnboarding,
                child: Text(t.onboardingSkip, 
                  style: GoogleFonts.cairo(color: accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicPage(WalkthroughModel data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
      child: Column(
        children: [
          _title(data.title),
          const SizedBox(height: 15),
          _subtitle(data.description),
          const Spacer(),
          _luxuryImageCard(data.imageUrl),
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  Widget _buildDefaultWelcomePage(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
      child: Column(
        children: [
          _title(t.onboardingDefaTitle),
          const SizedBox(height: 15),
          _subtitle(t.onboardingDefaSubtitle),
          const Spacer(),
          _luxuryImageCard('assets/images/logo.png'), // شعار دفا المفرغ الجديد
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  Widget _luxuryImageCard(String pathOrUrl) {
    return FadeInUp(
      child: Container(
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))],
          border: Border.all(color: accentGold.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SmartMediaImage(
                mediaId: pathOrUrl,
                useCase: MediaUseCase.banner,
                fit: BoxFit.cover,
              ),
              
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, primaryDark.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return FadeInDown(
      child: Text(text, textAlign: TextAlign.center, 
        style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: lightGold, height: 1.2)),
    );
  }

  Widget _subtitle(String text) {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Text(text, textAlign: TextAlign.center, 
        style: GoogleFonts.cairo(fontSize: 16, color: lightGold.withOpacity(0.6), height: 1.6)),
    );
  }

  Widget _buildBottomIndicatorAndButton(AppLocalizations t, int totalPages) {
    return Positioned(
      bottom: 40, left: 24, right: 24,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 5, width: _currentPage == i ? 30 : 10,
              decoration: BoxDecoration(color: _currentPage == i ? accentGold : Colors.white10, borderRadius: BorderRadius.circular(5)),
            )),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _nextPage(totalPages),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGold, foregroundColor: primaryDark,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 8,
            ),
            child: Text(_currentPage == totalPages - 1 ? t.onboardingStartShopping : t.onboardingNext, 
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}