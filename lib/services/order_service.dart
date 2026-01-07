import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:defa_sa/models/cart_item.dart';
import 'package:defa_sa/services/order_number_service.dart';
import 'package:defa_sa/services/notification_service.dart';

/**
 * ✅ محرك الطلبات الفاخر لمشروع دِفا الرسمي (defa-sa-official)
 * تم ضبط الإعدادات لتعمل بتوافق تام مع منطقة بلجيكا (europe-west1).
 */
class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // ✅ pricingMode resolver
  // =========================
  static String _resolvePricingMode({required String type, String? pricingMode}) {
    if (pricingMode != null && pricingMode.trim().isNotEmpty) {
      return pricingMode.trim().toLowerCase();
    }
    switch (type.trim().toLowerCase()) {
      case 'subscription':
        return 'subscription';
      case 'contact':
      case 'service':
        return 'contact';
      default:
        return 'price';
    }
  }

  // =========================
  // ✅ fetch product cover (for imageUrl)
  // =========================
  static Future<String?> _fetchProductCover(String productId) async {
    if (productId.trim().isEmpty) return null;
    try {
      final snap = await _db.collection('products').doc(productId).get();
      final data = snap.data();
      final url = (data?['coverImage'] ??
              data?['imageUrl'] ??
              data?['image'] ??
              data?['thumbnail'])
          ?.toString()
          .trim();
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  // =========================
  // ✅ Store currency resolver (fallback)
  // =========================
  static String? _cachedCurrencyCode;
  static int _cachedCurrencyAtMs = 0;

  static Future<String> _fetchStoreCurrencyCode() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_cachedCurrencyCode != null && (now - _cachedCurrencyAtMs) < 60000) {
        return _cachedCurrencyCode!;
      }

      // Try: store_settings/main
      try {
        final s1 = await _db.collection('store_settings').doc('main').get();
        final d1 = s1.data();
        final v1 = (d1?['currency'] ??
                d1?['currencyCode'] ??
                d1?['currency_code'] ??
                d1?['defaultCurrency'])
            ?.toString()
            .trim();
        if (v1 != null && v1.isNotEmpty) {
          _cachedCurrencyCode = v1.toUpperCase();
          _cachedCurrencyAtMs = now;
          return _cachedCurrencyCode!;
        }
      } catch (_) {}

      // Try: settings/main
      try {
        final s2 = await _db.collection('settings').doc('main').get();
        final d2 = s2.data();
        final v2 = (d2?['currency'] ??
                d2?['currencyCode'] ??
                d2?['currency_code'] ??
                d2?['defaultCurrency'])
            ?.toString()
            .trim();
        if (v2 != null && v2.isNotEmpty) {
          _cachedCurrencyCode = v2.toUpperCase();
          _cachedCurrencyAtMs = now;
          return _cachedCurrencyCode!;
        }
      } catch (_) {}

      _cachedCurrencyCode = 'SAR';
      _cachedCurrencyAtMs = now;
      return 'SAR';
    } catch (_) {
      return 'SAR';
    }
  }

  // =========================
  // ✅ Create Order (AUTH REQUIRED)
  // =========================
  static Future<String> createOrder({
    required String customerId, 
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    required double total,
    List<CartItem>? cartItems,
    dynamic shippingAddress,
    String? notes,
    String type = "product",
    String? pricingMode,
    String? title,
    String? productId,
    String? productName,
    String? currencyCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('AUTH_REQUIRED');

    final doc = _db.collection('orders').doc();

    // ✅ توليد رقم طلب موحد عبر الخدمة المخصصة
    final orderNumber = await OrderNumberService().nextOrderNumber();

    final resolvedType =
        type.trim().isEmpty ? 'product' : type.trim().toLowerCase();
    final resolvedPricingMode =
        _resolvePricingMode(type: resolvedType, pricingMode: pricingMode);

    final resolvedCurrency =
        (currencyCode != null && currencyCode.trim().isNotEmpty)
            ? currencyCode.trim().toUpperCase()
            : await _fetchStoreCurrencyCode();

    // ✅ بناء عناصر الطلب مع التأكد من جلب الصور
    final items = <Map<String, dynamic>>[];

    if (cartItems != null && cartItems.isNotEmpty) {
      for (final item in cartItems) {
        final m = item.toMap();
        final img = (m['imageUrl'] ?? '').toString().trim();
        if (img.isEmpty) {
          final fetched = await _fetchProductCover(item.productId);
          if (fetched != null) m['imageUrl'] = fetched;
        }
        m['pricingMode'] = resolvedPricingMode;
        items.add(m);
      }
    } else {
      final pid = (productId ?? '').trim();
      final pname = (productName ?? title ?? '').trim();

      String? img;
      if (pid.isNotEmpty) img = await _fetchProductCover(pid);

      if (pid.isNotEmpty || pname.isNotEmpty) {
        items.add({
          'productId': pid,
          'productName': pname,
          'quantity': 1,
          'unitPrice': (resolvedPricingMode == 'price') ? total : 0,
          'totalPrice': (resolvedPricingMode == 'price') ? total : 0,
          if (img != null && img.trim().isNotEmpty) 'imageUrl': img.trim(),
          'pricingMode': resolvedPricingMode,
        });
      }
    }

    final resolvedTitle = (title ?? '').trim().isNotEmpty
        ? title!.trim()
        : (productName ?? '').trim().isNotEmpty
            ? productName!.trim()
            : (items.isNotEmpty
                ? (items.first['productName'] ?? 'طلب').toString()
                : 'طلب');

    // ✅ حفظ الطلب في مستودع بلجيكا الرسمي
    await doc.set({
      'id': doc.id,
      'orderNumber': orderNumber,
      'projectId': 'defa-sa-official', // ✅ بصمة المشروع الرسمي الجديد
      'region': 'europe-west1',        // توثيق الموقع الجغرافي

      'type': resolvedType,
      'pricingMode': resolvedPricingMode,
      'title': resolvedTitle,

      if ((productId ?? '').trim().isNotEmpty) 'productId': productId!.trim(),
      if ((productName ?? '').trim().isNotEmpty)
        'productName': productName!.trim(),

      'status': 'new',

      'customerId': user.uid,
      'customerName': customerName.trim().isNotEmpty
          ? customerName.trim()
          : (user.displayName ?? 'عميل'),
      'customerEmail': (customerEmail ?? user.email ?? '').trim(),
      'customerPhone': (customerPhone ?? '').trim(),

      'items': items,
      'total': total,
      'currency': resolvedCurrency,

      'shippingAddress': shippingAddress,
      'notes': (notes ?? '').trim(),

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 إشعار فوري للأدمن عبر الدوال السحابية في بلجيكا
    try {
      await NotificationService.create(
        type: 'order',
        title: 'طلب جديد',
        body: '🛍️ $resolvedTitle • رقم الطلب $orderNumber',
        targetRole: 'admin',
        screen: 'order_details',
        id: doc.id,
        extra: {
          'orderNumber': orderNumber,
          'productName': resolvedTitle,
          'orderType': resolvedType,
          'currency': resolvedCurrency,
          'projectId': 'defa-sa-official',
        },
      );
    } catch (_) {}

    return doc.id;
  }

  // =========================
  // ✅ Reorder: returns new orderId (AUTH REQUIRED)
  // =========================
  static Future<String> reorderFromOrder({required String orderId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('AUTH_REQUIRED');

    final snap = await _db.collection('orders').doc(orderId).get();
    if (!snap.exists) throw Exception('ORDER_NOT_FOUND');

    final data = snap.data() as Map<String, dynamic>;
    final itemsRaw = data['items'];

    final List<Map<String, dynamic>> items = [];
    if (itemsRaw is List) {
      for (final it in itemsRaw) {
        if (it is Map) items.add(Map<String, dynamic>.from(it));
      }
    }

    final oldType = (data['type'] ?? 'product').toString().trim().toLowerCase();
    final oldPm = (data['pricingMode'] ?? '').toString().trim().toLowerCase();
    final resolvedPricingMode = _resolvePricingMode(type: oldType, pricingMode: oldPm);

    final newDoc = _db.collection('orders').doc();
    final newOrderNumber = await OrderNumberService().nextOrderNumber();

    final resolvedCurrency =
        (data['currency'] ?? '').toString().trim().isNotEmpty
            ? (data['currency'] ?? '').toString().trim().toUpperCase()
            : await _fetchStoreCurrencyCode();

    await newDoc.set({
      'id': newDoc.id,
      'orderNumber': newOrderNumber,
      'projectId': 'defa-sa-official', // ✅ الربط بالمشروع الرسمي

      'type': oldType,
      'pricingMode': resolvedPricingMode,
      'title': (data['title'] ?? data['productName'] ?? 'طلب').toString(),

      'status': 'new',
      'customerId': user.uid,
      'customerName': user.displayName ?? (data['customerName'] ?? 'عميل').toString(),
      'customerEmail': user.email ?? (data['customerEmail'] ?? '').toString(),
      'customerPhone': (data['customerPhone'] ?? '').toString(),

      'items': items,
      'total': (data['total'] ?? 0),
      'currency': resolvedCurrency,

      'notes': (data['notes'] ?? '').toString(),
      'reorderedFrom': orderId,

      if (data['productId'] != null)
        'productId': (data['productId'] ?? '').toString(),
      if (data['productName'] != null)
        'productName': (data['productName'] ?? '').toString(),

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await NotificationService.create(
        type: 'order',
        title: 'إعادة طلب',
        body: '🔁 تم إنشاء إعادة طلب • رقم الطلب $newOrderNumber',
        targetRole: 'admin',
        screen: 'order_details',
        id: newDoc.id,
        extra: {
          'orderNumber': newOrderNumber,
          'orderType': oldType,
          'currency': resolvedCurrency,
          'projectId': 'defa-sa-official',
        },
      );
    } catch (_) {}

    return newDoc.id;
  }

  // =========================
  // ✅ Stream: my orders (safe if user == null)
  // =========================
  static Stream<QuerySnapshot<Map<String, dynamic>>> myOrdersStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: user.uid)
        .where('projectId', isEqualTo: 'defa-sa-official') // ✅ فلترة حسب المشروع الرسمي
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // =========================
  // ✅ Cancel order (client only)
  // =========================
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('AUTH_REQUIRED');

    final normalized = status.trim().toLowerCase();
    if (normalized != 'canceled') throw Exception('FORBIDDEN_STATUS_CHANGE');

    final ref = _db.collection('orders').doc(orderId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('ORDER_NOT_FOUND');

    final current = (snap.data()!['status'] ?? '').toString().trim().toLowerCase();

    // القواعد الملكية للإلغاء من طرف العميل
    final canCancel = current == 'new' ||
        current == 'pending' ||
        current == 'review' ||
        current == 'in_review' ||
        current == 'under_review' ||
        current == 'pending_review' ||
        current == 'قيدالمراجعة' ||
        current == 'قيد المراجعة' ||
        current == 'قيد المراجعه';

    if (!canCancel) throw Exception('ORDER_NOT_CANCELABLE');

    await ref.update({
      'status': 'canceled',
      'updatedAt': FieldValue.serverTimestamp(),
      'canceledBy': user.uid,
      'canceledAt': FieldValue.serverTimestamp(),
    });

    try {
      // إشعار للأدمن بحالة الإلغاء في بلجيكا
      await NotificationService.create(
        type: 'order',
        title: 'تم إلغاء طلب',
        body: '❌ تم إلغاء الطلب رقم ${snap.data()?['orderNumber'] ?? orderId} من قبل العميل',
        targetRole: 'admin',
        screen: 'order_details',
        id: orderId,
        extra: {'projectId': 'defa-sa-official'},
      );

      // تأكيد الإلغاء للعميل لضمان الفخامة التقنية
      await NotificationService.create(
        type: 'order',
        title: 'تم إلغاء طلبك',
        body: 'تم إلغاء طلبك بنجاح من نظام دِفا',
        targetRole: 'user',
        targetUserId: user.uid,
        screen: 'order_details',
        id: orderId,
        extra: {'projectId': 'defa-sa-official'},
      );
    } catch (_) {}
  }
}