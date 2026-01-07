import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart'; // ✅ تأكد أنك نفذت أمر التثبيت
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../shell/main_shell.dart';
import '../../services/notification_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  static const goldColor = Color(0xFFE0C097);

  // ✅ دالة التحقق من الكود
  Future<void> _verifyOtp() async {
    String smsCode = _pinController.text.trim();
    if (smsCode.length != 6) return;

    setState(() => _isLoading = true);

    try {
      // إنشاء أوراق الاعتماد
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      // تسجيل الدخول
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // تحديث التوكن للإشعارات
      await NotificationService.updateDeviceToken('user');

      if (!mounted) return;
      
      // الانتقال للرئيسية
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الرمز غير صحيح أو انتهت صلاحيته")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // تنسيق حقول الـ PIN
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.cairo(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            FadeInDown(
              child: const Icon(Icons.lock_clock_outlined, size: 80, color: goldColor),
            ),
            const SizedBox(height: 30),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: Text(
                "تأكيد الرمز",
                style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "تم إرسال الرمز إلى ${widget.phoneNumber}",
              style: GoogleFonts.cairo(color: Colors.white54),
            ),
            const SizedBox(height: 50),

            // ✅ حقل إدخال الرمز
            Pinput(
              controller: _pinController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: goldColor),
                ),
              ),
              onCompleted: (pin) => _verifyOtp(),
            ),

            const SizedBox(height: 50),

            // زر التحقق
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text("تحقق والدخول", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}