import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ إضافة المكتبة

// ✅ Localization
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/locale_controller.dart';
import 'l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

import 'core/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/orders/order_details_screen.dart';

// ✅ الصفحات
import 'features/onboarding/onboarding_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/splash/splash_screen.dart'; 
import 'features/language/language_selection_screen.dart'; // ✅ تأكد من المسار الصحيح لشاشة اللغة

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final LocaleController globalLocaleController = LocaleController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ التحقق من حالة اختيار اللغة لأول مرة
  final prefs = await SharedPreferences.getInstance();
  final bool isLanguageSet = prefs.getBool('is_language_set') ?? false;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("⚠️ تنبيه: الفايربيس يعمل بالفعل، تم تجاوز التهيئة.");
  }

  await globalLocaleController.loadSaved();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/notification_icon');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel);
  } catch (_) {}

  unawaited(
    FirebaseFirestore.instance
        .collection('connection_test')
        .doc('status')
        .set({
          'connected': true,
          'project': 'defa-sa-official',
          'region': 'europe-west1',
          'environment': 'production',
          'last_login': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 4))
        .catchError((_) {}),
  );

  // مرر حالة اللغة إلى التطبيق
  runApp(MyApp(
    localeController: globalLocaleController,
    isLanguageSet: isLanguageSet,
  ));
}

class MyApp extends StatelessWidget {
  final LocaleController localeController;
  final bool isLanguageSet; // ✅ استقبال الحالة

  const MyApp({
    super.key, 
    required this.localeController, 
    required this.isLanguageSet,
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    globalLocaleController.changeLocale(newLocale);
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    switch (name) {
      case '/payment':
        return _buildPaymentRoute(settings.arguments);
      case '/checkout':
        return _buildCheckoutRoute(settings.arguments);
      default:
        return null;
    }
  }

  MaterialPageRoute _buildPaymentRoute(dynamic args) {
    return MaterialPageRoute(
      builder: (_) => const _MissingArgsScreen(
        title: 'بوابة الدفع',
        details: 'جاري تأمين اتصالك ببوابة الدفع الفاخرة...',
      ),
    );
  }

  MaterialPageRoute _buildCheckoutRoute(dynamic args) {
    return MaterialPageRoute(
      builder: (_) => const _MissingArgsScreen(
        title: 'إتمام الطلب',
        details: 'جاري مراجعة سلة مشتريات دِفا الرسمية...',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          onGenerateTitle: (ctx) =>
              AppLocalizations.of(ctx)?.appTitle ?? 'متجر دِفــــا الرسمي',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeForLocale(
              localeController.locale ?? const Locale('ar')),
          locale: localeController.locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // ✅ نظام التوجيه المحدث
          routes: {
            // المسار الرئيسي '/' يوجه لشاشة البداية
            '/': (context) => const SplashScreen(),
            
            // شاشة اللغة تظهر فقط إذا لم يتم ضبطها سابقاً (يتم توجيهها من SplashScreen)
            '/language_selection': (context) => const LanguageSelectionScreen(),
            
            '/onboarding': (context) => OnboardingScreen(localeController: globalLocaleController),
            
            '/app': (_) => const _AuthGate(),
          },
          
          onGenerateRoute: _onGenerateRoute,
          
          builder: (context, child) {
            final code = localeController.locale?.languageCode ?? 'ar';
            return Directionality(
              textDirection: code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E14),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFE0C097))),
          );
        }
        if (snapshot.hasData) {
          return _ClientPushBootstrapper(child: const MainShell());
        }
        return const LoginScreen();
      },
    );
  }
}

class _ClientPushBootstrapper extends StatefulWidget {
  final Widget child;
  const _ClientPushBootstrapper({required this.child});

  @override
  State<_ClientPushBootstrapper> createState() => _ClientPushBootstrapperState();
}

class _ClientPushBootstrapperState extends State<_ClientPushBootstrapper> {
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenSub;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initClientPush();
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    _onMessageSub?.cancel();
    _onOpenSub?.cancel();
    super.dispose();
  }

  Future<void> _initClientPush() async {
    if (_initialized) return;
    _initialized = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission(
        alert: true, 
        badge: true, 
        sound: true,
        provisional: false,
      );
      await _saveTokenIfPossible(user.uid);
    } catch (_) {}

    _tokenSub = messaging.onTokenRefresh.listen((newToken) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) await _saveTokenToFirestore(u.uid, newToken.trim());
    });

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      final notif = message.notification;
      if (notif == null) return;

      await flutterLocalNotificationsPlugin.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            highImportanceChannel.id,
            highImportanceChannel.name,
            channelDescription: highImportanceChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/notification_icon', 
            color: const Color(0xFFE0C097), 
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });

    _onOpenSub = FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleNotificationTap(message);
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) await _handleNotificationTap(initial);
  }

  Future<void> _saveTokenIfPossible(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveTokenToFirestore(uid, token.trim());
      }
    } catch (_) {}
  }

  Future<DocumentReference<Map<String, dynamic>>> _ensureUserDocByUid(String uid) async {
    final docRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        "uid": uid,
        "projectId": "defa-sa-official",
        "region": "europe-west1",
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return docRef;
  }

  Future<void> _saveTokenToFirestore(String uid, String token) async {
    final userDocRef = await _ensureUserDocByUid(uid);
    final ref = userDocRef.collection("fcmTokens").doc(token);

    await ref.set({
      "token": token,
      "platform": kIsWeb ? "web" : (Platform.isAndroid ? "android" : "ios"),
      "projectId": "defa-sa-official",
      "lastSeenAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userDocRef.set({
      "fcmToken": token,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final screen = (data["screen"] ?? "").toString();
    final id = (data["id"] ?? "").toString();

    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    if (screen == "order_details" && id.isNotEmpty) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: id),
        ),
      );
    } else if (screen == "chat") {
      if (data.containsKey("orderNumber")) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen.order(
              orderNumber: data["orderNumber"],
              orderDocId: id,
              orderTitle: "طلب #${data["orderNumber"]}",
            ),
          ),
        );
      } else {
        nav.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen.support(),
          ),
        );
      }
    } else if (screen == "support") {
      nav.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen.support(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MissingArgsScreen extends StatelessWidget {
  final String title;
  final String details;

  const _MissingArgsScreen({required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            details,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}