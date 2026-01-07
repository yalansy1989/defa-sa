import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/**
 * ✅ مؤشر خطوات الدفع الملكي لمشروع دِفا الرسمي (defa-sa-official)
 * تم إصلاح استدعاءات التعريب لتعمل بتوافق تام مع الملفات المولدة.
 */
class CheckoutStepper extends StatelessWidget {
  final int currentStep; // 0 = المنتج, 1 = التأكيد, 2 = الدفع

  const CheckoutStepper({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    Widget step({
      required int index,
      required String label,
      required IconData icon,
    }) {
      final active = index == currentStep;
      final done = index < currentStep;

      Color color;
      if (active) {
        color = theme.colorScheme.primary;
      } else if (done) {
        color = Colors.green;
      } else {
        color = Colors.grey.withOpacity(0.6);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(
                color: color, 
                width: active ? 2.0 : 1.2,
              ),
              boxShadow: active ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ] : null,
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: color,
              letterSpacing: 0.5,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.cardColor.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Divider(
              indent: 40,
              endIndent: 40,
              thickness: 1,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ✅ تم الإصلاح: استدعاء الخصائص مباشرة
              step(
                index: 0, 
                label: l10n?.checkout_step_product ?? "المنتج", 
                icon: Icons.shopping_bag_outlined
              ),
              step(
                index: 1, 
                label: l10n?.checkout_step_confirm ?? "التأكيد", 
                icon: Icons.assignment_turned_in_outlined
              ),
              step(
                index: 2, 
                label: l10n?.checkout_step_payment ?? "الدفع", 
                icon: Icons.credit_card_outlined
              ),
            ],
          ),
        ],
      ),
    );
  }
}