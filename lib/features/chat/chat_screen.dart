import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String title;
  final String? orderNumber;
  final String? orderDocId;
  final String? orderTitle;
  final String? initialMessage;

  const ChatScreen._({
    required this.title,
    this.orderNumber,
    this.orderDocId,
    this.orderTitle,
    this.initialMessage,
    super.key,
  });

  factory ChatScreen.support({Key? key}) {
    return ChatScreen._(key: key, title: "الدعم الفني");
  }

  factory ChatScreen.order({
    Key? key,
    required String orderNumber,
    String? orderDocId,
    String? orderTitle,
  }) {
    return ChatScreen._(
      key: key,
      title: orderTitle ?? "طلب #$orderNumber",
      orderNumber: orderNumber,
      orderDocId: orderDocId,
      orderTitle: orderTitle,
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _svc = ChatService();
  final ScrollController _scrollController = ScrollController();

  static const goldColor = Color(0xFFE0C097);
  static const deepDarkColor = Color(0xFF0A0E14);
  static const cardColor = Color(0xFF161B22);

  // ✅ استخدام Stream محفوظ لضمان عدم إعادة التحميل عند كل setState
  late Stream<QuerySnapshot> _chatStream;

  @override
  void initState() {
    super.initState();
    _chatStream = _getChatStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepDarkColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [goldColor.withOpacity(0.05), Colors.transparent],
                  center: Alignment.center,
                  radius: 1.2,
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatStream, // ✅ نستخدم الـ Stream المحفوظ في initState
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("حدث خطأ في الاتصال", style: TextStyle(color: Colors.white24)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: goldColor, strokeWidth: 1.5));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final bool isMe = data['isAdmin'] != true;

                      bool showDate = false;
                      if (index == docs.length - 1) {
                        showDate = true;
                      } else {
                        final curr = (data['createdAt'] as Timestamp?)?.toDate();
                        final prev = (docs[index + 1].data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                        if (curr != null && prev != null) {
                          showDate = !_isSameDay(curr, prev.toDate());
                        }
                      }

                      return Column(
                        children: [
                          if (showDate) _buildDateHeader(data['createdAt'] as Timestamp?),
                          _buildMessageBubble(data, isMe),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          // ✅ تم فصل منطقة الإدخال لضمان عدم تأثر الـ StreamBuilder عند تحديث الحالة
          ChatInputArea(
            onSend: (txt) => _svc.sendMessage(
              text: txt,
              orderNumber: widget.orderNumber,
              orderDocId: widget.orderDocId,
            ),
            onAttach: (file) => _svc.uploadChatFile(
              file: file,
              orderNumber: widget.orderNumber,
              orderDocId: widget.orderDocId,
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getChatStream() {
    final uid = _svc.currentUserId;
    if (uid == null) return const Stream.empty();

    var baseQuery = FirebaseFirestore.instance
        .collection('chats')
        .where('senderId', isEqualTo: uid);

    if (widget.orderNumber != null) {
      return baseQuery
          .where('orderNumber', isEqualTo: widget.orderNumber)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return baseQuery
          .where('category', isEqualTo: 'support')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: goldColor.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Icon(Icons.support_agent_rounded, size: 50, color: goldColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 20),
            Text(
              "كيف يمكننا خدمتك اليوم؟",
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _QuickReplyChip(label: "📦 أين طلبي؟", onTap: () => {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(Timestamp? ts) {
    if (ts == null) return const SizedBox.shrink();
    final date = ts.toDate();
    final now = DateTime.now();
    String label = _isSameDay(date, now) 
        ? "اليوم" 
        : _isSameDay(date, now.subtract(const Duration(days: 1))) 
            ? "أمس" 
            : intl.DateFormat('d MMM yyyy', 'en').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: isMe ? goldColor : cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['type'] == 'image' && data['fileUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(data['fileUrl'], loadingBuilder: (_, child, p) => p == null ? child : const Center(child: CircularProgressIndicator())),
                ),
              if ((data['text'] ?? '').toString().isNotEmpty)
                Text(data['text'], style: GoogleFonts.cairo(color: isMe ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// ✅ مكون منفصل لمنطقة الإدخال لمنع إعادة تحميل الصفحة بالكامل
class ChatInputArea extends StatefulWidget {
  final Function(String) onSend;
  final Function(File) onAttach;

  const ChatInputArea({super.key, required this.onSend, required this.onAttach});

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 12, 10, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE0C097), size: 30),
              onPressed: _sending ? null : _handleAttach,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "اكتب رسالتك...",
                      hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _handleSend,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFE0C097), shape: BoxShape.circle),
                child: _sending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.black, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;
    setState(() => _sending = true);
    await widget.onSend(txt);
    _controller.clear();
    setState(() => _sending = false);
  }

  void _handleAttach() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _sending = true);
      await widget.onAttach(File(result.files.single.path!));
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
      backgroundColor: Colors.white.withOpacity(0.05),
      onPressed: onTap,
    );
  }
}