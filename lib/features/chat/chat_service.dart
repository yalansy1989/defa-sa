import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart'; // يفضل إضافتها للتعرف الدقيق، أو نكتفي بالامتداد

/// ✅ خدمة الدردشة الملكية (الإصدار الذكي)
/// ترتبط بمشروع دِفا الرسمي وتدعم التصنيف التلقائي للملفات.
class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// 🚀 إرسال ذكي: يحدد نوع الرسالة تلقائياً ويحدث واجهة الأدمن
  Future<void> sendMessage({
    required String text,
    String? orderNumber,
    String? orderDocId,
    String type = 'text',
    String? fileUrl,
    Map<String, dynamic>? metadata, // بيانات إضافية ذكية (مثل حجم الملف)
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bool isOrder = orderNumber != null && orderNumber.isNotEmpty;
    
    // إعداد الرسالة بذكاء
    final messageData = {
      'senderId': user.uid,
      'senderName': user.displayName ?? 'عميل دِفا',
      'text': text,
      'type': type,
      'fileUrl': fileUrl,
      'metadata': metadata ?? {}, // حفظ تفاصيل الملف
      'createdAt': FieldValue.serverTimestamp(),
      'isAdmin': false,
      'isRead': false, // حالة القراءة
      'projectId': 'defa-sa-official', // ✅ ربط بسحابة بلجيكا الرسمية
      'orderNumber': orderNumber,
      'orderDocId': orderDocId,
      'category': isOrder ? 'order' : 'support',
    };

    // ✅ استخدام Batch Write لضمان السرعة والأمان (كل شيء يحدث أو لا شيء)
    final batch = _db.batch();

    // 1. إضافة الرسالة للكولكشن العام
    final msgRef = _db.collection('chats').doc();
    batch.set(msgRef, messageData);

    // 2. تحديث مؤشرات المستخدم (ليظهر في أعلى قائمة الأدمن)
    final userRef = _db.collection('users').doc(user.uid);
    batch.set(userRef, {
      'lastMessage': _getPreviewText(type, text),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1), // تنبيه الأدمن
      'lastSenderId': user.uid,
      'hasActiveTicket': true, // مؤشر ذكي لفتح تذكرة
    }, SetOptions(merge: true));

    // 3. إذا كانت مرتبطة بطلب، نحدث مستند الطلب أيضاً
    if (isOrder && orderDocId != null) {
      final orderRef = _db.collection('orders').doc(orderDocId);
      batch.update(orderRef, {
        'hasNewMessages': true,
        'lastChatTime': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// 🧠 رفع الملفات الذكي: يحدد النوع (صورة، pdf، صوت) تلقائياً
  Future<void> uploadChatFile({
    required File file,
    String? orderNumber,
    String? orderDocId,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final fileName = p.basename(file.path);
    final extension = p.extension(file.path).toLowerCase();
    
    // منطق ذكي لتحديد النوع
    String type = 'file';
    if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) type = 'image';
    else if (['.mp4', '.mov'].contains(extension)) type = 'video';
    else if (['.mp3', '.m4a', '.wav'].contains(extension)) type = 'audio';
    else if (extension == '.pdf') type = 'pdf';

    // تنظيم الملفات في السحابة
    final ref = _storage.ref().child('chats/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    
    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();
    final meta = await uploadTask.ref.getMetadata();

    // إرسال الرسالة مع البيانات الوصفية
    await sendMessage(
      text: _getPreviewText(type, fileName),
      orderNumber: orderNumber,
      orderDocId: orderDocId,
      type: type,
      fileUrl: url,
      metadata: {
        'size': meta.size,
        'contentType': meta.contentType,
        'fileName': fileName,
      },
    );
  }

  // مساعد لتحويل النوع لنص مقروء
  String _getPreviewText(String type, String fallback) {
    switch (type) {
      case 'image': return '📷 صورة جديدة';
      case 'video': return '🎥 فيديو';
      case 'audio': return '🎙️ تسجيل صوتي';
      case 'pdf': return '📄 ملف PDF';
      case 'file': return '📎 ملف مرفق';
      default: return fallback;
    }
  }
}