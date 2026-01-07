import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ الخدمات
import 'package:defa_sa/services/auth_service.dart';
import 'package:defa_sa/l10n/app_localizations.dart';

// ✅ الإعدادات والدردشة والطلبات
import 'package:defa_sa/features/settings/settings_screen.dart';
import 'package:defa_sa/features/chat/chat_screen.dart'; 
import 'package:defa_sa/features/orders/orders_screen.dart'; // ✅ تم إضافة استيراد صفحة الطلبات

// ✅ كارد الهيدر
import 'widgets/account_header_card.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _userName = 'عميل دِفا الملكي';
  String _userEmail = 'email@defa-sa.com';

  File? _profileImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        final name = (user.displayName ?? '').trim();
        _userName = name.isEmpty ? 'عميل دِفا الملكي' : name;
        _userEmail = user.email ?? _userEmail;
      });
    }
  }

  void _openSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ).then((_) {
      if (mounted) _loadUserData();
    });
  }

  // ✅ دالة فتح صفحة الطلبات
  void _openOrdersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrdersScreen()),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _profileImageFile = File(picked.path));
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _openSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen.support()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    const goldColor = Color(0xFFE0C097);
    const deepDarkColor = Color(0xFF0A0E14);

    ImageProvider? avatarImage;
    if (_profileImageFile != null) {
      avatarImage = FileImage(_profileImageFile!);
    } else if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      avatarImage = NetworkImage(user.photoURL!);
    }

    return Scaffold(
      backgroundColor: deepDarkColor,
      appBar: AppBar(
        title: Text(
          t.accountTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: t.editProfile,
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.photo_camera_outlined, color: goldColor),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        children: [
          // 1. كارد رأس الصفحة الفخم (البروفايل الرئيسي)
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: AccountHeaderCard(
              userName: _userName,
              userEmail: _userEmail,
              avatarImage: avatarImage,
              isVip: false,
              onEditTap: _openSettingsScreen,
            ),
          ),
          
          const SizedBox(height: 32),
          
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _SectionTitle(title: t.services),
          ),
          
          const SizedBox(height: 20),
          
          // 2. شبكة الكروت المربعة (GridView)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
            children: [
              // ✅ كرت طلباتي الجديد (تمت إضافته كأول خيار)
              _SquareActionCard(
                delay: 150,
                icon: Icons.receipt_long_rounded,
                title: "طلباتي", // يمكن استخدام t.navOrders إذا كانت متوفرة
                color: goldColor,
                onTap: _openOrdersScreen,
              ),

              // كرت الإعدادات
              _SquareActionCard(
                delay: 200,
                icon: Icons.settings_suggest_rounded,
                title: t.settings,
                color: goldColor,
                onTap: _openSettingsScreen,
              ),
              
              // كرت الدعم الفني
              _SquareActionCard(
                delay: 300,
                icon: Icons.support_agent_rounded,
                title: t.support,
                color: goldColor,
                onTap: _openSupport,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // 3. زر تسجيل الخروج
          FadeInUp(
            delay: const Duration(milliseconds: 450),
            child: SizedBox(
              height: 60,
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(
                    color: Colors.redAccent.withOpacity(0.3), 
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.redAccent.withOpacity(0.05),
                ),
                onPressed: () async => await AuthService.signOut(),
                icon: const Icon(Icons.logout_rounded, size: 22),
                label: Text(
                  t.logout,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ ويدجت الكرت المربع الفخم
class _SquareActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _SquareActionCard({
    required this.icon, 
    required this.title, 
    required this.color, 
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: Material(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.5,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w900,
        fontSize: 15,
        letterSpacing: 0.5,
      ),
    );
  }
}