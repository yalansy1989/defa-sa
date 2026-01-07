import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ المكتبات المطلوبة لتحديد الموقع (تأكد من إضافتها في pubspec.yaml)
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:defa_sa/models/cart_item.dart';
import 'package:defa_sa/widgets/app_button_styles.dart';
import 'package:defa_sa/features/home/payment_page.dart';
import 'package:defa_sa/widgets/checkout_stepper.dart';
import 'package:defa_sa/l10n/app_localizations.dart';

import 'package:defa_sa/widgets/smart_media_image.dart';
import 'package:defa_sa/utils/media_processor.dart';

class OrderConfirmPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<CartItem> cartItems;
  final double total;
  final dynamic shippingAddress;
  final String? notes;

  final String currencyCode;

  const OrderConfirmPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.cartItems,
    required this.total,
    this.shippingAddress,
    this.notes,
    this.currencyCode = 'SAR',
  });

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  bool _loading = false;
  bool _locating = false; // حالة تحميل الموقع
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController; // ✅ تحكم حقل العنوان

  String _resolvedName = "";
  String _resolvedEmail = "";
  
  static const goldColor = Color(0xFFE0C097);
  static const deepDarkColor = Color(0xFF0A0E14);

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.customerPhone.trim());
    
    // تهيئة العنوان إذا كان موجوداً مسبقاً
    String initialAddress = "";
    if (widget.shippingAddress != null && widget.shippingAddress is Map) {
       // دمج البيانات إذا كانت بصيغة Map
       initialAddress = [
         widget.shippingAddress['city'],
         widget.shippingAddress['district'],
         widget.shippingAddress['street']
       ].where((e) => e != null && e.toString().isNotEmpty).join(' - ');
    } else if (widget.shippingAddress is String) {
       initialAddress = widget.shippingAddress;
    }
    _addressController = TextEditingController(text: initialAddress);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillAuth();
    });
  }

  Future<void> _prefillAuth() async {
    final s = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _resolvedName = (user.displayName ?? widget.customerName).trim().isEmpty
          ? s.default_customer_name
          : (user.displayName ?? widget.customerName).trim();
      _resolvedEmail = (user.email ?? "").trim();
    });
  }

  // ✅ دالة تحديد الموقع الذكي
  Future<void> _getCurrentLocation() async {
    setState(() => _locating = true);
    try {
      // 1. التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "يرجى تفعيل خدمة الموقع (GPS) في هاتفك.";
      }

      // 2. التحقق من الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "تم رفض إذن الوصول للموقع.";
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw "إذن الموقع مرفوض نهائياً من الإعدادات.";
      }

      // 3. جلب الإحداثيات الحالية
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high // دقة عالية للفخامة
      );

      // 4. تحويل الإحداثيات إلى عنوان مقروء (Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // تنسيق العنوان: المدينة - الحي - الشارع
        String formattedAddress = [
          place.locality,      // المدينة
          place.subLocality,   // الحي
          place.thoroughfare   // الشارع
        ].where((e) => e != null && e.isNotEmpty).join(' - ');

        if (formattedAddress.isEmpty) {
           formattedAddress = "${place.administrativeArea ?? ''} ${place.country ?? ''}";
        }

        setState(() {
          _addressController.text = formattedAddress;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("✅ تم تحديد موقعك بنجاح"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _locating = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _goToPayment(String activeCurrency) {
    final s = AppLocalizations.of(context)!;
    if (_loading) return;

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.please_login_first)));
      return;
    }

    final String currencyToUse =
        (widget.currencyCode.trim().isNotEmpty && widget.currencyCode != 'SAR')
            ? widget.currencyCode.trim()
            : activeCurrency;

    // ✅ تجهيز العنوان للإرسال
    final shippingData = {
       'address': _addressController.text.trim(),
       'type': 'home_delivery' // نوع افتراضي
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          cartItems: widget.cartItems,
          total: widget.total,
          customerId: user.uid,
          customerName: _resolvedName,
          customerPhone: _phoneController.text.trim(),
          customerEmail: _resolvedEmail,
          
          // ✅ تمرير العنوان المكتشف أو المكتوب
          shippingAddress: shippingData,
          requiresShipping: _addressController.text.trim().isNotEmpty, // تفعيل الشحن إذا وجد عنوان
          
          notes: widget.notes,
          orderType: "product",
          pricingMode: "price",
          currencyCode: currencyToUse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('currency_config')
          .snapshots(),
      builder: (context, configSnap) {
        String activeCurrency = "EUR";
        String symbol = "€";
        double rate = 1.0;

        if (configSnap.hasData && configSnap.data!.exists) {
          final config = configSnap.data!.data() as Map<String, dynamic>;
          activeCurrency = (config['active_currency'] ?? "EUR").toString();
          symbol = (config['symbol'] ?? "€").toString();
          if (activeCurrency != "EUR") {
            rate = (config['rates']?[activeCurrency] ?? 1.0).toDouble();
          }
        }

        if (widget.currencyCode == 'SAR') {
           activeCurrency = 'SAR';
           symbol = 'ر.س';
           rate = 1.0; 
        }

        return Scaffold(
          backgroundColor: deepDarkColor,
          appBar: AppBar(
            title: Text(
              s.checkout_title,
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                const CheckoutStepper(currentStep: 1),
                const SizedBox(height: 24),
                
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    s.order_confirm_page_review_msg,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // 1️⃣ بطاقة بيانات العميل
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                          label: s.customer_label,
                          icon: Icons.person_outline),
                      const SizedBox(height: 12),
                      _InfoRow(label: s.name_label, value: _resolvedName),
                      if (_resolvedEmail.isNotEmpty)
                        _InfoRow(label: s.email_label, value: _resolvedEmail),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2️⃣ حقل رقم الهاتف والعنوان
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                          label: "بيانات التواصل والتوصيل", // تم تحديث التسمية
                          icon: Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      
                      // حقل الهاتف
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: s.phone_number,
                          hintStyle: GoogleFonts.cairo(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.phone,
                              color: goldColor, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return s.phone_is_required_msg;
                          }
                          if (value.length < 8) return "رقم الهاتف غير مكتمل";
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12),

                      // ✅ حقل العنوان مع زر تحديد الموقع
                      Row(
                        children: [
                          // زر تحديد الموقع (GPS)
                          Container(
                            margin: const EdgeInsets.only(right: 8), // مسافة صغيرة
                            decoration: BoxDecoration(
                              color: goldColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: goldColor.withOpacity(0.3)),
                            ),
                            child: IconButton(
                              onPressed: _locating ? null : _getCurrentLocation,
                              tooltip: "تحديد موقعي الحالي",
                              icon: _locating 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: goldColor))
                                : const Icon(Icons.my_location, color: goldColor),
                            ),
                          ),
                          
                          // حقل إدخال العنوان
                          Expanded(
                            child: TextFormField(
                              controller: _addressController,
                              textAlign: TextAlign.right,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 1, // سطر واحد لأناقة التصميم
                              decoration: InputDecoration(
                                hintText: "عنوان التوصيل (المدينة، الحي...)",
                                hintStyle: GoogleFonts.cairo(color: Colors.white24, fontSize: 13),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "يرجى إدخال عنوان التوصيل";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                         "اضغط على زر الموقع لتعبئة العنوان تلقائياً",
                         textAlign: TextAlign.center,
                         style: GoogleFonts.cairo(color: Colors.white30, fontSize: 10),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3️⃣ بطاقة المنتجات
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                          label: s.products_label,
                          icon: Icons.shopping_bag_outlined),
                      const SizedBox(height: 12),
                      ...widget.cartItems.map((e) => _CartLine(
                          item: e,
                          symbol: symbol,
                          rate: rate)),
                      const Divider(color: Colors.white10, height: 30),
                      _TotalRow(total: widget.total, symbol: symbol, rate: rate),
                    ],
                  ),
                ),

                if ((widget.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(
                            label: s.notes_label,
                            icon: Icons.note_alt_outlined),
                        const SizedBox(height: 8),
                        Text(widget.notes!.trim(),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // زر الدفع النهائي
                FadeInUp(
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: AppButtonStyles.primaryRounded(context, 16).copyWith(
                        backgroundColor: WidgetStateProperty.all(goldColor),
                        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
                      ),
                      onPressed:
                          _loading ? null : () => _goToPayment(activeCurrency),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              s.proceed_to_payment,
                              style: GoogleFonts.cairo(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- المكونات الفرعية ---

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label,
            style: GoogleFonts.cairo(
                color: const Color(0xFFE0C097),
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(width: 8),
        Icon(icon, color: const Color(0xFFE0C097), size: 18),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          Text(label,
              style: GoogleFonts.cairo(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  final String symbol;
  final double rate;

  const _CartLine({
      required this.item,
      required this.symbol,
      required this.rate
  });

  @override
  Widget build(BuildContext context) {
    final lineTotal = (item.unitPrice * rate) * item.quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text("${lineTotal.toStringAsFixed(2)} $symbol",
              style: GoogleFonts.cairo(
                  color: const Color(0xFFE0C097), fontWeight: FontWeight.bold)),
          
          const Spacer(),
          
          Text("${item.productName} × ${item.quantity}",
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
          
          const SizedBox(width: 10),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: (item.imageMediaId != null && item.imageMediaId!.isNotEmpty)
                  ? SmartMediaImage(
                      mediaId: item.imageMediaId!, 
                      useCase: MediaUseCase.product,
                      fit: BoxFit.cover,
                    )
                  : (item.imageUrl != null 
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : Container(color: Colors.white10, child: const Icon(Icons.image, size: 15, color: Colors.white30)))
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;
  final String symbol;
  final double rate;

  const _TotalRow(
      {required this.total, required this.symbol, required this.rate});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final displayedTotal = total * rate;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("${displayedTotal.toStringAsFixed(2)} $symbol",
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
        Text(s.total,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }
}