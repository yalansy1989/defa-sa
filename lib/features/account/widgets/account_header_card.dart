import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:defa_sa/l10n/app_localizations.dart';

class AccountHeaderCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final ImageProvider? avatarImage;
  final bool isVip;
  final VoidCallback onEditTap;

  const AccountHeaderCard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.avatarImage,
    required this.isVip,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // الألوان الملكية
    const goldColor = Color(0xFFE0C097);
    const deepDarkColor = Color(0xFF0A0E14);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [
            const Color(0xFF161B22), // لون الكارد الأساسي
            deepDarkColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: InkWell(
        onTap: onEditTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            // صورة البروفايل مع إطار ذهبي
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.person_rounded, color: Colors.white70, size: 30)
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: goldColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: deepDarkColor, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Colors.black,
                  ),
                )
              ],
            ),
            const SizedBox(width: 16),
            
            // معلومات المستخدم
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName.isEmpty ? l10n.accountNamePlaceholder : userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail.isEmpty ? l10n.accountEmailPlaceholder : userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 10),
            
            // شارة العضوية
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isVip ? goldColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isVip ? goldColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                isVip ? l10n.accountVipLabel : l10n.accountStandardLabel,
                style: GoogleFonts.cairo(
                  color: isVip ? goldColor : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}