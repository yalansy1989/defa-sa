import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


/**
 * ✅ خدمة دفع الإشعارات المتقدمة - مشروع دِفا الرسمي (defa-sa-official)
 * تم ضبط الإعدادات لتتوافق مع معايير الأداء في منطقة بلجيكا (europe-west1).
 */
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _started = false;
  String? _lastUid;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // 1) طلب صلاحية الإشعارات (مهم حتى على Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) التحقق من وجود مستخدم مسجل
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _lastUid = user.uid;

    // 3) جلب التوكن وحفظه في سحابة بلجيكا
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await _saveTokenForUserDoc(user.uid, token.trim());
    }

    // 4) تحديث عند تغيّر التوكن لضمان استمرارية الاتصال
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;

      final t = newToken.trim();
      if (t.isEmpty) return;

      await _saveTokenForUserDoc(u.uid, t);
    });

    // 5) مراقبة تغيّر المستخدم لضمان أمن التوكنات
    FirebaseAuth.instance.userChanges().listen((u) async {
      final prevUid = _lastUid;
      final nextUid = u?.uid;

      if (nextUid == null) {
        _lastUid = null;
        return;
      }

      // إذا تبدّل الحساب: نحذف توكن الجهاز من المستخدم السابق لحماية الخصوصية
      if (prevUid != null && prevUid != nextUid) {
        final t = await FirebaseMessaging.instance.getToken();
        if (t != null && t.trim().isNotEmpty) {
          await _deleteTokenForUserDoc(prevUid, t.trim());
        }
      }

      _lastUid = nextUid;

      // تسجيل التوكن للمستخدم الجديد في مشروع defa-sa-official
      final t2 = await FirebaseMessaging.instance.getToken();
      if (t2 != null && t2.trim().isNotEmpty) {
        await _saveTokenForUserDoc(nextUid, t2.trim());
      }
    });
  }

  String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /**
   * ✅ تهيئة مستند المستخدم في بلجيكا
   * يضمن الربط الصحيح مع Cloud Functions لضمان وصول الإشعارات
   */
  Future<DocumentReference<Map<String, dynamic>>> _ensureUserDocByUid(String uid) async {
    final usersCol = FirebaseFirestore.instance.collection('users');
    final docRef = usersCol.doc(uid);

    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'uid': uid,
        'projectId': 'defa-sa-official', // ✅ بصمة المشروع الرسمي
        'region': 'europe-west1',        // توثيق الموقع في بلجيكا
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return docRef;
  }

  Future<void> _saveTokenForUserDoc(String uid, String token) async {
    final userDocRef = await _ensureUserDocByUid(uid);

    // docId = token لتجنب تكرار العناوين في قاعدة البيانات
    final tokenRef = userDocRef.collection('fcmTokens').doc(token);

    await tokenRef.set({
      'token': token,
      'projectId': 'defa-sa-official',
      'platform': _platform(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // تحديث التوكن الأساسي في وثيقة المستخدم لسرعة الوصول من السيرفر
    await userDocRef.set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteTokenForUserDoc(String uid, String token) async {
    try {
      final usersCol = FirebaseFirestore.instance.collection('users');
      final userDocRef = usersCol.doc(uid);

      final snap = await userDocRef.get();
      if (!snap.exists) return;

      await userDocRef.collection('fcmTokens').doc(token).delete();
    } catch (_) {}
  }

  /// تحديث حالة التواجد (Ping) لضمان دقة إرسال الإشعارات
  Future<void> ping() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) return;

    final userDocRef = await _ensureUserDocByUid(user.uid);

    await userDocRef.collection('fcmTokens').doc(token.trim()).set({
      'lastSeenAt': FieldValue.serverTimestamp(),
      'platform': _platform(),
      'projectId': 'defa-sa-official',
    }, SetOptions(merge: true));
  }
}