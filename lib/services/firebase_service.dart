import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/**
 * ✅ المحرك الرئيسي لخدمات Firebase - لوحة تحكم دِفا الرسمية (defa-sa-official)
 * تم ضبط الإعدادات لتعمل بتوافق تام مع منطقة بلجيكا (europe-west1) لضمان سرعة الإدارة.
 */
class FirebaseService {
  FirebaseService._internal();

  static final FirebaseService instance = FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ ربط قاعدة البيانات بالمشروع الرسمي الجديد (بلجيكا)
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // المستخدم (الأدمن) الحالي
  User? get currentUser => _auth.currentUser;

  // 🔐 تسجيل دخول الأدمن الرسمي
  // ملاحظة: الأدمن يستخدم بريده الرسمي المسجل في Firebase Console المشروع الجديد
  Future<User?> signInAdmin(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء تسجيل دخول الأدمن بمعايير عالية
      print("Admin Auth Error: ${e.code}");
      rethrow;
    }
  }

  // 👤 تحديث بيانات الأدمن وحفظ توكن الإشعارات للوحة التحكم
  Future<void> upsertAdminData({
    required String uid,
    required String name,
    String? fcmToken,
  }) async {
    await _db.collection('admins').doc(uid).set({
      'projectId': 'defa-sa-official',
      'name': name,
      'role': 'admin',
      'fcmToken': fcmToken,
      'region': 'europe-west1',
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 📊 جلب كافة الحجوزات (لإدارة الأدمن)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenAllAppointments() {
    return _db
        .collection('appointments')
        .where('projectId', isEqualTo: 'defa-sa-official')
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  // ✅ تحديث حالة حجز وإرسال إشعار تلقائي عبر الـ Functions
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    required String userId, // مطلوب لربط الإشعار بالعميل
  }) async {
    // 1. تحديث الحالة في Firestore
    await _db.collection('appointments').doc(appointmentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'managedBy': _auth.currentUser?.uid,
    });

    // 2. إنشاء مستند إشعار ليقوم الـ Worker في بلجيكا بإرساله فوراً للعميل
    await _db.collection('notifications').add({
      'projectId': 'defa-sa-official',
      'type': 'order_update',
      'title': 'تحديث في حالة حجزك',
      'body': 'تم تغيير حالة حجزك إلى: $status',
      'targetRole': 'user',
      'targetUserId': userId,
      'target': {
        'screen': 'order_details',
        'id': appointmentId,
      },
      'push': {
        'enabled': true,
        'sent': false,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 📂 إدارة ملفات المستخدمين (مشاهدة كافة الملفات المرفوعة في بلجيكا)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenAllUserFiles() {
    return _db
        .collection('files')
        .where('projectId', isEqualTo: 'defa-sa-official')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 💬 ستريم لجميع رسائل الدعم الفني أو الدردشات النشطة
  Stream<QuerySnapshot<Map<String, dynamic>>> listenActiveChats() {
    return _db
        .collection('chats')
        .where('projectId', isEqualTo: 'defa-sa-official')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}