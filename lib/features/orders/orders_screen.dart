import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'order_details_screen.dart';
import 'package:defa_sa/l10n/app_localizations.dart';
import 'package:defa_sa/widgets/price_text.dart'; // ✅ تحويل العملة من Firestore

class OrdersScreen extends StatefulWidget {
  final String? autoOpenOrderId;
  const OrdersScreen({super.key, this.autoOpenOrderId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedStatus = 'all';
  bool _preferIndexedQuery = true;
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  bool _didAutoOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoOpen && widget.autoOpenOrderId != null) {
      _didAutoOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showOrderDetails(context, orderId: widget.autoOpenOrderId!);
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    final user = _currentUser;
    if (user == null) return const Stream.empty();

    final base = FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: user.uid);

    if (_preferIndexedQuery) {
      // ✅ محاولة استخدام الفهرس للسرعة
      return base.orderBy('createdAt', descending: true).snapshots();
    }
    return base.snapshots();
  }

  String _normalizeStatus(String? raw) {
    final s0 = (raw ?? '').trim().toLowerCase();
    final s = s0
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll('__', '_');

    if (['new', 'pending', 'in_review', 'under_review', 'review', 'pending_review']
        .contains(s)) return 'new';
    if (['in_progress', 'processing', 'inprogress'].contains(s)) return 'in_progress';
    if (['done', 'completed', 'complete'].contains(s)) return 'done';
    if (['canceled', 'cancelled'].contains(s)) return 'canceled';

    return s.isEmpty ? 'unknown' : s;
  }

  String _statusLabel(BuildContext context, String? status) {
    final t = AppLocalizations.of(context)!;
    switch (_normalizeStatus(status)) {
      case 'new':
        return t.orderStatusNew;
      case 'in_progress':
        return t.orderStatusInProgress;
      case 'done':
        return t.orderStatusDone;
      case 'canceled':
        return t.orderStatusCanceled;
      default:
        return t.orderStatusUnknown;
    }
  }

  Color _statusColor(String? status) {
    switch (_normalizeStatus(status)) {
      case 'new':
        return Colors.blueAccent;
      case 'in_progress':
        return const Color(0xFFE0C097); // Gold
      case 'done':
        return Colors.greenAccent;
      case 'canceled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(BuildContext context, Timestamp? ts) {
    final t = AppLocalizations.of(context)!;
    if (ts == null) return t.notAvailable;
    final date = ts.toDate();
    // ✅ تنسيق التاريخ ليكون أكثر دقة
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _typeLabel(BuildContext context, String? type) {
    final t = AppLocalizations.of(context)!;
    switch ((type ?? '').toString().trim().toLowerCase()) {
      case 'product':
        return t.orderTypeProduct;
      case 'service':
        return t.orderTypeService;
      default:
        return t.orderTypeGeneric;
    }
  }

  String _displayOrderNumber(String docId, Map<String, dynamic> data) {
    final raw = data['orderNumber'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is num && raw.toInt() > 0) return '#${raw.toInt()}';
    return docId.substring(0, 8).toUpperCase();
  }

  void _showOrderDetails(BuildContext context, {required String orderId}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    const goldColor = Color(0xFFE0C097);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        title: Text(
          t.ordersTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // شريط الفلترة الأفقي
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // reverse: true, // إزالة العكس ليكون الترتيب منطقياً
              children: [
                _StatusChip(
                  label: t.filterAll,
                  value: 'all',
                  groupValue: _selectedStatus,
                  onSelected: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: t.orderStatusNew,
                  value: 'new',
                  groupValue: _selectedStatus,
                  onSelected: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: t.orderStatusInProgress,
                  value: 'in_progress',
                  groupValue: _selectedStatus,
                  onSelected: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: t.orderStatusDone,
                  value: 'done',
                  groupValue: _selectedStatus,
                  onSelected: (v) => setState(() => _selectedStatus = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ordersStream(),
              builder: (context, snapshot) {
                if (_currentUser == null) {
                  return Center(
                    child: Text(
                      t.ordersLoginRequired,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: goldColor));
                }

                if (snapshot.hasError) {
                  // التعامل مع خطأ الفهرس تلقائياً
                  if (_preferIndexedQuery && snapshot.error.toString().contains('index')) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _preferIndexedQuery = false);
                    });
                  }
                  return Center(
                    child: Text(t.ordersLoadError, style: const TextStyle(color: Colors.redAccent)),
                  );
                }

                var docs = snapshot.data?.docs ?? [];
                if (_selectedStatus != 'all') {
                  docs = docs
                      .where((d) =>
                          _normalizeStatus(d.data()['status']?.toString()) == _selectedStatus)
                      .toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.white12),
                        const SizedBox(height: 16),
                        Text(t.ordersEmpty, style: const TextStyle(color: Colors.white30)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final status = data['status']?.toString();
                    final displayNo = _displayOrderNumber(docs[index].id, data);

                    return FadeInUp(
                      delay: Duration(milliseconds: index * 50),
                      child: GestureDetector(
                        onTap: () => _showOrderDetails(context, orderId: docs[index].id),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: goldColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: goldColor),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayNo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _typeLabel(context, data['type']?.toString()),
                                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: _statusColor(status).withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _statusLabel(context, status),
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(context, data['createdAt'] as Timestamp?),
                                    style: const TextStyle(color: Colors.white24, fontSize: 12),
                                  ),
                                  if (data['total'] != null)
                                    // ✅ عرض السعر بالعملة المعتمدة
                                    PriceText(
                                      priceInEur: (data['total'] as num).toDouble(),
                                      style: const TextStyle(
                                        color: goldColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label, value, groupValue;
  final ValueChanged<String> onSelected;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = value == groupValue;
    const goldColor = Color(0xFFE0C097);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: goldColor,
      backgroundColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: selected ? goldColor : Colors.white10),
      ),
      showCheckmark: false,
    );
  }
}