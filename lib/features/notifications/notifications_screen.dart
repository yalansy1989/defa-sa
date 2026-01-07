import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:google_fonts/google_fonts.dart';

// ✅ استيراد الترجمة
import 'package:defa_sa/l10n/app_localizations.dart';

// ✅ الألوان الفاخرة المعتمدة
const Color _kBackground = Color(0xFF0A0E14);
const Color _kCardColor = Color(0xFF161B22); // أغمق قليلاً للتباين
const Color _kAccentGold = Color(0xFFE0C097);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ دالة لتمييز إشعار واحد كمقروء
  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (_) {}
  }

  // ✅ دالة لتحديد الكل كمقروء
  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    
    // جلب كل الإشعارات غير المقروءة لهذا المستخدم
    final snapshot = await _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  // ✅ حذف إشعار
  Future<void> _deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes}د';
    if (diff.inDays < 1) return DateFormat('h:mm a').format(time);
    return DateFormat('MMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _kBackground,
        body: Center(child: CircularProgressIndicator(color: _kAccentGold)),
      );
    }

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          s.notifications_title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: _kBackground,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: s.mark_all_read,
            icon: const Icon(Icons.done_all, color: _kAccentGold),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ الاستعلام: إشعارات موجهة لهذا المستخدم
        stream: _firestore
            .collection('notifications')
            .where('targetUserId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kAccentGold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    s.no_notifications_yet,
                    style: GoogleFonts.cairo(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['read'] == true;
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
              
              // ✅ التحقق مما إذا كان الإشعار من النظام (لعرض الشعار)
              // نفترض وجود حقل 'type' أو 'isSystem' في الإشعار
              final isSystemNotification = data['type'] == 'system' || data['sender'] == 'admin';

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                onDismissed: (_) => _deleteNotification(doc.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isRead ? _kCardColor.withOpacity(0.4) : _kCardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isRead 
                          ? Colors.white.withOpacity(0.03) 
                          : _kAccentGold.withOpacity(0.3),
                      width: isRead ? 1 : 1.5,
                    ),
                    boxShadow: isRead ? [] : [
                      BoxShadow(
                        color: _kAccentGold.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      if (!isRead) _markAsRead(doc.id);
                      // TODO: إضافة التوجيه لصفحة الطلب إذا كان الإشعار مرتبطاً بطلب
                    },
                    leading: Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSystemNotification 
                            ? _kAccentGold.withOpacity(0.1) 
                            : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: isSystemNotification 
                            ? Border.all(color: _kAccentGold.withOpacity(0.3)) 
                            : null,
                      ),
                      child: isSystemNotification
                          // ✅ استخدام الشعار للإشعارات الرسمية
                          ? Image.asset('assets/images/icon.png', color: _kAccentGold) 
                          : Icon(
                              isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                              color: isRead ? Colors.white38 : _kAccentGold,
                              size: 24,
                            ),
                    ),
                    title: Text(
                      data['title'] ?? 'إشعار جديد',
                      style: GoogleFonts.cairo(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: isRead ? Colors.white70 : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          data['body'] ?? '',
                          style: GoogleFonts.cairo(
                            color: isRead ? Colors.white38 : Colors.white60,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(timestamp),
                          style: GoogleFonts.cairo(
                            fontSize: 11, 
                            color: isRead ? Colors.white24 : _kAccentGold.withOpacity(0.8),
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _kAccentGold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}