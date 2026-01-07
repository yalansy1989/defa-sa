import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:defa_sa/l10n/app_localizations.dart';

class AccountServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// ✅ Optional badge (e.g., tasks count)
  final int? badgeCount;

  const AccountServiceCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // الألوان الملكية المعتمدة
    const goldColor = Color(0xFFE0C097);
    
    final int bc = (badgeCount ?? 0);
    final bool showBadge = bc > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03), // خلفية زجاجية داكنة
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)), // حدود خفيفة جداً
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container + badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: goldColor.withOpacity(0.1), // خلفية ذهبية خفيفة للأيقونة
                      border: Border.all(color: goldColor.withOpacity(0.2)),
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: goldColor, // الأيقونة ذهبية
                    ),
                  ),
                  
                  // شارة التنبيهات (Badge)
                  if (showBadge)
                    PositionedDirectional(
                      top: -6,
                      end: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0A0E14), width: 2), // حدود بلون الخلفية
                        ),
                        child: Text(
                          bc > 99 ? '99+' : bc.toString(),
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              const Spacer(),
              
              // النصوص
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // استخدام نص احتياطي في حال لم يتم تعريف المفتاح في ملف الترجمة
                    l10n.tapToOpenLabel, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}