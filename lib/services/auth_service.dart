import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ✅ خدمة الهوية والتوثيق لمشروع دِفا الرسمي (defa-sa-official)
/// تم تحديثها لربط المستخدمين بمشروع بلجيكا لضمان فخامة وصول الدردشات والبيانات.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// المستخدم الحالي
  static User? get currentUser => _auth.currentUser;

  /// متابعة حالة دخول المستخدم
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// ✅ تسجيل الدخول باستخدام Google مع ربط المشروع الرسمي الجديد
  static Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // حفظ/تحديث بيانات المستخدم في Firestore لضمان الظهور في لوحة أدمن دِفا الرسمية
      final userDoc = await _db.collection('users').doc(user.uid).get();
      
      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'provider': 'google',
        'role': 'client',
        'projectId': 'defa-sa-official', // ✅ الربط بمشروع بلجيكا الرسمي
        'region': 'europe-west1',        // توثيق الموقع الجغرافي للبيانات
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      };

      if (!userDoc.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _db.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      return user;
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في المصادقة';
      if (e.code == 'account-exists-with-different-credential') {
        message = 'الحساب موجود مسبقاً بوسيلة دخول مختلفة';
      } else if (e.code == 'network-request-failed') {
        message = 'فشل الاتصال بالشبكة، تأكد من اتصالك بالإنترنت';
      }
      throw Exception(e.message ?? message);
    } catch (e) {
      throw Exception("Google Sign-In Error: $e");
    }
  }

  /// ✅ إنشاء حساب جديد بالبريد (Named Parameters) للمشروع الرسمي
  static Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return null;

      await user.updateDisplayName(name);

      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'photoURL': null,
        'provider': 'password',
        'role': 'client',
        'projectId': 'defa-sa-official', // ✅ التوثيق للمشروع الرسمي الجديد
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'environment': 'production',
      }, SetOptions(merge: true));

      return user;
    } on FirebaseAuthException catch (e) {
      String message = 'فشل إنشاء الحساب';
      if (e.code == 'email-already-in-use') {
        message = 'هذا البريد الإلكتروني مستخدم بالفعل';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جداً';
      }
      throw Exception(e.message ?? message);
    } catch (e) {
      throw Exception("Register Error: $e");
    }
  }

  /// ✅ تسجيل الدخول بالبريد (تم تحديث المعرف للمشروع الرسمي)
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // تحديث وقت آخر ظهور ومعرف المشروع لضمان استمرارية الربط في سحابة بلجيكا
      await _db.collection('users').doc(cred.user?.uid).set({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'projectId': 'defa-sa-official', // ✅ الانتقال للمشروع الرسمي
      }, SetOptions(merge: true));

      return cred.user;
    } on FirebaseAuthException catch (e) {
      String message = 'فشل تسجيل الدخول';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      throw Exception(e.message ?? message);
    }
  }

  /// تسجيل الخروج
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception("Logout Error: $e");
    }
  }
}