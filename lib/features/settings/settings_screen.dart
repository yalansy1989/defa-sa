import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // للتخزين السحابي
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // لحفظ اللغة

// ✅ استيراد ملفات الترجمة والملف الرئيسي للتحكم باللغة
import 'package:defa_sa/l10n/app_localizations.dart';
import 'package:defa_sa/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // State Variables
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _selectedLanguage = 'العربية';
  String? _avatarUrl;

  // Codes
  final String _germanCode = "+49";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");

    // ✅ تهيئة الهاتف بالكود مبدئياً (كما كان)
    _phoneController = TextEditingController(text: _germanCode);

    // تحميل الصورة الحالية من Auth
    _avatarUrl = user?.photoURL;

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    // تحميل البيانات من Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    // تحميل اللغة المحفوظة محلياً لتحديد الاختيار في القائمة
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language_code');

    if (mounted) {
      setState(() {
        // الهاتف: إذا كان فارغاً نضع الكود، وإلا نضع الرقم المحفوظ
        String fetchedPhone = doc.data()?['phone'] ?? "";
        if (fetchedPhone.isEmpty) {
          _phoneController.text = _germanCode;
        } else {
          _phoneController.text = fetchedPhone;
        }

        // اللغة
        if (savedLang != null) {
          _selectedLanguage = _codeToName(savedLang);
        }

        // تحديث الصورة إذا كانت محفوظة في القاعدة وتختلف عن Auth
        if (doc.data()?['photoURL'] != null) {
          _avatarUrl = doc.data()?['photoURL'];
        }
      });
    }
  }

  // تحويل اسم اللغة لكود والعكس
  String _nameToCode(String name) {
    if (name == 'English') return 'en';
    return 'ar'; // ✅ تم حذف Deutsch
  }

  String _codeToName(String code) {
    if (code == 'en') return 'English';
    return 'العربية'; // ✅ تم حذف Deutsch
  }

  // ✅ دالة رفع الصورة للسحابة
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final File file = File(image.path);
      // مسار التخزين: profile_images/UID.jpg
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user!.uid}.jpg');

      // رفع الصورة
      await ref.putFile(file);

      // الحصول على الرابط
      final String downloadUrl = await ref.getDownloadURL();

      // تحديث بروفايل المستخدم (Auth + Firestore)
      await user?.updatePhotoURL(downloadUrl);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'photoURL': downloadUrl});

      setState(() {
        _avatarUrl = downloadUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تحديث الصورة الشخصية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // ✅ التحقق من الرقم الألماني (اختياري)
  bool _isValidGermanPhone(String phone) {
    String p = phone.replaceAll(" ", ""); // إزالة المسافات
    // إذا كان الحقل يحتوي فقط على الكود أو فارغ تماماً، فهو صحيح (لأنه اختياري)
    if (p == _germanCode || p.isEmpty) return true;

    // إذا أدخل أرقاماً، يجب أن تطابق الصيغة الألمانية
    final regex = RegExp(r'^(\+49|0049|0)[1-9][0-9]{4,14}$');
    return regex.hasMatch(p);
  }

  Future<void> _saveProfile() async {
    final t = AppLocalizations.of(context)!; // استخدام الترجمة

    // 1. التحقق من صحة الهاتف
    if (!_isValidGermanPhone(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invalidPhoneError)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 2. تحديث الاسم في Auth
      if (user?.displayName != _nameController.text) {
        await user?.updateDisplayName(_nameController.text);
      }

      // 3. تحديث الإيميل (إرسال تحقق)
      if (_emailController.text != user?.email &&
          _emailController.text.isNotEmpty) {
        try {
          await user?.verifyBeforeUpdateEmail(_emailController.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.emailVerificationSent),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } catch (e) {
          throw Exception("Error updating email: $e");
        }
      }

      // 4. ✅ تغيير اللغة الفعلي
      final langCode = _nameToCode(_selectedLanguage);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', langCode);

      if (mounted) {
        // استدعاء الدالة في main.dart لتحديث الواجهة فوراً
        MyApp.setLocale(context, Locale(langCode));
      }

      // 5. تحديث Firestore
      // ✅ حذفنا autoRenewal لأنك ألغيت الاشتراكات والباقات
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': _nameController.text,
        // حفظ الهاتف فقط إذا كان يحتوي على أرقام غير الكود
        'phone': (_phoneController.text == _germanCode) ? "" : _phoneController.text,
        'language': langCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.changesSaved)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${t.errorOccurred}: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final goldColor = const Color(0xFFE0C097);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        title: Text(t.settingsTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== 1. الصورة الشخصية (السحابية) ======
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 2),
                      image: _avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.white10,
                    ),
                    child: _avatarUrl == null
                        ? const Icon(Icons.person,
                            size: 60, color: Colors.white38)
                        : null,
                  ),
                  if (_isUploadingImage)
                    const Positioned.fill(
                        child: CircularProgressIndicator(color: Colors.white)),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Color(0xFFE0C097), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ====== 2. الملف الشخصي ======
            _buildSectionHeader(t.profileSection, Icons.person_outline, goldColor),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: t.fullNameLabel,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: t.emailLabel,
                    icon: Icons.email_outlined,
                    hint: t.emailHint,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: t.phoneLabel,
                    icon: Icons.phone_iphone,
                    hint: '+49 ...',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ====== 3. الدفع (واجهة فقط) ======
            // ✅ حافظنا على نفس التصميم تماماً وحذفنا فقط خيار التجديد التلقائي (اشتراكات)
            _buildSectionHeader(t.paymentSection, Icons.credit_card, goldColor),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  // بطاقة محفوظة (شكل فقط حالياً)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card,
                            color: Colors.white, size: 30),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('**** **** **** 4242',
                                style: TextStyle(
                                    color: Colors.white, letterSpacing: 2)),
                            Text('Default Method',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.check_circle,
                            color: Color(0xFFE0C097), size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () => _showAddCardBottomSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t.addPaymentMethod),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: goldColor,
                      side: BorderSide(color: goldColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),

                  // ✅ هنا كان Switch التجديد التلقائي — تم حذفه فقط
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ====== 4. اللغة ======
            _buildSectionHeader(t.appPrefsSection, Icons.settings_outlined, goldColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: _cardDecoration(),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.language, color: Colors.white),
                ),
                title: Text(t.languageLabel,
                    style: const TextStyle(color: Colors.white)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF161B22),
                    value: _selectedLanguage,
                    icon: Icon(Icons.arrow_drop_down, color: goldColor),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    // ✅ تم حذف Deutsch
                    items: ['العربية', 'English'].map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedLanguage = newValue);
                        // سيتم التفعيل عند الضغط على حفظ
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ====== زر الحفظ (إصلاح القص) ======
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  shadowColor: goldColor.withOpacity(0.4),
                  padding: EdgeInsets.zero,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2))
                    : Center(
                        child: Text(
                          t.saveChanges,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF161B22),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0C097))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  void _showAddCardBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('إضافة بطاقة جديدة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              height: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text('سيتم تفعيل بوابة الدفع قريباً',
                  style: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0C097),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('حفظ البطاقة',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
