import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';

import 'package:defa_sa/models/cart_item.dart';
import 'package:defa_sa/features/home/order_confirm_page.dart';
import 'package:defa_sa/widgets/app_button_styles.dart';
import 'package:defa_sa/features/auth/login_screen.dart';
import 'package:defa_sa/services/analytics_service.dart';

// ✅ الترجمة
import 'package:defa_sa/l10n/app_localizations.dart';

// ✅ إعدادات المتجر (مصدر العملة)
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final String customerId;
  final String customerName;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _checkingAuth = true;
  bool _checkoutLogged = false;

  // ✅ العملة الديناميكية
  String _currencyCode = 'SAR';

  final Map<String, dynamic> _emptyShippingAddress = {
    'city': 'Direct Order',
    'line1': 'One-Step Checkout',
    'line2': '',
    'zip': '',
  };

  double get _total {
    double sum = 0;
    for (final item in widget.cartItems) {
      sum += (item.unitPrice * item.quantity);
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCurrency();
      _ensureSignedIn();
    });
  }

  // =========================
  // ✅ جلب عملة المتجر
  // =========================
  Future<void> _loadCurrency() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('store_settings')
          .doc('main')
          .get();

      final data = snap.data();
      final v = (data?['currency'] ??
              data?['currencyCode'] ??
              data?['currency_code'] ??
              'SAR')
          .toString()
          .toUpperCase();

      if (mounted) setState(() => _currencyCode = v);
    } catch (_) {}
  }

  Future<void> _logCheckoutStartOnce() async {
    if (_checkoutLogged) return;
    _checkoutLogged = true;
    try {
      await AnalyticsService.log(
        type: 'checkout_start',
        source: 'checkout',
        targetType: 'order',
        targetId: 'cart',
        meta: {
          'itemsCount': widget.cartItems.length,
          'total': _total,
          'currency': _currencyCode,
          'productIds': widget.cartItems.map((e) => e.productId).toList(),
        },
      );
    } catch (_) {}
  }

  Future<void> _ensureSignedIn() async {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) setState(() => _checkingAuth = false);
      _logCheckoutStartOnce();
      return;
    }

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(s.login_required_title, style: const TextStyle(color: Colors.white)),
        content: Text(s.login_required_content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.back)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.login)),
        ],
      ),
    );

    if (go == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }

    if (!mounted) return;
    final after = FirebaseAuth.instance.currentUser;
    if (after == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _checkingAuth = false);
    _logCheckoutStartOnce();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _processCheckout() {
    final s = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.cart_empty)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderConfirmPage(
          customerId: user.uid,
          customerName: user.displayName ?? widget.customerName,
          customerPhone: _phoneController.text.trim(),
          cartItems: widget.cartItems,
          total: _total,
          shippingAddress: _emptyShippingAddress,
          notes: _notesController.text.trim(),

          // ✅ تمرير العملة للطلب
          currencyCode: _currencyCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!;
    const goldColor = Color(0xFFE0C097);

    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E14),
        body: Center(child: CircularProgressIndicator(color: goldColor)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        title: Text(s.checkout_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeInUp(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SectionHeader(title: s.order_summary),
              const SizedBox(height: 12),
              ...widget.cartItems.map((e) => _CartLine(item: e, currency: _currencyCode)),
              const SizedBox(height: 12),
              _TotalRow(total: _total, currency: _currencyCode),

              const SizedBox(height: 30),

              _SectionHeader(title: s.customer_data),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: s.phone_number,
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.phone_iphone, color: goldColor),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "يرجى إدخال رقم الهاتف للمتابعة";
                  }
                  if (value.length < 8) {
                    return "رقم الهاتف غير صحيح";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SectionHeader(title: s.notes_label),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: s.notes_hint,
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: AppButtonStyles.primaryRounded(context, 16).copyWith(
                    backgroundColor: WidgetStateProperty.all(goldColor),
                  ),
                  onPressed: _processCheckout,
                  child: Text(
                    s.confirm_order_button,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "بالضغط على تأكيد، أنت توافق على شروط الخدمة",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// UI Components
// =========================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  final String currency;
  const _CartLine({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.unitPrice * item.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${lineTotal.toStringAsFixed(2)} $currency",
            style: const TextStyle(color: Color(0xFFE0C097), fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              "${item.productName} × ${item.quantity}",
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;
  final String currency;
  const _TotalRow({required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${total.toStringAsFixed(2)} $currency",
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const Text(
          "الإجمالي",
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
