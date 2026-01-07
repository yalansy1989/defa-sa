import 'package:cloud_firestore/cloud_firestore.dart';

/// يولد رقم طلب موحد: DF-100 ثم RB-101 ...
/// يعتمد على عدّاد في Firestore داخل:
/// counters/orders  { lastNumber: 99 }
class OrderNumberService {
  final FirebaseFirestore _db;
  OrderNumberService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const String _prefix = "DF";
  static const int _startFrom = 100;

  DocumentReference<Map<String, dynamic>> get _counterRef =>
      _db.collection("counters").doc("orders");

  /// يُرجع رقم الطلب بصيغة DF-### (ابتداءً من 100)
  Future<String> nextOrderNumber() async {
    return _db.runTransaction((tx) async {
      final snap = await tx.get(_counterRef);

      int last = 0;
      if (!snap.exists) {
        // أول مرة: نثبت lastNumber = 99 -> القادم يصير 100
        last = _startFrom - 1;
        tx.set(_counterRef, {"lastNumber": last}, SetOptions(merge: true));
      } else {
        final data = snap.data();
        final raw = data?["lastNumber"];
        if (raw is int) last = raw;
        if (raw is num) last = raw.toInt();
      }

      final next = (last < (_startFrom - 1)) ? (_startFrom) : (last + 1);
      tx.set(_counterRef, {"lastNumber": next}, SetOptions(merge: true));

      return "$_prefix-$next";
    });
  }

  /// تضمن وجود العداد (اختياري)
  Future<void> ensureInitialized() async {
    final snap = await _counterRef.get();
    if (!snap.exists) {
      await _counterRef.set({"lastNumber": _startFrom - 1});
    }
  }
}
