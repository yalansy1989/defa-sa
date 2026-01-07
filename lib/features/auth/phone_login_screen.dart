import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'otp_verification_screen.dart'; // ✅ نحتاج هذا الملف (انظر بالأسفل)

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  PhoneNumber number = PhoneNumber(isoCode: 'SA'); 
  bool _isLoading = false;
  static const goldColor = Color(0xFFE0C097);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ✅ كود إرسال الـ OTP الحقيقي
  Future<void> _handleSendOTP() async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: number.phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // للأندرويد: التحقق التلقائي
          setState(() => _isLoading = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          String msg = "حدث خطأ";
          if (e.code == 'invalid-phone-number') msg = "الرقم غير صحيح";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          // ✅ الانتقال لشاشة الـ OTP
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                verificationId: verificationId,
                phoneNumber: number.phoneNumber!,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            FadeInDown(child: Text("تسجيل الدخول بالهاتف", style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
            const SizedBox(height: 40),
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: InternationalPhoneNumberInput(
                  onInputChanged: (PhoneNumber value) => number = value,
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    setSelectorButtonAsPrefixIcon: true,
                    showFlags: true,
                  ),
                  initialValue: number,
                  textFieldController: _phoneController,
                  cursorColor: goldColor,
                  textStyle: const TextStyle(color: Colors.white),
                  inputDecoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '5XXXXXXX',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: goldColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _isLoading ? null : _handleSendOTP,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text("إرسال رمز التحقق", style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}