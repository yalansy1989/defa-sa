import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:defa_sa/models/cart_item.dart';
import 'package:defa_sa/services/order_service.dart';
import 'package:defa_sa/widgets/checkout_stepper.dart';
import 'package:defa_sa/widgets/app_button_styles.dart';

// استيراد شاشة النجاح
import 'package:defa_sa/features/orders/widgets/order_result_screen.dart';

import 'package:defa_sa/l10n/app_localizations.dart';
import 'package:defa_sa/features/shell/main_shell.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;

  final String customerId; 
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  final dynamic shippingAddress;
  final String? notes;

  final bool requiresShipping;
  final String orderType; 
  final String pricingMode; 
  final String currencyCode;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.total,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.shippingAddress,
    this.notes,
    this.requiresShipping = false,
    this.orderType = "product",
    this.pricingMode = "price",
    this.currencyCode = 'SAR',
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _loading = false;
  String _method = 'cod';
  final _bankRefController = TextEditingController();

  static const Color goldColor = Color(0xFFE0C097);
  static const Color deepDarkColor = Color(0xFF0A0E14);

  @override
  void dispose() {
    _bankRefController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final s = AppLocalizations.of(context)!;
    if (_loading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.please_login_first)),
      );
      return;
    }

    if (_method == 'bank' && _bankRefController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.bank_ref_required_msg)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final extra = StringBuffer();
      extra.writeln("[PAYMENT]");
      extra.writeln(
        "method=${_method == 'cod' ? s.cod_title : s.bank_transfer_title}",
      );
      if (_method == 'bank') {
        extra.writeln("bank_ref=${_bankRefController.text.trim()}");
      }

      final mergedNotes = [
        if ((widget.notes ?? '').trim().isNotEmpty) widget.notes!.trim(),
        extra.toString().trim(),
      ].join("\n\n");

      // 1. إنشاء الطلب
      final orderId = await OrderService.createOrder(
        customerId: user.uid,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
        cartItems: widget.cartItems,
        total: widget.total,
        shippingAddress: widget.requiresShipping ? widget.shippingAddress : null,
        notes: mergedNotes,
        type: widget.orderType,
        pricingMode: widget.pricingMode,
        currencyCode: widget.currencyCode,
      );

      if (!mounted) return;

      // 2. جلب رقم الطلب للعرض
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final orderNumber = (snap.data()?['orderNumber'] ?? '').toString();

      // 3. التوجيه لصفحة النجاح
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (resultCtx) => OrderResultScreen(
            status: OrderResultStatus.success,
            title: s.order_success_title,
            message: s.order_success_msg,
            orderNumber: orderNumber,
            
            // ✅ تمرير المعرف لفتح التفاصيل
            orderId: orderId, 
            
            primaryText: s.return_to_home,
            onPrimary: () {
              Navigator.of(resultCtx).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainShell(initialIndex: 0),
                ),
                (r) => false,
              );
            },

            secondaryText: s.view_order,
            
            // ✅✅✅ التعديل هنا: جعلناها null
            // عندما تكون null، ستقوم شاشة OrderResultScreen تلقائياً بفتح صفحة تفاصيل الطلب (OrderDetailsScreen)
            // بدلاً من محاولة الذهاب للصفحة الرئيسية وتخمين التبويب.
            onSecondary: null, 
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (resultCtx) => OrderResultScreen(
            status: OrderResultStatus.failed,
            title: s.order_failed_title,
            message: s.order_failed_msg,
            orderNumber: "---",
            primaryText: s.retry_button,
            onPrimary: () => Navigator.of(resultCtx).pop(),
            secondaryText: s.return_to_home,
            onSecondary: () {
              Navigator.of(resultCtx).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainShell(initialIndex: 0),
                ),
                (r) => false,
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              s.payment_title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            physics: const BouncingScrollPhysics(),
            children: [
              const CheckoutStepper(currentStep: 2),
              const SizedBox(height: 24),

              Text(
                s.choose_payment_method,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),

              _PaymentMethodTile(
                title: s.cod_title,
                subtitle: s.cod_subtitle,
                value: 'cod',
                groupValue: _method,
                onChanged: (v) => setState(() => _method = v),
                icon: Icons.local_shipping_outlined,
              ),

              const SizedBox(height: 12),

              _PaymentMethodTile(
                title: s.bank_transfer_title,
                subtitle: s.bank_transfer_subtitle,
                value: 'bank',
                groupValue: _method,
                onChanged: (v) => setState(() => _method = v),
                icon: Icons.account_balance_outlined,
              ),

              if (_method == 'bank') ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.bank_ref_label,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _bankRefController,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: s.bank_ref_required_msg,
                          hintStyle: GoogleFonts.cairo(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.bank_transfer_subtitle,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Text(
                      "${(widget.total * rate).toStringAsFixed(2)} $symbol",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s.total,
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: AppButtonStyles.primaryRounded(context, 16).copyWith(
                    backgroundColor: WidgetStateProperty.all(goldColor),
                    overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
                  ),
                  onPressed: _loading ? null : _submitOrder,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          s.confirm_order_button,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),
              Text(
                s.total_items_count(widget.cartItems.length.toString()),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: Colors.white24),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    const goldColor = Color(0xFFE0C097);

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? goldColor : Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: selected ? goldColor : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? goldColor : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}